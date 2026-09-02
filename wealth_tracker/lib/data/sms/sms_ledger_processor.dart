import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/security/app_lock_exemption.dart';
import '../../features/ledger/screens/sms_review_screen.dart';
import '../db/database.dart';
import 'bank_charge_payload.dart';
import 'bank_sms_parser.dart';
import 'card_balance_updater.dart';

const _dedupeKey = 'sms_processed_ids';
const _dedupeCap = 200;

/// The WorkManager task name a bank-SMS notification's "Quick add" action
/// enqueues (see SmsQuickAddActionReceiver.kt) -- must match the string
/// switched on in `priceRefreshCallbackDispatcher`
/// (lib/data/pricing/background_refresh.dart).
const smsQuickAddTaskName = 'smsQuickAdd';

/// The WorkManager task name SmsReceiver.kt enqueues automatically, with no
/// notification ever posted, when it recognizes an incoming SMS as a card
/// payment/settlement or refund alert -- must match the string switched on
/// in `priceRefreshCallbackDispatcher` (lib/data/pricing/background_refresh.dart).
const smsAutoUpdateTaskName = 'smsAutoUpdate';

/// One incoming SMS, already known to be from the app's own SMS-detected
/// launch path (see `native_sms_channel.dart` / `app.dart`) — so the app is
/// guaranteed to be in the foreground by the time this runs, which is why
/// this can push straight to the review screen instead of going through a
/// system notification and a background isolate the way the very first
/// version of this feature did.
///
/// Does two independent things with a parsed charge: silently keeps a
/// matching credit card's tracked balance current (see
/// [updateCardBalanceFromSms] — nothing to confirm, it's just a number),
/// and separately opens [SmsReviewScreen] so the user can decide whether
/// this specific charge should also become a ledger entry (pre-filled from
/// a vendor rule when one matches, otherwise left for the user to pick).
/// Those two outcomes aren't mutually exclusive — a charge on your own
/// card can *also* be a payment made on someone else's behalf.
Future<void> processIncomingSms(
  AppDatabase db, {
  required String body,
  required int timestampMillis,
  required String profileId,
}) async {
  if (body.trim().isEmpty) return;

  // Claims the same [QuickActionExemption] [SmsReviewScreen] itself would
  // claim once it actually mounts -- claimed here instead, immediately,
  // before any of the real drift/SQLite I/O below runs (the dedupe check,
  // the parse, the card-balance update, the vendor-rule lookup), because
  // that chain can on a real device -- especially at cold start, while
  // other providers are also hitting the database -- easily outlast
  // [AppLockGate]'s bounded wait for an exemption to appear. Without this,
  // the OS biometric sheet could fire before the exemption was ever
  // claimed (the reported "asked for biometrics when adding a payment from
  // an SMS notification" bug). Only claimed when the app is actually
  // locked right now -- exactly [SmsReviewScreen]'s own condition -- since
  // an already-unlocked app has nothing to exempt anything from. Every
  // early return below releases the claim explicitly; the one path that
  // pushes [SmsReviewScreen] releases it a frame later (via
  // `addPostFrameCallback`, scheduled right after the `push`), which is
  // guaranteed to run after that screen's own `initState` -- and thus its
  // own claim -- has already landed, so the exemption never drops to zero
  // in between even for a single frame.
  final claimedExemption = !appUnlocked.value;
  if (claimedExemption) QuickActionExemption.claim();

  final dedupeId = '$timestampMillis:${body.hashCode}';
  if (await _alreadyProcessed(db, dedupeId)) {
    if (claimedExemption) QuickActionExemption.release();
    return;
  }
  await _markProcessed(db, dedupeId);

  final parsed = parseBankSms(body);
  if (parsed == null) {
    if (claimedExemption) QuickActionExemption.release();
    return;
  }

  await updateCardBalanceFromSms(db, parsed);
  // A payment/settlement SMS (paying down the card, isCharge == false)
  // only ever updates that tracked balance -- it's not a purchase and
  // isn't a candidate for "who was this for", so it never opens the
  // review screen the way an actual charge does.
  if (!parsed.isCharge) {
    if (claimedExemption) QuickActionExemption.release();
    return;
  }

  final rules = await (db.select(
    db.vendorRules,
  )..where((r) => r.profileId.equals(profileId))).get();
  VendorRule? rule;
  for (final r in rules) {
    if (parsed.vendor.toLowerCase().contains(r.vendorPattern.toLowerCase())) {
      rule = r;
      break;
    }
  }

  final payload = BankChargePayload(
    vendor: parsed.vendor,
    amount: parsed.amount,
    currency: parsed.currency,
    occurredAt: parsed.occurredAt,
    dedupeId: dedupeId,
    counterpartyId: rule?.counterpartyId,
    category: rule?.category,
  );

  final navigator = await _awaitNavigator();
  if (navigator == null) {
    if (claimedExemption) QuickActionExemption.release();
    return;
  }
  navigator.push(
    MaterialPageRoute(builder: (_) => SmsReviewScreen(payload: payload)),
  );
  // [SmsReviewScreen]'s own initState claims its lifecycle-tied exemption
  // synchronously during this same frame's build phase, strictly before
  // any postFrameCallback fires -- so releasing here, once the frame is
  // done, can never let the exemption count touch zero while the app is
  // still locked and that screen is on screen.
  if (claimedExemption) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      QuickActionExemption.release();
    });
  }
}

/// Headless counterpart to [processIncomingSms] for the notification's
/// "Quick add" action -- runs with no UI and no user confirmation, so it
/// only ever commits when a [VendorRule] already resolves the SMS sender to
/// a specific ledger + category on its own; anything else is silently left
/// for the notification's normal tap (still [processIncomingSms], still
/// available afterward since nothing here marks the SMS processed unless a
/// rule actually matched). Shares [processIncomingSms]'s dedupe key space
/// so a charge added this way is not reviewable-and-addable again from a
/// later tap on the same notification, and vice versa.
///
/// Returns whether a ledger entry was actually added, purely so a caller
/// (or a test) can tell "matched and added" apart from "nothing to do
/// here" -- the background isolate that calls this in production has no
/// UI to report it to either way.
Future<bool> commitSmsQuickAdd(
  AppDatabase db, {
  required String body,
  required int timestampMillis,
  required String profileId,
}) async {
  if (body.trim().isEmpty) return false;

  final dedupeId = '$timestampMillis:${body.hashCode}';
  if (await _alreadyProcessed(db, dedupeId)) return false;

  final parsed = parseBankSms(body);
  if (parsed == null) return false;

  await updateCardBalanceFromSms(db, parsed);
  // See the matching comment in processIncomingSms -- a payment/settlement
  // SMS never becomes a ledger entry, so there's nothing further to commit.
  if (!parsed.isCharge) return false;

  final rules = await (db.select(
    db.vendorRules,
  )..where((r) => r.profileId.equals(profileId))).get();
  VendorRule? rule;
  for (final r in rules) {
    if (parsed.vendor.toLowerCase().contains(r.vendorPattern.toLowerCase())) {
      rule = r;
      break;
    }
  }
  if (rule == null) return false;

  await db
      .into(db.ledgerTransactions)
      .insert(
        LedgerTransactionsCompanion.insert(
          id: const Uuid().v4(),
          counterpartyId: rule.counterpartyId,
          date: parsed.occurredAt,
          amount: parsed.amount,
          currency: Value(parsed.currency),
          category: rule.category,
          createdAt: DateTime.now(),
          profileId: Value(profileId),
        ),
      );

  await _markProcessed(db, dedupeId);
  return true;
}

/// Headless counterpart for SMS the *native* receiver already identified as
/// a card payment/settlement or refund alert (see SmsReceiver.kt's
/// `isCardPaymentOrRefundAlert`) -- runs with no notification and no
/// ledger entry at all, per the user's explicit ask to only be interrupted
/// for purchases, not for paying a card down or a refund landing on it.
///
/// The native check is a narrow trigger-phrase match, not a full parse, so
/// this still runs the same tested [parseBankSms] before touching
/// anything -- if it somehow doesn't parse, or turns out to be a charge
/// after all, nothing happens here (no notification can be raised from a
/// background isolate either way; that gap is accepted as the cost of the
/// native check being deliberately conservative about *what* it matches,
/// not *how much* of the message it verifies). Shares the same dedupe key
/// space as [processIncomingSms]/[commitSmsQuickAdd].
Future<void> commitSmsAutoUpdate(
  AppDatabase db, {
  required String body,
  required int timestampMillis,
  required String profileId,
}) async {
  if (body.trim().isEmpty) return;

  final dedupeId = '$timestampMillis:${body.hashCode}';
  if (await _alreadyProcessed(db, dedupeId)) return;

  final parsed = parseBankSms(body);
  if (parsed == null) return;

  await updateCardBalanceFromSms(db, parsed);
  await _markProcessed(db, dedupeId);
}

/// [navigatorKey]'s Navigator is usually already mounted by the time this
/// runs (callers wait for the first frame), but polls briefly rather than
/// giving up immediately, as a safety net against rarer timing races —
/// same pattern used for widget-tap launches (`quick_add_launch.dart`).
Future<NavigatorState?> _awaitNavigator() async {
  for (var attempt = 0; attempt < 10; attempt++) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) return navigator;
    await Future.delayed(const Duration(milliseconds: 100));
  }
  return null;
}

Future<bool> _alreadyProcessed(AppDatabase db, String dedupeId) async {
  final ids = await _loadProcessedIds(db);
  return ids.contains(dedupeId);
}

Future<void> _markProcessed(AppDatabase db, String dedupeId) async {
  final ids = await _loadProcessedIds(db);
  ids.add(dedupeId);
  while (ids.length > _dedupeCap) {
    ids.removeAt(0);
  }
  await db
      .into(db.syncMeta)
      .insertOnConflictUpdate(
        SyncMetaCompanion.insert(key: _dedupeKey, value: jsonEncode(ids)),
      );
}

Future<List<String>> _loadProcessedIds(AppDatabase db) async {
  final row = await (db.select(
    db.syncMeta,
  )..where((m) => m.key.equals(_dedupeKey))).getSingleOrNull();
  if (row == null) return [];
  final decoded = jsonDecode(row.value);
  return decoded is List ? decoded.cast<String>() : [];
}

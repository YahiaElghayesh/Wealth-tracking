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

/// Separate from [_dedupeKey] on purpose -- that key means "this SMS's
/// *ledger* outcome (a review-screen visit, a quick-add, or a confirmed
/// no-op) is fully settled, never act on it again", which a charge SMS
/// only reaches once its notification is actually tapped. The balance
/// update needs to happen the moment the SMS arrives, whether or not that
/// tap ever comes (see [commitSmsBalanceUpdate]) -- tracked here instead
/// so it can run early without prematurely marking the SMS as "settled"
/// and silently skipping the review screen later.
const _balanceAppliedKey = 'sms_balance_applied_ids';
const _balanceAppliedCap = 200;

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

/// The WorkManager task name SmsReceiver.kt enqueues automatically,
/// *alongside* posting its usual notification, for a charge SMS -- must
/// match the string switched on in `priceRefreshCallbackDispatcher`
/// (lib/data/pricing/background_refresh.dart). See [commitSmsBalanceUpdate]
/// for why this exists as a separate task from the notification tap.
const smsBalanceUpdateTaskName = 'smsBalanceUpdate';

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

  // Read before claiming anything below -- once claimed, [appUnlocked]
  // reads "unlocked" for as long as this function's own claim (and then
  // [SmsReviewScreen]'s) is active, so this is the only correct moment to
  // capture whether the app was *genuinely* locked when this SMS arrived.
  // Threaded through to [SmsReviewScreen] explicitly (see its
  // `wasLockedOnArrival` parameter) rather than left for that screen to
  // re-derive from [appUnlocked] itself at mount time, which would by then
  // always read "unlocked" because of the claim below.
  final wasLocked = !appUnlocked.value;

  // Claims the same [QuickActionExemption] [SmsReviewScreen] itself would
  // claim once it actually mounts -- claimed here instead, immediately,
  // before any of the real drift/SQLite I/O below runs (the dedupe check,
  // the parse, the card-balance update, the vendor-rule lookup), because
  // that chain can on a real device -- especially at cold start, while
  // other providers are also hitting the database -- easily outlast
  // [AppLockGate]'s bounded wait for an exemption to appear. Without this,
  // the OS biometric sheet could fire before the exemption was ever
  // claimed (the reported "asked for biometrics when adding a payment from
  // an SMS notification" bug).
  //
  // Claimed unconditionally now, regardless of [wasLocked] -- previously
  // gated on it, which raced [AppLockGate]'s own resume handling:
  // [appUnlocked] only updates on that widget's next rebuild, so a resume's
  // relock evaluation landing concurrently with this same SMS could still
  // read a stale "already unlocked" here and skip the claim entirely,
  // leaving nothing to stop the OS biometric prompt from firing once
  // [AppLockGate]'s bounded wait ran out (the reported "sometimes still
  // asks for biometrics" bug persisting despite the guard above). Claiming
  // even when the app turns out to already be genuinely unlocked is
  // harmless -- see [QuickActionExemption]'s own doc comment. Every early
  // return below releases the claim explicitly; the one path that pushes
  // [SmsReviewScreen] releases it a frame later (via
  // `addPostFrameCallback`, scheduled right after the `push`), which is
  // guaranteed to run after that screen's own `initState` -- and thus its
  // own claim -- has already landed, so the exemption never drops to zero
  // in between even for a single frame.
  QuickActionExemption.claim();

  final dedupeId = '$timestampMillis:${body.hashCode}';
  if (await _alreadyProcessed(db, dedupeId)) {
    QuickActionExemption.release();
    return;
  }
  await _markProcessed(db, dedupeId);

  final parsed = parseBankSms(body);
  if (parsed == null) {
    QuickActionExemption.release();
    return;
  }

  // Idempotent against [commitSmsBalanceUpdate] having already applied
  // this exact SMS's balance update the moment it arrived (the common
  // case, since that always runs before this ever could) -- without this
  // guard, a charge with no stated available-balance figure would get its
  // amount subtracted a second time here, on top of the one that already
  // ran, double-counting the same charge.
  await _updateCardBalanceOnce(db, parsed, dedupeId);
  // A payment/settlement SMS (paying down the card, isCharge == false)
  // only ever updates that tracked balance -- it's not a purchase and
  // isn't a candidate for "who was this for", so it never opens the
  // review screen the way an actual charge does.
  if (!parsed.isCharge) {
    QuickActionExemption.release();
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
    QuickActionExemption.release();
    return;
  }
  navigator.push(
    MaterialPageRoute(
      builder: (_) =>
          SmsReviewScreen(payload: payload, wasLockedOnArrival: wasLocked),
    ),
  );
  // [SmsReviewScreen]'s own initState claims its lifecycle-tied exemption
  // synchronously during this same frame's build phase, strictly before
  // any postFrameCallback fires -- so releasing here, once the frame is
  // done, can never let the exemption count touch zero while the app is
  // still locked and that screen is on screen.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    QuickActionExemption.release();
  });
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

  await _updateCardBalanceOnce(db, parsed, dedupeId);
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
          source: const Value('sms'),
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

  await _updateCardBalanceOnce(db, parsed, dedupeId);
  await _markProcessed(db, dedupeId);
}

/// Headless counterpart for a *charge* SMS SmsReceiver.kt has just posted
/// its usual notification for -- runs alongside that notification, not
/// instead of it, so the tracked card balance updates the moment the SMS
/// arrives whether or not the user ever taps the notification. Previously
/// a charge notification the user swiped away (or simply hadn't gotten to
/// yet) left the balance stale indefinitely, since the only code that ever
/// called [updateCardBalanceFromSms] for a charge ran from inside
/// [processIncomingSms] -- reachable only by opening that notification.
///
/// Deliberately never touches [_dedupeKey] (the "fully settled" state
/// [processIncomingSms]/[commitSmsQuickAdd] check) -- this only ever
/// updates the balance, using its own separate [_balanceAppliedKey]
/// dedupe so the same SMS's balance effect is never applied twice, while
/// leaving the ledger-entry decision exactly as available as it was
/// before: tapping the notification afterward still opens
/// [SmsReviewScreen] normally.
Future<void> commitSmsBalanceUpdate(
  AppDatabase db, {
  required String body,
  required int timestampMillis,
}) async {
  if (body.trim().isEmpty) return;

  final dedupeId = '$timestampMillis:${body.hashCode}';
  final parsed = parseBankSms(body);
  if (parsed == null) return;

  await _updateCardBalanceOnce(db, parsed, dedupeId);
}

/// Applies [parsed] to its matching card's tracked balance at most once
/// per [dedupeId] -- shared by every call site above so a charge SMS
/// whose balance [commitSmsBalanceUpdate] already applied on arrival
/// doesn't get it applied a second time once [processIncomingSms] or
/// [commitSmsQuickAdd] later runs for the same SMS (which would silently
/// double-subtract the charge whenever the SMS states no explicit
/// available-balance figure for [updateCardBalanceFromSms] to just
/// re-assert instead).
Future<void> _updateCardBalanceOnce(
  AppDatabase db,
  ParsedBankSms parsed,
  String dedupeId,
) async {
  final applied = await _loadIds(db, _balanceAppliedKey);
  if (applied.contains(dedupeId)) return;
  await updateCardBalanceFromSms(db, parsed);
  applied.add(dedupeId);
  while (applied.length > _balanceAppliedCap) {
    applied.removeAt(0);
  }
  await db
      .into(db.syncMeta)
      .insertOnConflictUpdate(
        SyncMetaCompanion.insert(
          key: _balanceAppliedKey,
          value: jsonEncode(applied),
        ),
      );
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
  final ids = await _loadIds(db, _dedupeKey);
  return ids.contains(dedupeId);
}

Future<void> _markProcessed(AppDatabase db, String dedupeId) async {
  final ids = await _loadIds(db, _dedupeKey);
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

/// Shared by both dedupe key spaces in this file (see [_dedupeKey] and
/// [_balanceAppliedKey]) -- same storage shape (a JSON array of dedupe-id
/// strings under one [SyncMeta] row), just keyed differently depending on
/// which "has this already happened" question is being asked.
Future<List<String>> _loadIds(AppDatabase db, String key) async {
  final row = await (db.select(
    db.syncMeta,
  )..where((m) => m.key.equals(key))).getSingleOrNull();
  if (row == null) return [];
  final decoded = jsonDecode(row.value);
  return decoded is List ? decoded.cast<String>() : [];
}

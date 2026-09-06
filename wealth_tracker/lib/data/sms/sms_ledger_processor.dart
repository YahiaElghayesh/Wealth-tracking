import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/models/currency.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/security/app_lock_exemption.dart';
import '../../features/ledger/screens/sms_review_screen.dart';
import '../db/database.dart';
import '../notifications/sms_rule_notifications.dart';
import 'bank_charge_payload.dart';
import 'sms_rule_engine.dart';

const _dedupeKey = 'sms_processed_ids';
const _dedupeCap = 200;

/// Separate from [_dedupeKey] on purpose -- that key means "this SMS's
/// *ledger* outcome (a review-screen visit, a quick-add, or a confirmed
/// no-op) is fully settled, never act on it again", which a charge SMS
/// only reaches once its notification is actually tapped. The balance
/// update needs to happen the moment the SMS arrives, whether or not that
/// tap ever comes, so it's tracked here instead: run at most once per SMS,
/// without prematurely marking the SMS as "settled" and silently skipping
/// the review screen later.
const _balanceAppliedKey = 'sms_balance_applied_ids';
const _balanceAppliedCap = 200;

/// The WorkManager task name a bank-SMS notification's "Quick add" action
/// enqueues (see SmsQuickAddActionReceiver.kt) -- must match the string
/// switched on in `priceRefreshCallbackDispatcher`
/// (lib/data/pricing/background_refresh.dart).
const smsQuickAddTaskName = 'smsQuickAdd';

/// The WorkManager task name SmsReceiver.kt enqueues automatically, with no
/// notification ever posted, when its own narrow keyword pre-filter
/// recognizes an incoming SMS as a card payment/settlement or refund alert
/// -- must match the string switched on in `priceRefreshCallbackDispatcher`
/// (lib/data/pricing/background_refresh.dart).
const smsAutoUpdateTaskName = 'smsAutoUpdate';

/// The WorkManager task name SmsReceiver.kt enqueues automatically,
/// *alongside* posting its usual notification, for anything else -- must
/// match the string switched on in `priceRefreshCallbackDispatcher`
/// (lib/data/pricing/background_refresh.dart). See [commitSmsBalanceUpdate]
/// for why this exists as a separate task from the notification tap.
const smsBalanceUpdateTaskName = 'smsBalanceUpdate';

class _RuleMatch {
  const _RuleMatch(this.rule, this.match);
  final SmsRule rule;
  final SmsRuleMatch match;
}

/// Tries every saved [SmsRule] (across every profile -- an SMS Rule isn't
/// scoped the way a ledger is; only a 'ledgerPayment' rule's *target*
/// counterparty carries a real profile, resolved separately by
/// `applySmsRule` itself) against [body], returning every one that
/// matched -- deliberately not just the first, since a single real SMS
/// can legitimately match more than one rule (e.g. a card-balance rule and
/// a ledger-payment rule both built from the same bank's charge wording).
Future<List<_RuleMatch>> _matchAllRules(AppDatabase db, String body) async {
  final rules = await db.select(db.smsRules).get();
  final matches = <_RuleMatch>[];
  for (final rule in rules) {
    final match = matchSmsRule(rule, body);
    if (match != null) matches.add(_RuleMatch(rule, match));
  }
  return matches;
}

/// Applies every matched credit-card/bank-account balance rule -- the
/// "keep the tracked number current" half of a match, independent of
/// whichever ledger-payment rule(s) may also have matched the same SMS.
/// Returns whether anything was actually applied.
Future<bool> _applyBalanceMatches(
  AppDatabase db,
  List<_RuleMatch> matches,
) async {
  var appliedAny = false;
  for (final m in matches) {
    if (m.rule.operation != 'creditCardBalance' &&
        m.rule.operation != 'bankAccountBalance') {
      continue;
    }
    final outcome = await applySmsRule(db, m.rule, m.match);
    if (!outcome.applied) continue;
    appliedAny = true;
    if (m.rule.notifyOnMatch && outcome.notificationTitle != null) {
      await showSmsRuleNotification(
        title: outcome.notificationTitle!,
        body: outcome.notificationBody ?? '',
      );
    }
  }
  return appliedAny;
}

/// [_applyBalanceMatches], applied at most once per [dedupeId] -- shared by
/// every call site below so a charge SMS whose balance
/// [commitSmsBalanceUpdate] already applied on arrival doesn't get it
/// applied a second time once [processIncomingSms] or [commitSmsQuickAdd]
/// later runs for the same SMS, which would silently double-count an
/// "add"/"subtract" role rule's effect.
Future<void> _applyBalanceMatchesOnce(
  AppDatabase db,
  List<_RuleMatch> matches,
  String dedupeId,
) async {
  final applied = await _loadIds(db, _balanceAppliedKey);
  if (applied.contains(dedupeId)) return;
  await _applyBalanceMatches(db, matches);
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

/// One incoming SMS, already known to be from the app's own SMS-detected
/// launch path (see `native_sms_channel.dart` / `app.dart`) — so the app is
/// guaranteed to be in the foreground by the time this runs, which is why
/// this can push straight to the review screen instead of going through a
/// system notification and a background isolate the way the very first
/// version of this feature did.
///
/// Applies every matched credit-card/bank-account balance rule silently
/// (nothing to confirm, it's just a number), and separately opens
/// [SmsReviewScreen] for the first matched 'ledgerPayment' rule tagged as
/// a charge, so the user can decide whether it should become a ledger
/// entry — pre-filled with that rule's ledger/category, editable before
/// saving. A 'ledgerPayment' match tagged as a repayment has nothing to
/// review (the ledger, sign, and amount are already fully determined) so
/// it's applied directly instead, the same way the headless paths do.
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
  // before any of the real drift/SQLite I/O below runs, because that chain
  // can on a real device easily outlast [AppLockGate]'s bounded wait for
  // an exemption to appear. Every early return below releases the claim
  // explicitly; the one path that pushes [SmsReviewScreen] releases it a
  // frame later (via `addPostFrameCallback`), guaranteed to run after that
  // screen's own claim has already landed.
  QuickActionExemption.claim();

  final dedupeId = '$timestampMillis:${body.hashCode}';
  if (await _alreadyProcessed(db, dedupeId)) {
    QuickActionExemption.release();
    return;
  }
  await _markProcessed(db, dedupeId);

  final matches = await _matchAllRules(db, body);
  await _applyBalanceMatchesOnce(db, matches, dedupeId);

  _RuleMatch? reviewable;
  for (final m in matches) {
    if (m.rule.operation != 'ledgerPayment') continue;
    if (m.match.valueRole == 'repayment') {
      final outcome = await applySmsRule(db, m.rule, m.match);
      if (outcome.applied &&
          m.rule.notifyOnMatch &&
          outcome.notificationTitle != null) {
        await showSmsRuleNotification(
          title: outcome.notificationTitle!,
          body: outcome.notificationBody ?? '',
        );
      }
      continue;
    }
    reviewable ??= m;
  }

  if (reviewable == null) {
    QuickActionExemption.release();
    return;
  }

  final rule = reviewable.rule;
  final match = reviewable.match;
  final vendor = (match.vendor?.trim().isNotEmpty ?? false)
      ? match.vendor!
      : (match.sender ?? 'Unknown');
  final payload = BankChargePayload(
    vendor: vendor,
    amount: match.value ?? 0,
    currency: rule.currency ?? defaultCurrency,
    occurredAt: DateTime.now(),
    dedupeId: dedupeId,
    counterpartyId: rule.targetCounterpartyId,
    category: (match.vendor?.trim().isNotEmpty ?? false) ? match.vendor : null,
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
/// only ever commits a ledger entry when a matched 'ledgerPayment' rule
/// already resolves the SMS to a specific ledger + category on its own;
/// anything else (no match, or a balance-only rule) is silently left for
/// the notification's normal tap (still [processIncomingSms], still
/// available afterward since nothing here marks the SMS processed unless
/// a ledger entry actually got added). Shares [processIncomingSms]'s
/// dedupe key space so a charge added this way is not reviewable-and-
/// addable again from a later tap on the same notification, and vice
/// versa.
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

  final matches = await _matchAllRules(db, body);
  await _applyBalanceMatchesOnce(db, matches, dedupeId);

  var ledgerApplied = false;
  for (final m in matches) {
    if (m.rule.operation != 'ledgerPayment') continue;
    final outcome = await applySmsRule(db, m.rule, m.match);
    if (!outcome.applied) continue;
    ledgerApplied = true;
    if (m.rule.notifyOnMatch && outcome.notificationTitle != null) {
      await showSmsRuleNotification(
        title: outcome.notificationTitle!,
        body: outcome.notificationBody ?? '',
      );
    }
  }

  if (ledgerApplied) await _markProcessed(db, dedupeId);
  return ledgerApplied;
}

/// Headless counterpart for SMS the *native* receiver already identified as
/// a card payment/settlement or refund alert (see SmsReceiver.kt's
/// `isCardPaymentOrRefundAlert`) -- runs with no notification and no
/// ledger entry at all, per the user's explicit ask to only be interrupted
/// for purchases, not for paying a card down or a refund landing on it.
/// Shares the same dedupe key space as [processIncomingSms]/
/// [commitSmsQuickAdd].
Future<void> commitSmsAutoUpdate(
  AppDatabase db, {
  required String body,
  required int timestampMillis,
  required String profileId,
}) async {
  if (body.trim().isEmpty) return;

  final dedupeId = '$timestampMillis:${body.hashCode}';
  if (await _alreadyProcessed(db, dedupeId)) return;

  final matches = await _matchAllRules(db, body);
  await _applyBalanceMatchesOnce(db, matches, dedupeId);
  await _markProcessed(db, dedupeId);
}

/// Headless counterpart for a *charge* SMS SmsReceiver.kt has just posted
/// its usual notification for -- runs alongside that notification, not
/// instead of it, so any matched balance rule's tracked number updates the
/// moment the SMS arrives whether or not the user ever taps the
/// notification. Deliberately never touches [_dedupeKey] (the "fully
/// settled" state [processIncomingSms]/[commitSmsQuickAdd] check) -- this
/// only ever updates a balance, using [_balanceAppliedKey] so the same
/// SMS's balance effect is never applied twice, while leaving the ledger-
/// entry decision exactly as available as it was before: tapping the
/// notification afterward still opens [SmsReviewScreen] normally.
Future<void> commitSmsBalanceUpdate(
  AppDatabase db, {
  required String body,
  required int timestampMillis,
}) async {
  if (body.trim().isEmpty) return;

  final dedupeId = '$timestampMillis:${body.hashCode}';
  final matches = await _matchAllRules(db, body);
  await _applyBalanceMatchesOnce(db, matches, dedupeId);
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

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/format/money_formatter.dart';
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

/// The WorkManager task name a bank-SMS charge-review notification's
/// "Quick add" action enqueues (see `notificationTapBackground` in
/// app.dart, registered with flutter_local_notifications) -- must match
/// the string switched on in `priceRefreshCallbackDispatcher`
/// (lib/data/pricing/background_refresh.dart).
const smsQuickAddTaskName = 'smsQuickAdd';

/// The WorkManager task name SmsReceiver.kt enqueues unconditionally for
/// *every* incoming SMS -- there is no native pre-filter of any kind
/// anymore (see [commitSmsAutoDetect]'s own doc comment for why); must
/// match the string switched on in `priceRefreshCallbackDispatcher`
/// (lib/data/pricing/background_refresh.dart).
const smsAutoDetectTaskName = 'smsAutoDetect';

class _RuleMatch {
  const _RuleMatch(this.rule, this.match);
  final SmsRule rule;
  final SmsRuleMatch match;
}

/// Tries every saved, *enabled* [SmsRule] (across every profile -- an SMS
/// Rule isn't scoped the way a ledger is; only a 'ledgerPayment' rule's
/// *target* counterparty carries a real profile, resolved separately by
/// `applySmsRule` itself) against [body], returning every one that
/// matched -- deliberately not just the first, since a single real SMS
/// can legitimately match more than one rule (e.g. a card-balance rule and
/// a ledger-payment rule both built from the same bank's charge wording).
/// A disabled rule is skipped entirely, the same as if it didn't exist.
Future<List<_RuleMatch>> _matchAllRules(AppDatabase db, String body) async {
  final rules = await (db.select(
    db.smsRules,
  )..where((r) => r.enabled.equals(true))).get();
  final matches = <_RuleMatch>[];
  for (final rule in rules) {
    final match = matchSmsRule(rule, body);
    if (match != null) matches.add(_RuleMatch(rule, match));
  }
  return matches;
}

/// One rule that matched, alongside what it extracted -- [_RuleMatch]'s
/// own public counterpart, for a caller outside this file (the SMS Rules
/// "Test an SMS" screen) that needs to show *which* rules matched and
/// *what* they captured, without reaching into this file's own dedupe/
/// apply bookkeeping.
class MatchedSmsRule {
  const MatchedSmsRule(this.rule, this.match);
  final SmsRule rule;
  final SmsRuleMatch match;
}

/// Public wrapper around [_matchAllRules] -- read-only, no dedupe/apply
/// side effects of its own (unlike [commitSmsAutoDetect], which a caller
/// wanting the real thing should call separately). Exists purely so the
/// "Test an SMS" screen can show which rule(s) actually matched a pasted
/// message and what each one extracted, since [commitSmsAutoDetect] itself
/// only ever returns `void`.
Future<List<MatchedSmsRule>> previewSmsRuleMatches(
  AppDatabase db,
  String body,
) async {
  final matches = await _matchAllRules(db, body);
  return [for (final m in matches) MatchedSmsRule(m.rule, m.match)];
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
/// [commitSmsAutoDetect] already applied on arrival doesn't get it applied
/// a second time once [processIncomingSms] or [commitSmsQuickAdd] later
/// runs for the same SMS, which would silently double-count an
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

/// One incoming SMS, run once the app is actually in the foreground --
/// either a live SMS arriving while it's already open (`native_sms_channel
/// .dart`), a cold/warm launch from tapping [showSmsChargeReviewNotification]
/// (see app.dart's notification-response handling), or a widget/shortcut
/// launch carrying pending SMS extras. Guaranteed to have a mounted
/// Navigator by the time this runs, which is why this can push straight to
/// the review screen instead of going through a background isolate the
/// way [commitSmsAutoDetect] (this same SMS's *first* pass, the instant it
/// arrived) has to.
///
/// Applies every matched credit-card/bank-account balance rule silently
/// (nothing to confirm, it's just a number), and separately opens
/// [SmsReviewScreen] for the first matched 'ledgerPayment' rule tagged as
/// a charge, so the user can decide whether it should become a ledger
/// entry — pre-filled with that rule's ledger/category, editable before
/// saving. A 'ledgerPayment' match tagged as a repayment has nothing to
/// review (the ledger, sign, and amount are already fully determined) so
/// it's applied directly instead, the same way the headless paths do --
/// and so does a charge match whose own rule has [SmsRule.autoAddCharges]
/// on, skipping the review step entirely for a vendor the user has
/// decided never needs a second look.
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
    final isRepayment = m.match.valueRole == 'repayment';
    final resolvedTarget = isRepayment
        ? m.rule.targetCounterpartyId
        : resolveLedgerTarget(m.rule, m.match.vendor);
    if (isRepayment || (m.rule.autoAddCharges && resolvedTarget != null)) {
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
    currency: match.currency ?? rule.currency ?? defaultCurrency,
    occurredAt: DateTime.now(),
    dedupeId: dedupeId,
    // Null when the matched vendor has no configured mapping and the
    // rule has no fallback ledger either -- SmsReviewScreen already
    // handles a null counterpartyId by asking the user to pick one from
    // scratch, exactly the "ask which ledger" this is meant to trigger.
    counterpartyId: resolveLedgerTarget(rule, match.vendor),
    category:
        rule.category ??
        ((match.vendor?.trim().isNotEmpty ?? false) ? match.vendor : null),
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
/// already resolves the SMS to a specific ledger + category on its own.
/// A matched *charge* that can't resolve one (no vendor mapping, no
/// fallback ledger on the rule either -- exactly [resolveLedgerTarget]'s
/// own "ask which ledger" case) used to be silently left for "the
/// notification's normal tap" -- except flutter_local_notifications'
/// own default cancels whichever notification an action was tapped on
/// the instant it's tapped, Quick Add included (see
/// AndroidNotificationAction.cancelNotification's default in the
/// vendored plugin), so that notification is already gone by the time
/// this runs. There is no "normal tap" left to fall back to. Posting a
/// fresh review notification -- same call [commitSmsAutoDetect] already
/// makes for the equivalent case, since a headless isolate has no
/// Navigator to push [SmsReviewScreen] onto directly either -- is what
/// actually gives the user something left to act on. Shares
/// [processIncomingSms]'s dedupe key space so a charge added this way is
/// not reviewable-and-addable again from a later tap on the same
/// notification, and vice versa.
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
  // First charge match that couldn't be applied -- a repayment never
  // needs this (it always nets against one fixed ledger, never a
  // per-vendor one -- see resolveLedgerTarget's own doc comment), and
  // only the first one matters, matching the single `reviewable` tracked
  // elsewhere in this file for the same underlying reason.
  _RuleMatch? needsLedgerSelection;
  for (final m in matches) {
    if (m.rule.operation != 'ledgerPayment') continue;
    final outcome = await applySmsRule(db, m.rule, m.match);
    if (!outcome.applied) {
      if (m.match.valueRole != 'repayment') needsLedgerSelection ??= m;
      continue;
    }
    ledgerApplied = true;
    if (m.rule.notifyOnMatch && outcome.notificationTitle != null) {
      await showSmsRuleNotification(
        title: outcome.notificationTitle!,
        body: outcome.notificationBody ?? '',
      );
    }
  }

  if (ledgerApplied) {
    await _markProcessed(db, dedupeId);
  } else if (needsLedgerSelection != null) {
    final vendor =
        (needsLedgerSelection.match.vendor?.trim().isNotEmpty ?? false)
        ? needsLedgerSelection.match.vendor!
        : (needsLedgerSelection.match.sender ?? 'a bank text');
    final value = needsLedgerSelection.match.value;
    final currency =
        needsLedgerSelection.match.currency ??
        needsLedgerSelection.rule.currency ??
        defaultCurrency;
    await showSmsChargeReviewNotification(
      body: body,
      timestampMillis: timestampMillis,
      vendor: vendor,
      amountText: value == null ? null : formatMoney(value, currency),
      // Quick Add itself just failed to resolve a ledger for this exact
      // SMS -- offering the same "Quick add" action on the notification
      // this posts would only ever repeat that same failure, looping the
      // notification away and back with nothing to show for it (see
      // showSmsChargeReviewNotification's own doc comment on this param).
      includeQuickAddAction: false,
    );
  }
  return ledgerApplied;
}

/// Headless entry point SmsReceiver.kt enqueues for *every* incoming SMS,
/// unconditionally -- there is no native keyword pre-filter deciding
/// what "looks like" a bank text anymore (the old `looksLikeBankCardSms`/
/// `isOtpMessage`/`isCardPaymentOrRefundAlert`/vendor-pattern checks are
/// gone entirely); whether anything happens at all now rests solely on
/// whether a saved [SmsRule] actually matches. If nothing matches, this
/// does nothing -- no notification, no fallback prompt.
///
/// Applies every matched balance rule immediately (as [processIncomingSms]
/// does), and a matched 'ledgerPayment' rule tagged 'repayment' directly
/// too, both notifying only when that rule's own [SmsRule.notifyOnMatch]
/// is on -- a 'charge' match applies directly the same way when its own
/// rule has [SmsRule.autoAddCharges] on. Otherwise a 'charge' match needs
/// the user's review before it becomes a ledger entry -- there's no
/// Navigator in this headless isolate to push [SmsReviewScreen] onto, so
/// it posts a notification instead (always, regardless of
/// [SmsRule.notifyOnMatch], since a charge match is inherently something
/// to act on, not just an FYI). Tapping
/// that notification re-runs [processIncomingSms] with the same body/
/// timestamp once the app is open (see app.dart's notification-response
/// handling), which re-matches and pushes the review screen for real;
/// its "Quick add" action commits headlessly via [commitSmsQuickAdd]
/// instead. Deliberately does *not* mark [_dedupeKey] in that case, so
/// either of those later paths still finds `_alreadyProcessed` false.
Future<void> commitSmsAutoDetect(
  AppDatabase db, {
  required String body,
  required int timestampMillis,
}) async {
  if (body.trim().isEmpty) return;

  final dedupeId = '$timestampMillis:${body.hashCode}';
  if (await _alreadyProcessed(db, dedupeId)) return;

  final matches = await _matchAllRules(db, body);
  if (matches.isEmpty) return;

  await _applyBalanceMatchesOnce(db, matches, dedupeId);

  _RuleMatch? reviewable;
  for (final m in matches) {
    if (m.rule.operation != 'ledgerPayment') continue;
    final isRepayment = m.match.valueRole == 'repayment';
    final resolvedTarget = isRepayment
        ? m.rule.targetCounterpartyId
        : resolveLedgerTarget(m.rule, m.match.vendor);
    if (isRepayment || (m.rule.autoAddCharges && resolvedTarget != null)) {
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
    // Fully settled already (balance-only and/or repayment matches, or no
    // ledgerPayment match at all) -- nothing left for a later tap to do.
    await _markProcessed(db, dedupeId);
    return;
  }

  final vendor = (reviewable.match.vendor?.trim().isNotEmpty ?? false)
      ? reviewable.match.vendor!
      : (reviewable.match.sender ?? 'a bank text');
  final value = reviewable.match.value;
  final currency =
      reviewable.match.currency ?? reviewable.rule.currency ?? defaultCurrency;
  final targetId = resolveLedgerTarget(reviewable.rule, reviewable.match.vendor);
  final targetName = targetId == null
      ? null
      : (await (db.select(
          db.counterparties,
        )..where((c) => c.id.equals(targetId))).getSingleOrNull())?.name;
  await showSmsChargeReviewNotification(
    body: body,
    timestampMillis: timestampMillis,
    vendor: vendor,
    amountText: value == null ? null : formatMoney(value, currency),
    targetName: targetName,
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

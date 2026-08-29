import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../features/ledger/screens/sms_review_screen.dart';
import '../db/database.dart';
import 'bank_charge_payload.dart';
import 'bank_sms_parser.dart';
import 'card_balance_updater.dart';

const _dedupeKey = 'sms_processed_ids';
const _dedupeCap = 200;

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
Future<void> processIncomingSms(AppDatabase db, {required String body, required int timestampMillis}) async {
  if (body.trim().isEmpty) return;

  final dedupeId = '$timestampMillis:${body.hashCode}';
  if (await _alreadyProcessed(db, dedupeId)) return;
  await _markProcessed(db, dedupeId);

  final parsed = parseBankSms(body);
  if (parsed == null) return;

  await updateCardBalanceFromSms(db, parsed);

  final rules = await db.select(db.vendorRules).get();
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
  navigator?.push(MaterialPageRoute(builder: (_) => SmsReviewScreen(payload: payload)));
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
  await db.into(db.syncMeta).insertOnConflictUpdate(
        SyncMetaCompanion.insert(key: _dedupeKey, value: jsonEncode(ids)),
      );
}

Future<List<String>> _loadProcessedIds(AppDatabase db) async {
  final row = await (db.select(db.syncMeta)..where((m) => m.key.equals(_dedupeKey))).getSingleOrNull();
  if (row == null) return [];
  final decoded = jsonDecode(row.value);
  return decoded is List ? decoded.cast<String>() : [];
}

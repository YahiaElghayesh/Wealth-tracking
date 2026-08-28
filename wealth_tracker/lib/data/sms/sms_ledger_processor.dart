import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'bank_charge_notifications.dart';
import 'bank_sms_parser.dart';

const _dedupeKey = 'sms_processed_ids';
const _dedupeCap = 200;
const _uuid = Uuid();

/// One incoming SMS: parsed, matched against the vendor rules, and — if it
/// looks like a bank charge — surfaced as a notification for the user to
/// act on. Never writes a ledger entry itself; that only happens once the
/// user taps "Add" (see [recordBankCharge]), since the whole point of this
/// flow (as opposed to the earlier silent auto-capture) is that nothing
/// gets recorded without the user seeing and confirming it.
///
/// Shared by the foreground listener and the headless background isolate,
/// so the two can't drift apart — each just supplies its own
/// [AppDatabase] and its own initialized notifications plugin.
Future<void> handleIncomingBankSms(
  AppDatabase db,
  FlutterLocalNotificationsPlugin notifications, {
  required String? body,
  required int? timestampMillis,
}) async {
  if (body == null || body.trim().isEmpty) return;

  final dedupeId = '${timestampMillis ?? 0}:${body.hashCode}';
  if (await _alreadyProcessed(db, dedupeId)) return;
  await _markProcessed(db, dedupeId);

  final parsed = parseBankSms(body);
  if (parsed == null) return;

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

  await showBankChargeNotification(notifications, payload);
}

/// Records a ledger entry for a detected charge — called when the user taps
/// the notification's "Add" action (a matched vendor rule's counterparty
/// and category, taken from the payload) or saves from the review screen
/// (a manually picked counterparty and category).
Future<void> recordBankCharge(
  AppDatabase db, {
  required String counterpartyId,
  required String category,
  required double amount,
  required String currency,
  required DateTime occurredAt,
}) {
  return db.into(db.ledgerTransactions).insert(
        LedgerTransactionsCompanion.insert(
          id: _uuid.v4(),
          counterpartyId: counterpartyId,
          date: occurredAt,
          amount: amount,
          currency: Value(currency),
          category: category,
          description: const Value('Added from SMS'),
          createdAt: DateTime.now(),
        ),
      );
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

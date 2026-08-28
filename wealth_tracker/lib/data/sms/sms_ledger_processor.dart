import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'bank_sms_parser.dart';

const _dedupeKey = 'sms_processed_ids';
const _dedupeCap = 200;
const _uuid = Uuid();

/// One incoming SMS, matched against the configured vendor rules and
/// recorded as a ledger entry if it's a recognized charge. Shared by both
/// the foreground listener and the headless background isolate, so the two
/// can't drift apart — each just supplies its own [AppDatabase] connection.
///
/// Returns `true` if a ledger entry was created. Safe to call more than
/// once for the same message (e.g. plugin redelivery) — a dedupe record is
/// checked first and this becomes a no-op.
Future<bool> processIncomingSms(
  AppDatabase db, {
  required String? body,
  required int? timestampMillis,
}) async {
  if (body == null || body.trim().isEmpty) return false;

  final dedupeId = '${timestampMillis ?? 0}:${body.hashCode}';
  if (await _alreadyProcessed(db, dedupeId)) return false;

  final parsed = parseBankSms(body);
  if (parsed == null) {
    await _markProcessed(db, dedupeId);
    return false;
  }

  final rules = await db.select(db.vendorRules).get();
  VendorRule? rule;
  for (final r in rules) {
    if (parsed.vendor.toLowerCase().contains(r.vendorPattern.toLowerCase())) {
      rule = r;
      break;
    }
  }
  if (rule == null) {
    await _markProcessed(db, dedupeId);
    return false;
  }

  await db.into(db.ledgerTransactions).insert(
        LedgerTransactionsCompanion.insert(
          id: _uuid.v4(),
          counterpartyId: rule.counterpartyId,
          date: parsed.occurredAt,
          amount: parsed.amount,
          currency: Value(parsed.currency),
          category: rule.category,
          description: const Value('Auto-captured from SMS'),
          createdAt: DateTime.now(),
        ),
      );

  await _markProcessed(db, dedupeId);
  return true;
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

import '../db/database.dart';

const _snapshotVersion = 1;

/// Everything that gets synced across devices: assets, the debt ledger,
/// counterparties, the calculator's manually-entered inputs, and SMS
/// vendor-matching rules. Deliberately excludes `price_cache` (re-fetched
/// from live APIs anyway) and `sync_meta` (local bookkeeping only).
Future<Map<String, dynamic>> exportSnapshot(AppDatabase db, {required DateTime modifiedAt}) async {
  final assets = await db.select(db.assets).get();
  final counterparties = await db.select(db.counterparties).get();
  final transactions = await db.select(db.ledgerTransactions).get();
  final calculatorInputs = await db.select(db.calculatorInputs).get();
  final vendorRules = await db.select(db.vendorRules).get();

  return {
    'version': _snapshotVersion,
    'modifiedAt': modifiedAt.toUtc().toIso8601String(),
    'assets': assets.map((a) => a.toJson()).toList(),
    'counterparties': counterparties.map((c) => c.toJson()).toList(),
    'ledgerTransactions': transactions.map((t) => t.toJson()).toList(),
    'calculatorInputs': calculatorInputs.map((c) => c.toJson()).toList(),
    'vendorRules': vendorRules.map((v) => v.toJson()).toList(),
  };
}

DateTime? snapshotModifiedAt(Map<String, dynamic> json) {
  final raw = json['modifiedAt'];
  return raw is String ? DateTime.tryParse(raw) : null;
}

/// Replaces all local assets/counterparties/transactions with the contents
/// of [json]. Runs in a single transaction so a failure partway through
/// doesn't leave the local database half-overwritten.
Future<void> importSnapshot(AppDatabase db, Map<String, dynamic> json) async {
  final assets = (json['assets'] as List? ?? [])
      .cast<Map<String, dynamic>>()
      .map(Asset.fromJson)
      .toList();
  final counterparties = (json['counterparties'] as List? ?? [])
      .cast<Map<String, dynamic>>()
      .map(Counterparty.fromJson)
      .toList();
  final transactions = (json['ledgerTransactions'] as List? ?? [])
      .cast<Map<String, dynamic>>()
      .map(LedgerTransaction.fromJson)
      .toList();
  final calculatorInputs = (json['calculatorInputs'] as List? ?? [])
      .cast<Map<String, dynamic>>()
      .map(CalculatorInput.fromJson)
      .toList();
  final vendorRules = (json['vendorRules'] as List? ?? [])
      .cast<Map<String, dynamic>>()
      .map(VendorRule.fromJson)
      .toList();

  await db.transaction(() async {
    await db.delete(db.ledgerTransactions).go();
    await db.delete(db.counterparties).go();
    await db.delete(db.assets).go();
    await db.delete(db.calculatorInputs).go();
    await db.delete(db.vendorRules).go();

    await db.batch((batch) {
      batch.insertAll(db.assets, assets.map((a) => a.toCompanion(true)));
      batch.insertAll(db.counterparties, counterparties.map((c) => c.toCompanion(true)));
      batch.insertAll(db.ledgerTransactions, transactions.map((t) => t.toCompanion(true)));
      batch.insertAll(db.calculatorInputs, calculatorInputs.map((c) => c.toCompanion(true)));
      batch.insertAll(db.vendorRules, vendorRules.map((v) => v.toCompanion(true)));
    });
  });
}

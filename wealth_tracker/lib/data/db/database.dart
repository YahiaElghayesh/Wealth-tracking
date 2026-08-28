import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Assets, PriceCache, Counterparties, LedgerTransactions, SyncMeta],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // Pre-release schema churn (asset valuation model + ledger
        // currency) — no installed base to preserve yet, so the simplest
        // correct migration is to just rebuild the affected tables.
        onUpgrade: (m, from, to) async {
          await m.deleteTable(assets.actualTableName);
          await m.createTable(assets);
          await m.deleteTable(ledgerTransactions.actualTableName);
          await m.createTable(ledgerTransactions);
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'wealth_tracker');
}

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Assets, PriceCache, Counterparties, LedgerTransactions, SyncMeta, CalculatorInputs],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // Pre-release schema churn — no installed base to preserve yet, so
        // the simplest correct migration is to just rebuild the affected
        // tables (version 2: asset valuation model + ledger currency;
        // version 3: adds the calculator_inputs table).
        onUpgrade: (m, from, to) async {
          await m.deleteTable(assets.actualTableName);
          await m.createTable(assets);
          await m.deleteTable(ledgerTransactions.actualTableName);
          await m.createTable(ledgerTransactions);
          if (from < 3) {
            await m.createTable(calculatorInputs);
          }
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'wealth_tracker');
}

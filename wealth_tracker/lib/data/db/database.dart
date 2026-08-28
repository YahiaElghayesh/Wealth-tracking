import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Assets,
    PriceCache,
    Counterparties,
    LedgerTransactions,
    SyncMeta,
    CalculatorInputs,
    VendorRules,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // Pre-release schema churn — no installed base to preserve yet, so
        // the simplest correct migration is to just rebuild the affected
        // tables (version 2: asset valuation model + ledger currency;
        // version 3: adds the calculator_inputs table; version 4: adds the
        // vendor_rules table for SMS auto-capture).
        onUpgrade: (m, from, to) async {
          await m.deleteTable(assets.actualTableName);
          await m.createTable(assets);
          await m.deleteTable(ledgerTransactions.actualTableName);
          await m.createTable(ledgerTransactions);
          if (from < 3) {
            await m.createTable(calculatorInputs);
          }
          if (from < 4) {
            await m.createTable(vendorRules);
          }
        },
        // The "Breakfast" quick-pick category was a voice-transcription
        // typo for Breadfast (the actual grocery-delivery app, confirmed by
        // its real bank SMS merchant name) — fix up any rows saved under
        // the old spelling on every open, not just once at migration time,
        // since it's a cheap no-op once there's nothing left to fix.
        beforeOpen: (details) async {
          await customStatement("UPDATE ledger_transactions SET category = 'Breadfast' WHERE category = 'Breakfast'");
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'wealth_tracker');
}

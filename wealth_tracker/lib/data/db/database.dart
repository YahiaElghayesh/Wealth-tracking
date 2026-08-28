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
    CalculatorSnapshots,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // IMPORTANT: every step here must be scoped to the specific `from`
        // version it applies to. The assets/ledgerTransactions rebuild
        // below was previously unconditional — it ran on *every* upgrade,
        // silently wiping both tables on every single app update, not just
        // the one release (version 2) that actually needed a structural
        // change. That's the "my data disappears when I update" bug.
        // Anyone already on version 2+ (i.e. everyone with the app
        // installed today) now upgrades without touching either table.
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // version 2: asset valuation model + ledger currency column —
            // a real structural change, from before this app had any real
            // installed base, so a destructive rebuild was an accepted
            // one-time tradeoff at the time.
            await m.deleteTable(assets.actualTableName);
            await m.createTable(assets);
            await m.deleteTable(ledgerTransactions.actualTableName);
            await m.createTable(ledgerTransactions);
          }
          if (from < 3) {
            await m.createTable(calculatorInputs);
          }
          if (from < 4) {
            await m.createTable(vendorRules);
          }
          if (from < 5) {
            await m.createTable(calculatorSnapshots);
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

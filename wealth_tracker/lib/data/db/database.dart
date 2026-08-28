import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/ledger_category.dart';
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
    CreditCards,
    LedgerCategories,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  Future<void> _seedDefaultLedgerCategories() async {
    // 'Other' isn't seeded — it's always appended as a synthetic last
    // choice by the add-transaction screen, never a real row.
    final defaults = ledgerExpenseCategories.where((c) => c != 'Other').toList();
    for (var i = 0; i < defaults.length; i++) {
      await into(ledgerCategories).insert(
        LedgerCategoriesCompanion.insert(id: const Uuid().v4(), name: defaults[i], sortOrder: Value(i)),
      );
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultLedgerCategories();
        },
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
          if (from < 6) {
            // Credit cards became fully user-managed (name/bank/limit/
            // currency, added and removed from Settings) instead of a
            // fixed hardcoded set of three. Anyone upgrading from before
            // this point already had those three cards, possibly with a
            // limit they'd customized in the old Settings screen (stored
            // as a calculator_inputs key/value row) — seed real
            // CreditCards rows from that so the switch doesn't silently
            // drop a limit someone already set. A brand-new install never
            // takes this branch, so it starts with an empty card list, as
            // it should.
            await m.createTable(creditCards);
            await m.addColumn(calculatorSnapshots, calculatorSnapshots.cardEntriesJson);

            const legacyCards = [
              (key: 'card_nbe_limit', name: 'NBE Wallet', bank: 'NBE', defaultLimit: 500000.0),
              (key: 'card_cib_explorer_wallet_limit', name: 'CIB Explore World', bank: 'CIB', defaultLimit: 109900.0),
              (key: 'card_cib_platinum_limit', name: 'CIB Platinum', bank: 'CIB', defaultLimit: 145500.0),
            ];
            for (var i = 0; i < legacyCards.length; i++) {
              final legacy = legacyCards[i];
              final row =
                  await (select(calculatorInputs)..where((t) => t.key.equals(legacy.key))).getSingleOrNull();
              await into(creditCards).insert(
                CreditCardsCompanion.insert(
                  id: const Uuid().v4(),
                  name: legacy.name,
                  bank: legacy.bank,
                  limitAmount: row?.value ?? legacy.defaultLimit,
                  currency: const Value('EGP'),
                  sortOrder: Value(i),
                ),
              );
            }
          }
          if (from < 7) {
            // Ledger categories became user-managed (add/rename/remove
            // from Settings) instead of a fixed hardcoded list. Seed the
            // same defaults anyone upgrading already had as quick-pick
            // chips, so the switch doesn't make categories disappear.
            await m.createTable(ledgerCategories);
            await _seedDefaultLedgerCategories();
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

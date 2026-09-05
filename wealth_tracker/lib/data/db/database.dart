import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/ledger_category.dart';
import '../../core/models/ledger_category_icons.dart';
import 'tables.dart';

part 'database.g.dart';

/// The profile every fresh install (and every pre-existing installed base
/// upgrading past v14) starts on -- a fixed, literal id rather than a
/// generated UUID specifically so the v14 migration can create the row and
/// backfill every existing table to it in one deterministic pass.
const defaultProfileId = 'default-profile';

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
    ManualInputs,
    Profiles,
    RecurringPayments,
    RecurringPaymentHistory,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 25;

  /// Public so `ProfileRepository.addProfile` can give a newly created
  /// profile the same starter categories a fresh install gets -- otherwise
  /// its add-transaction screen would start with zero quick-pick chips.
  Future<void> seedDefaultLedgerCategories(String profileId) =>
      _seedDefaultLedgerCategories(profileId: profileId);

  Future<void> _seedDefaultLedgerCategories({String? profileId}) async {
    // 'Other' isn't seeded — it's always appended as a synthetic last
    // choice by the add-transaction screen, never a real row.
    final defaults = ledgerExpenseCategories
        .where((c) => c != 'Other')
        .toList();
    for (var i = 0; i < defaults.length; i++) {
      await into(ledgerCategories).insert(
        LedgerCategoriesCompanion.insert(
          id: const Uuid().v4(),
          name: defaults[i],
          sortOrder: Value(i),
          icon: Value(defaultCategoryEmoji[defaults[i]]),
          profileId: Value(profileId),
        ),
      );
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(profiles).insert(
        ProfilesCompanion.insert(
          id: defaultProfileId,
          name: 'Default',
          createdAt: DateTime.now(),
        ),
      );
      await _seedDefaultLedgerCategories(profileId: defaultProfileId);
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
        await m.addColumn(
          calculatorSnapshots,
          calculatorSnapshots.cardEntriesJson,
        );

        const legacyCards = [
          (
            key: 'card_nbe_limit',
            name: 'NBE Wallet',
            bank: 'NBE',
            defaultLimit: 500000.0,
          ),
          (
            key: 'card_cib_explorer_wallet_limit',
            name: 'CIB Explore World',
            bank: 'CIB',
            defaultLimit: 109900.0,
          ),
          (
            key: 'card_cib_platinum_limit',
            name: 'CIB Platinum',
            bank: 'CIB',
            defaultLimit: 145500.0,
          ),
        ];
        for (var i = 0; i < legacyCards.length; i++) {
          final legacy = legacyCards[i];
          final row = await (select(
            calculatorInputs,
          )..where((t) => t.key.equals(legacy.key))).getSingleOrNull();
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
      if (from < 8) {
        await m.addColumn(creditCards, creditCards.lastFourDigits);
      }
      if (from < 9) {
        // Ledgers gained per-ledger "include in Statistics" / "include
        // in Calculator" toggles. Both default to true via the column
        // default, so every existing ledger keeps behaving exactly as
        // before until the user explicitly opts one out.
        await m.addColumn(counterparties, counterparties.includeInStatistics);
        await m.addColumn(counterparties, counterparties.includeInCalculator);
      }
      if (from < 10) {
        // Apartment savings / CIB Accounts Balance became user-managed
        // manual inputs (name/sign/currency, added and removed from
        // Settings) instead of a fixed hardcoded pair. Seed the same two
        // starter rows anyone upgrading already had, so the switch
        // doesn't present an empty list — same spirit as the
        // credit-cards migration at from < 6.
        await m.createTable(manualInputs);
        await m.addColumn(
          calculatorSnapshots,
          calculatorSnapshots.manualInputEntriesJson,
        );

        await into(manualInputs).insert(
          ManualInputsCompanion.insert(
            id: const Uuid().v4(),
            name: 'Apartment savings',
            isAddition: false,
            currency: const Value('EGP'),
            sortOrder: const Value(0),
          ),
        );
        await into(manualInputs).insert(
          ManualInputsCompanion.insert(
            id: const Uuid().v4(),
            name: 'CIB Accounts Balance',
            isAddition: true,
            currency: const Value('EGP'),
            sortOrder: const Value(1),
          ),
        );
      }
      if (from < 11) {
        // Credit cards gained a remembered available-to-spend balance,
        // kept current by SMS capture instead of only ever a value
        // typed into the Calculator for one session.
        await m.addColumn(creditCards, creditCards.currentAvailableBalance);
        await m.addColumn(creditCards, creditCards.balanceUpdatedAt);
      }
      if (from < 12) {
        // Ledger categories gained a user-managed icon (Settings ->
        // Categories & icons) instead of always rendering a generic
        // glyph. Backfill the same sensible defaults a fresh install
        // seeds, by name, so existing categories don't show up blank;
        // anyone whose category name isn't in the default map (a
        // custom-typed one) just keeps the null fallback icon.
        await m.addColumn(ledgerCategories, ledgerCategories.icon);
        for (final entry in defaultCategoryEmoji.entries) {
          await (update(ledgerCategories)
                ..where((c) => c.name.equals(entry.key)))
              .write(LedgerCategoriesCompanion(icon: Value(entry.value)));
        }
      }
      if (from < 13) {
        // Picking "Vehicle" in Add Asset now asks which kind (car,
        // motorcycle, or scooter) so the right icon shows everywhere
        // that asset displays; existing vehicle assets fall back to
        // the generic car icon (null) until edited.
        await m.addColumn(assets, assets.vehicleType);
      }
      if (from < 14) {
        // Profiles: every screen (Net Worth, Ledger, Statistics,
        // Calculator) can now be fully isolated per profile, switched
        // from a picker beside Settings. Seed one profile carrying the
        // fixed id every existing row backfills to, so nothing anyone
        // already had disappears.
        await m.createTable(profiles);
        await into(profiles).insert(
          ProfilesCompanion.insert(
            id: defaultProfileId,
            name: 'Default',
            createdAt: DateTime.now(),
          ),
        );
        await m.addColumn(assets, assets.profileId);
        await m.addColumn(counterparties, counterparties.profileId);
        await m.addColumn(ledgerTransactions, ledgerTransactions.profileId);
        await m.addColumn(calculatorSnapshots, calculatorSnapshots.profileId);
        await m.addColumn(creditCards, creditCards.profileId);
        await m.addColumn(manualInputs, manualInputs.profileId);
        await m.addColumn(ledgerCategories, ledgerCategories.profileId);
        await m.addColumn(vendorRules, vendorRules.profileId);
        const backfill = Value(defaultProfileId);
        await (update(assets)..where((t) => t.profileId.isNull())).write(
          AssetsCompanion(profileId: backfill),
        );
        await (update(counterparties)..where((t) => t.profileId.isNull()))
            .write(CounterpartiesCompanion(profileId: backfill));
        await (update(ledgerTransactions)..where((t) => t.profileId.isNull()))
            .write(LedgerTransactionsCompanion(profileId: backfill));
        await (update(calculatorSnapshots)..where((t) => t.profileId.isNull()))
            .write(CalculatorSnapshotsCompanion(profileId: backfill));
        await (update(creditCards)..where((t) => t.profileId.isNull())).write(
          CreditCardsCompanion(profileId: backfill),
        );
        await (update(manualInputs)..where((t) => t.profileId.isNull())).write(
          ManualInputsCompanion(profileId: backfill),
        );
        await (update(ledgerCategories)..where((t) => t.profileId.isNull()))
            .write(LedgerCategoriesCompanion(profileId: backfill));
        await (update(vendorRules)..where((t) => t.profileId.isNull())).write(
          VendorRulesCompanion(profileId: backfill),
        );
      }
      if (from < 15) {
        // Gold/silver/real estate can now optionally record what was
        // originally paid, so the dashboard can show a gain/loss since
        // purchase. Null (the default for every pre-existing asset)
        // means "not tracked" -- nothing shows until the user fills it
        // in via Edit.
        await m.addColumn(assets, assets.purchasePrice);
        await m.addColumn(assets, assets.purchaseCurrency);
      }
      if (from < 16) {
        // Calculator History's "is this snapshot's card/manual-input
        // breakdown legacy?" check used to infer it purely from
        // cardEntriesJson/manualInputEntriesJson being empty -- which a
        // profile with genuinely zero cards or manual inputs configured
        // at save time also produces, so it fell back to the fixed
        // legacy columns (the same three hardcoded card names /
        // "Apartment savings" / "CIB Accounts Balance" labels on every
        // profile) instead of correctly showing "none". Backfill from
        // the same isEmpty signal the old inference used, since that's
        // the best information available for data written before this
        // flag existed -- it reproduces today's (already-correct for
        // non-empty rows) behavior exactly, while every snapshot saved
        // from now on sets both to `true` unconditionally via the
        // column default and is never ambiguous again.
        await m.addColumn(
          calculatorSnapshots,
          calculatorSnapshots.cardsRecorded,
        );
        await m.addColumn(
          calculatorSnapshots,
          calculatorSnapshots.manualInputsRecorded,
        );
        await customStatement(
          "UPDATE calculator_snapshots SET cards_recorded = (card_entries_json != '[]')",
        );
        await customStatement(
          "UPDATE calculator_snapshots SET manual_inputs_recorded = (manual_input_entries_json != '[]')",
        );
      }
      if (from < 17) {
        // Date purchased -- unlike purchasePrice, asked for on every
        // asset category, not just the ones that can compute a
        // gain/loss. Null (the default for every pre-existing asset)
        // means "not tracked" -- nothing shows until filled in via Edit.
        await m.addColumn(assets, assets.purchaseDate);
      }
      if (from < 18) {
        // New "Recurring payments" tab -- fully new data, so a plain
        // create with no backfill needed.
        await m.createTable(recurringPayments);
      }
      if (from < 19) {
        // Recurring payments: interval ("every N days") and yearly
        // frequencies, alongside the original monthly one, plus the
        // paid/pending tracking that drives the tab's green "paid" state
        // and its this-month total split. Every pre-existing row has no
        // stored frequency, which addColumn's default backfills to
        // 'monthly' -- the only kind that existed before this migration.
        await m.addColumn(recurringPayments, recurringPayments.frequency);
        await m.addColumn(recurringPayments, recurringPayments.intervalDays);
        await m.addColumn(
          recurringPayments,
          recurringPayments.intervalAnchorDate,
        );
        await m.addColumn(recurringPayments, recurringPayments.yearlyMonth);
        await m.addColumn(recurringPayments, recurringPayments.yearlyDay);
        await m.addColumn(recurringPayments, recurringPayments.lastPaidAt);
      }
      if (from < 20) {
        // Auto-recorded monthly history for recurring payments -- fully
        // new data (no prior version could have written it), so a plain
        // create with no backfill needed.
        await m.createTable(recurringPaymentHistory);
      }
      if (from < 21) {
        // Per-item breakdown for each recorded month -- addColumn's
        // '[]' default correctly marks every pre-existing row as
        // predating this feature (see itemsJson's own doc comment for how
        // that stays distinguishable from a real, empty month).
        await m.addColumn(
          recurringPaymentHistory,
          recurringPaymentHistory.itemsJson,
        );
      }
      if (from < 22) {
        // Both addColumn defaults/nulls correctly mark every pre-existing
        // row as predating this feature: every ledger entry that already
        // existed really was typed in by hand ('manual'), and a card whose
        // balance was never touched by either path stays null, matching
        // balanceUpdatedAt's own null in that same case.
        await m.addColumn(ledgerTransactions, ledgerTransactions.source);
        await m.addColumn(creditCards, creditCards.balanceUpdatedSource);
      }
      if (from < 23) {
        // Recurring payments gained free-text notes and an auto/manual
        // payment mode -- every pre-existing row has no notes (null) and
        // defaults to 'auto', which is exactly how every one of them
        // already behaved before this column existed.
        await m.addColumn(recurringPayments, recurringPayments.notes);
        await m.addColumn(recurringPayments, recurringPayments.paymentMode);
      }
      if (from < 24) {
        // Manual inputs gained a persisted `currentValue`, kept live by a
        // debounced save-back the moment the user edits it -- see that
        // column's own doc comment for the "reset itself" bug this fixes.
        // Null (the default for every pre-existing row) correctly falls
        // back to the existing last-saved-snapshot seeding logic.
        await m.addColumn(manualInputs, manualInputs.currentValue);
      }
      if (from < 25) {
        // Ledgers gained a "show in Ledger list" toggle -- every existing
        // ledger defaults to visible, exactly how it already behaved.
        await m.addColumn(counterparties, counterparties.visible);
      }
    },
    // The "Breakfast" quick-pick category was a voice-transcription
    // typo for Breadfast (the actual grocery-delivery app, confirmed by
    // its real bank SMS merchant name) — fix up any rows saved under
    // the old spelling on every open, not just once at migration time,
    // since it's a cheap no-op once there's nothing left to fix.
    //
    // Wrapped defensively: a failure here (e.g. a transient lock from
    // another isolate opening the same database at the same moment --
    // see _openConnection's WAL/busy_timeout setup for the general
    // fix) would otherwise abort opening the database at all, taking
    // down every screen instead of just leaving one stale row
    // unrenamed until the next open retries it.
    beforeOpen: (details) async {
      try {
        await customStatement(
          "UPDATE ledger_transactions SET category = 'Breadfast' WHERE category = 'Breakfast'",
        );
      } catch (_) {
        // Swallow -- see comment above.
      }
    },
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'wealth_tracker',
    native: DriftNativeOptions(
      // The foreground app and a background WorkManager isolate (bank-SMS
      // auto-update, the periodic price refresh, ...) can now both hold
      // this database open at the same time. SQLite's default rollback-
      // journal mode needs an exclusive lock for any write, which two
      // genuinely separate connections collide on easily -- this is what
      // was producing "database is locked" errors. WAL lets readers and
      // writers coexist instead; busy_timeout makes an actual writer-vs-
      // writer collision (WAL still only allows one at a time) wait and
      // retry briefly rather than fail immediately.
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL;');
        db.execute('PRAGMA busy_timeout=5000;');
      },
      shareAcrossIsolates: true,
    ),
  );
}

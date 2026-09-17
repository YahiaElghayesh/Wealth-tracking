import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/sync/drive_snapshot.dart';

/// Exercises `exportSnapshot`/`importSnapshot` against a real database
/// built the same way the app itself does ([AppDatabase.forTesting] with
/// migrations run for real), then checks every table this pair is
/// responsible for -- not just the original handful (assets, the ledger,
/// calculator, vendor rules) but everything added so a delete-and-reinstall
/// followed by signing back in restores the app exactly: profiles, credit
/// cards, bank accounts, manual inputs, calculator snapshots, recurring
/// payments and their history, banks, SMS rules, and tracked returns.
void main() {
  const uuid = Uuid();
  late AppDatabase source;
  late AppDatabase target;

  setUp(() {
    source = AppDatabase.forTesting(NativeDatabase.memory());
    target = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  test(
    'a full round trip restores every synced table onto a different '
    'database, matching row for row',
    () async {
      // A second profile beyond the seeded default -- "all accounts I've
      // created", not just the one every fresh install starts with.
      final secondProfileId = uuid.v4();
      await source
          .into(source.profiles)
          .insert(
            ProfilesCompanion.insert(
              id: secondProfileId,
              name: 'Family',
              createdAt: DateTime.utc(2024, 1, 1),
            ),
          );

      final assetId = uuid.v4();
      await source
          .into(source.assets)
          .insert(
            AssetsCompanion.insert(
              id: assetId,
              name: 'BTC',
              category: 'crypto',
              valuationMode: 'live',
              quantity: 0.5,
              symbolOrCurrency: 'bitcoin',
              createdAt: DateTime.utc(2024, 2, 1),
              updatedAt: DateTime.utc(2024, 2, 2),
              profileId: const Value(defaultProfileId),
            ),
          );

      final counterpartyId = uuid.v4();
      await source
          .into(source.counterparties)
          .insert(
            CounterpartiesCompanion.insert(
              id: counterpartyId,
              name: 'Ahmed',
              profileId: const Value(defaultProfileId),
            ),
          );
      await source
          .into(source.ledgerTransactions)
          .insert(
            LedgerTransactionsCompanion.insert(
              id: uuid.v4(),
              counterpartyId: counterpartyId,
              date: DateTime.utc(2024, 3, 1),
              amount: 250,
              category: 'Family',
              createdAt: DateTime.utc(2024, 3, 1),
              profileId: const Value(defaultProfileId),
            ),
          );

      final bankId = uuid.v4();
      await source
          .into(source.banks)
          .insert(
            BanksCompanion.insert(
              id: bankId,
              name: 'CIB',
              profileId: const Value(defaultProfileId),
            ),
          );
      await source
          .into(source.smsRules)
          .insert(
            SmsRulesCompanion.insert(
              id: uuid.v4(),
              bankId: bankId,
              operation: 'ledgerPayment',
              sampleText: 'Card charged EGP 100 at Test.',
              segmentsJson: '[]',
              createdAt: DateTime.utc(2024, 1, 5),
              profileId: const Value(defaultProfileId),
            ),
          );

      final creditCardId = uuid.v4();
      await source
          .into(source.creditCards)
          .insert(
            CreditCardsCompanion.insert(
              id: creditCardId,
              name: 'Platinum',
              bank: 'CIB',
              limitAmount: 50000,
              profileId: const Value(defaultProfileId),
            ),
          );

      final bankAccountId = uuid.v4();
      await source
          .into(source.bankAccounts)
          .insert(
            BankAccountsCompanion.insert(
              id: bankAccountId,
              name: 'CIB Current',
              bank: 'CIB',
              profileId: const Value(defaultProfileId),
            ),
          );

      await source
          .into(source.manualInputs)
          .insert(
            ManualInputsCompanion.insert(
              id: uuid.v4(),
              name: 'Apartment savings',
              isAddition: true,
              profileId: const Value(defaultProfileId),
            ),
          );

      await source
          .into(source.calculatorInputs)
          .insert(
            CalculatorInputsCompanion.insert(
              key: 'nbe',
              value: 500,
              updatedAt: DateTime.utc(2024, 4, 1),
            ),
          );

      await source
          .into(source.calculatorSnapshots)
          .insert(
            CalculatorSnapshotsCompanion.insert(
              id: uuid.v4(),
              computedAt: DateTime.utc(2024, 4, 2),
              resultAmount: 1234.5,
              ledgersTotal: 250,
              apartmentSavings: 1000,
              cibAccountBalance: 500,
              profileId: const Value(defaultProfileId),
            ),
          );

      final recurringId = uuid.v4();
      await source
          .into(source.recurringPayments)
          .insert(
            RecurringPaymentsCompanion.insert(
              id: recurringId,
              name: 'Netflix',
              amount: 200,
              dayOfMonth: 5,
              profileId: const Value(defaultProfileId),
            ),
          );
      await source
          .into(source.recurringPaymentHistory)
          .insert(
            RecurringPaymentHistoryCompanion.insert(
              id: uuid.v4(),
              year: 2024,
              month: 3,
              totalAmount: 200,
              paidAmount: 200,
              recordedAt: DateTime.utc(2024, 4, 5),
              profileId: const Value(defaultProfileId),
            ),
          );

      await source
          .into(source.returns)
          .insert(
            ReturnsCompanion.insert(
              id: uuid.v4(),
              vendor: 'Amazon',
              amount: 300,
              createdAt: DateTime.utc(2024, 4, 1),
              profileId: const Value(defaultProfileId),
            ),
          );

      final snapshot = await exportSnapshot(source, modifiedAt: DateTime.now());
      await importSnapshot(target, snapshot);

      Future<void> expectSameRows<T>(
        Future<List<T>> Function(AppDatabase) select,
      ) async {
        final sourceRows = await select(source);
        final targetRows = await select(target);
        expect(
          targetRows.length,
          sourceRows.length,
          reason: '$T row count should match after a round trip',
        );
      }

      await expectSameRows((db) => db.select(db.profiles).get());
      await expectSameRows((db) => db.select(db.assets).get());
      await expectSameRows((db) => db.select(db.counterparties).get());
      await expectSameRows((db) => db.select(db.ledgerTransactions).get());
      await expectSameRows((db) => db.select(db.banks).get());
      await expectSameRows((db) => db.select(db.smsRules).get());
      await expectSameRows((db) => db.select(db.creditCards).get());
      await expectSameRows((db) => db.select(db.bankAccounts).get());
      await expectSameRows((db) => db.select(db.manualInputs).get());
      await expectSameRows((db) => db.select(db.calculatorInputs).get());
      await expectSameRows((db) => db.select(db.calculatorSnapshots).get());
      await expectSameRows((db) => db.select(db.recurringPayments).get());
      await expectSameRows((db) => db.select(db.recurringPaymentHistory).get());
      await expectSameRows((db) => db.select(db.returns).get());

      // Spot-check actual field values survive, not just row counts.
      final targetAsset = await (target.select(
        target.assets,
      )..where((a) => a.id.equals(assetId))).getSingle();
      expect(targetAsset.name, 'BTC');
      expect(targetAsset.quantity, 0.5);

      final targetProfiles = await target.select(target.profiles).get();
      expect(targetProfiles.map((p) => p.id), contains(secondProfileId));

      final targetRecurring = await target
          .select(target.recurringPayments)
          .get();
      expect(targetRecurring.single.id, recurringId);
    },
  );

  test('importSnapshot replaces rather than merges', () async {
    await target
        .into(target.assets)
        .insert(
          AssetsCompanion.insert(
            id: uuid.v4(),
            name: 'Stale asset that should be wiped',
            category: 'crypto',
            valuationMode: 'live',
            quantity: 1,
            symbolOrCurrency: 'bitcoin',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            profileId: const Value(defaultProfileId),
          ),
        );

    final emptySnapshot = await exportSnapshot(
      source,
      modifiedAt: DateTime.now(),
    );
    await importSnapshot(target, emptySnapshot);

    final remainingAssets = await target.select(target.assets).get();
    expect(remainingAssets, isEmpty);
  });
}

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/sms/sms_ledger_processor.dart';

const _cibBreadfastSms =
    'Your credit card ending with#4912 was charged for EGP 958.54 at Breadfast '
    'on 27/08/26 at 13:30. Card available limit is EGP 85891.16. For more details, '
    'please visit https://cib.eg/mb';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<String> insertCounterparty(String name) async {
    final id = const Uuid().v4();
    await db
        .into(db.counterparties)
        .insert(
          CounterpartiesCompanion.insert(
            id: id,
            name: name,
            profileId: const Value('test-profile'),
          ),
        );
    return id;
  }

  Future<void> insertCard({
    required String lastFourDigits,
    double currentAvailableBalance = 0,
  }) {
    return db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            id: const Uuid().v4(),
            name: 'Test card',
            bank: 'Test bank',
            limitAmount: 100000,
            currency: const Value('EGP'),
            lastFourDigits: Value(lastFourDigits),
            currentAvailableBalance: Value(currentAvailableBalance),
            profileId: const Value('test-profile'),
          ),
        );
  }

  Future<void> insertVendorRule({
    required String vendorPattern,
    required String counterpartyId,
    required String category,
  }) {
    return db
        .into(db.vendorRules)
        .insert(
          VendorRulesCompanion.insert(
            id: const Uuid().v4(),
            vendorPattern: vendorPattern,
            counterpartyId: counterpartyId,
            category: category,
            profileId: const Value('test-profile'),
          ),
        );
  }

  group('commitSmsQuickAdd', () {
    test('adds a ledger entry when a Vendor Rule matches the sender', () async {
      final counterpartyId = await insertCounterparty('Dad');
      await insertVendorRule(
        vendorPattern: 'Breadfast',
        counterpartyId: counterpartyId,
        category: 'Groceries',
      );

      final added = await commitSmsQuickAdd(
        db,
        body: _cibBreadfastSms,
        timestampMillis: 1000,
        profileId: 'test-profile',
      );

      expect(added, isTrue);
      final rows = await db.select(db.ledgerTransactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.counterpartyId, counterpartyId);
      expect(rows.single.category, 'Groceries');
      expect(rows.single.amount, 958.54);
      expect(rows.single.currency, 'EGP');
      expect(rows.single.source, 'sms');
    });

    test('does nothing when no Vendor Rule matches the sender', () async {
      final added = await commitSmsQuickAdd(
        db,
        body: _cibBreadfastSms,
        timestampMillis: 1000,
        profileId: 'test-profile',
      );

      expect(added, isFalse);
      expect(await db.select(db.ledgerTransactions).get(), isEmpty);
    });

    test('does nothing for text that does not parse as a bank SMS', () async {
      final added = await commitSmsQuickAdd(
        db,
        body: 'Your OTP is 123456.',
        timestampMillis: 1000,
        profileId: 'test-profile',
      );

      expect(added, isFalse);
      expect(await db.select(db.ledgerTransactions).get(), isEmpty);
    });

    test(
      'the same SMS is only ever committed once, even across repeated calls',
      () async {
        final counterpartyId = await insertCounterparty('Dad');
        await insertVendorRule(
          vendorPattern: 'Breadfast',
          counterpartyId: counterpartyId,
          category: 'Groceries',
        );

        final first = await commitSmsQuickAdd(
          db,
          body: _cibBreadfastSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );
        final second = await commitSmsQuickAdd(
          db,
          body: _cibBreadfastSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(first, isTrue);
        expect(second, isFalse);
        expect(await db.select(db.ledgerTransactions).get(), hasLength(1));
      },
    );

    test(
      'a card-payment SMS updates the balance but is never added as a ledger entry',
      () async {
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );
        const cibPaymentSms =
            'نشكركم على سداد مبلغ 8860.36 جم لبطاقة رقم 8455 يوم 28/08';

        final added = await commitSmsQuickAdd(
          db,
          body: cibPaymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(added, isFalse);
        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, 50000 + 8860.36);
      },
    );
  });

  group('commitSmsAutoUpdate', () {
    test('a card-payment SMS updates the balance with no ledger entry', () async {
      await insertCard(lastFourDigits: '4912', currentAvailableBalance: 50000);
      const nbePaymentSms =
          'تم سداد مبلغ 100000.00 جم فى بطاقتكم الائتمانية المنتهية بـ 4912 بتاريخ 21-08-26';

      await commitSmsAutoUpdate(
        db,
        body: nbePaymentSms,
        timestampMillis: 1000,
        profileId: 'test-profile',
      );

      expect(await db.select(db.ledgerTransactions).get(), isEmpty);
      final card = await db.select(db.creditCards).getSingle();
      expect(card.currentAvailableBalance, 50000 + 100000.00);
    });

    test('does nothing for text that does not parse as a bank SMS', () async {
      await commitSmsAutoUpdate(
        db,
        body: 'Your OTP is 123456.',
        timestampMillis: 1000,
        profileId: 'test-profile',
      );

      expect(await db.select(db.creditCards).get(), isEmpty);
    });

    test(
      'the same SMS is only ever applied once, even across repeated calls',
      () async {
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );
        const cibPaymentSms =
            'نشكركم على سداد مبلغ 8860.36 جم لبطاقة رقم 8455 يوم 28/08';

        await commitSmsAutoUpdate(
          db,
          body: cibPaymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );
        await commitSmsAutoUpdate(
          db,
          body: cibPaymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, 50000 + 8860.36);
      },
    );

    test(
      'a charge SMS still updates the balance even though it is not meant to reach this path',
      () async {
        await insertCard(
          lastFourDigits: '4912',
          currentAvailableBalance: 50000,
        );

        await commitSmsAutoUpdate(
          db,
          body: _cibBreadfastSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, 85891.16);
      },
    );
  });

  group('commitSmsBalanceUpdate', () {
    test(
      'updates the matching card balance from a charge SMS, with no ledger entry',
      () async {
        await insertCard(
          lastFourDigits: '4912',
          currentAvailableBalance: 50000,
        );

        await commitSmsBalanceUpdate(
          db,
          body: _cibBreadfastSms,
          timestampMillis: 1000,
        );

        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, 85891.16);
      },
    );

    test('does nothing for text that does not parse as a bank SMS', () async {
      await insertCard(lastFourDigits: '4912', currentAvailableBalance: 50000);

      await commitSmsBalanceUpdate(
        db,
        body: 'Your OTP is 123456.',
        timestampMillis: 1000,
      );

      final card = await db.select(db.creditCards).getSingle();
      expect(card.currentAvailableBalance, 50000);
    });

    test(
      'the same SMS only ever applies its balance effect once, even across repeated calls',
      () async {
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );
        const cibPaymentSms =
            'نشكركم على سداد مبلغ 8860.36 جم لبطاقة رقم 8455 يوم 28/08';

        await commitSmsBalanceUpdate(
          db,
          body: cibPaymentSms,
          timestampMillis: 1000,
        );
        await commitSmsBalanceUpdate(
          db,
          body: cibPaymentSms,
          timestampMillis: 1000,
        );

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, 50000 + 8860.36);
      },
    );

    test(
      'a balance already applied by commitSmsBalanceUpdate is not double-applied when '
      'commitSmsQuickAdd later runs for the same SMS',
      () async {
        // _cibBreadfastSms states its own post-charge available balance
        // (85891.16), so updateCardBalanceFromSms would just re-assert that
        // same figure harmlessly either way -- this uses a payment SMS
        // instead, whose fallback math (current + amount) is NOT idempotent,
        // to actually prove the shared dedupe key is doing something.
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );
        const cibPaymentSms =
            'نشكركم على سداد مبلغ 8860.36 جم لبطاقة رقم 8455 يوم 28/08';

        // Simulates SmsReceiver.kt enqueuing the silent balance update
        // alongside a notification, followed by the user later tapping
        // that notification (processIncomingSms's headless-equivalent for
        // this scenario is commitSmsQuickAdd, since a payment SMS is not a
        // charge and never opens the review screen either way).
        await commitSmsBalanceUpdate(
          db,
          body: cibPaymentSms,
          timestampMillis: 1000,
        );
        await commitSmsQuickAdd(
          db,
          body: cibPaymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, 50000 + 8860.36);
      },
    );

    test(
      'a balance already applied by commitSmsBalanceUpdate is not double-applied when '
      'commitSmsAutoUpdate later runs for the same SMS',
      () async {
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );
        const cibPaymentSms =
            'نشكركم على سداد مبلغ 8860.36 جم لبطاقة رقم 8455 يوم 28/08';

        await commitSmsBalanceUpdate(
          db,
          body: cibPaymentSms,
          timestampMillis: 1000,
        );
        await commitSmsAutoUpdate(
          db,
          body: cibPaymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, 50000 + 8860.36);
      },
    );
  });
}

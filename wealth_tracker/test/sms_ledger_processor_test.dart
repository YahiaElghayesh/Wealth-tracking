import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:wealth_tracker/core/models/sms_rule_segment.dart';
import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/sms/sms_ledger_processor.dart';
import 'package:wealth_tracker/data/sms/sms_rule_engine.dart';

/// A charge shaped like the app's old hardwired CIB pattern -- card number,
/// value (stated post-charge available balance), vendor -- but matched
/// here by a *rule* built from a marked-up sample, not hardwired code.
const _chargeSms =
    'Card #4912 charged EGP 958.54 at Breadfast. Available limit EGP 85891.16.';

/// A card-payment (paying the card down, the opposite of a charge) shaped
/// like the app's old hardwired CIB Arabic payment pattern -- no stated
/// resulting balance, so the matching rule's role is "add" (net onto
/// whatever's already tracked) rather than "set".
const _paymentSms = 'Payment of EGP 8860.36 received on card #8455.';

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

  Future<String> insertBank() async {
    final id = const Uuid().v4();
    await db
        .into(db.banks)
        .insert(BanksCompanion.insert(id: id, name: 'Test bank'));
    return id;
  }

  /// A rule matching [_chargeSms]: card number, a "set" value (the stated
  /// post-charge available balance), and a vendor -- everything a real
  /// 'creditCardBalance' or 'ledgerPayment' rule built from this same
  /// sample would carry.
  List<SmsRuleSegment> chargeSegments() => [
    const SmsRuleSegment.literal('Card #'),
    const SmsRuleSegment.placeholder(text: '4912', tag: 'cardNumber'),
    const SmsRuleSegment.literal(' charged EGP 958.54 at '),
    const SmsRuleSegment.placeholder(text: 'Breadfast', tag: 'vendor'),
    const SmsRuleSegment.literal('. Available limit EGP '),
    const SmsRuleSegment.placeholder(
      text: '85891.16',
      tag: 'value',
      role: 'set',
    ),
    const SmsRuleSegment.literal('.'),
  ];

  /// A rule matching [_paymentSms]: an "add" value (nets onto whatever
  /// balance is already tracked, since no resulting balance is stated) and
  /// a card number.
  List<SmsRuleSegment> paymentSegments() => [
    const SmsRuleSegment.literal('Payment of EGP '),
    const SmsRuleSegment.placeholder(
      text: '8860.36',
      tag: 'value',
      role: 'add',
    ),
    const SmsRuleSegment.literal(' received on card #'),
    const SmsRuleSegment.placeholder(text: '8455', tag: 'cardNumber'),
    const SmsRuleSegment.literal('.'),
  ];

  Future<void> insertLedgerPaymentRule(String bankId, String counterpartyId) {
    return db
        .into(db.smsRules)
        .insert(
          SmsRulesCompanion.insert(
            id: const Uuid().v4(),
            bankId: bankId,
            operation: 'ledgerPayment',
            sampleText: _chargeSms,
            segmentsJson: encodeSmsRuleSegments(chargeSegments()),
            targetCounterpartyId: Value(counterpartyId),
            currency: const Value('EGP'),
            createdAt: DateTime(2026),
            profileId: const Value('test-profile'),
          ),
        );
  }

  Future<void> insertCreditCardBalanceRule(
    String bankId,
    List<SmsRuleSegment> segments,
    String sampleText,
  ) {
    return db
        .into(db.smsRules)
        .insert(
          SmsRulesCompanion.insert(
            id: const Uuid().v4(),
            bankId: bankId,
            operation: 'creditCardBalance',
            sampleText: sampleText,
            segmentsJson: encodeSmsRuleSegments(segments),
            createdAt: DateTime(2026),
            profileId: const Value('test-profile'),
          ),
        );
  }

  group('commitSmsQuickAdd', () {
    test('adds a ledger entry when a ledgerPayment rule matches', () async {
      final bankId = await insertBank();
      final counterpartyId = await insertCounterparty('Dad');
      await insertLedgerPaymentRule(bankId, counterpartyId);

      final added = await commitSmsQuickAdd(
        db,
        body: _chargeSms,
        timestampMillis: 1000,
        profileId: 'test-profile',
      );

      expect(added, isTrue);
      final rows = await db.select(db.ledgerTransactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.counterpartyId, counterpartyId);
      expect(rows.single.category, 'Breadfast');
      expect(rows.single.amount, closeTo(85891.16, 0.001));
      expect(rows.single.currency, 'EGP');
      expect(rows.single.source, 'sms');
    });

    test('does nothing when no SMS Rule matches', () async {
      final added = await commitSmsQuickAdd(
        db,
        body: _chargeSms,
        timestampMillis: 1000,
        profileId: 'test-profile',
      );

      expect(added, isFalse);
      expect(await db.select(db.ledgerTransactions).get(), isEmpty);
    });

    test('does nothing for unrelated text', () async {
      final bankId = await insertBank();
      final counterpartyId = await insertCounterparty('Dad');
      await insertLedgerPaymentRule(bankId, counterpartyId);

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
        final bankId = await insertBank();
        final counterpartyId = await insertCounterparty('Dad');
        await insertLedgerPaymentRule(bankId, counterpartyId);

        final first = await commitSmsQuickAdd(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );
        final second = await commitSmsQuickAdd(
          db,
          body: _chargeSms,
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
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(
          bankId,
          paymentSegments(),
          _paymentSms,
        );
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );

        final added = await commitSmsQuickAdd(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(added, isFalse);
        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(50000 + 8860.36, 0.001));
      },
    );
  });

  group('commitSmsAutoUpdate', () {
    test(
      'a card-payment SMS updates the balance with no ledger entry',
      () async {
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(
          bankId,
          paymentSegments(),
          _paymentSms,
        );
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );

        await commitSmsAutoUpdate(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(50000 + 8860.36, 0.001));
      },
    );

    test('does nothing for text that matches no rule', () async {
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
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(
          bankId,
          paymentSegments(),
          _paymentSms,
        );
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );

        await commitSmsAutoUpdate(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );
        await commitSmsAutoUpdate(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(50000 + 8860.36, 0.001));
      },
    );

    test(
      'a charge SMS still updates the balance even though it is not meant to reach this path',
      () async {
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(bankId, chargeSegments(), _chargeSms);
        await insertCard(
          lastFourDigits: '4912',
          currentAvailableBalance: 50000,
        );

        await commitSmsAutoUpdate(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(85891.16, 0.001));
      },
    );
  });

  group('commitSmsBalanceUpdate', () {
    test(
      'updates the matching card balance from a charge SMS, with no ledger entry',
      () async {
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(bankId, chargeSegments(), _chargeSms);
        await insertCard(
          lastFourDigits: '4912',
          currentAvailableBalance: 50000,
        );

        await commitSmsBalanceUpdate(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
        );

        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(85891.16, 0.001));
      },
    );

    test('does nothing for text that matches no rule', () async {
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
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(
          bankId,
          paymentSegments(),
          _paymentSms,
        );
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );

        await commitSmsBalanceUpdate(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
        );
        await commitSmsBalanceUpdate(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
        );

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(50000 + 8860.36, 0.001));
      },
    );

    test(
      'a balance already applied by commitSmsBalanceUpdate is not double-applied when '
      'commitSmsQuickAdd later runs for the same SMS',
      () async {
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(
          bankId,
          paymentSegments(),
          _paymentSms,
        );
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );

        // Simulates SmsReceiver.kt enqueuing the silent balance update
        // alongside a notification, followed by the user later tapping
        // that notification (processIncomingSms's headless-equivalent for
        // this scenario is commitSmsQuickAdd, since a payment SMS is not a
        // charge and never opens the review screen either way).
        await commitSmsBalanceUpdate(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
        );
        await commitSmsQuickAdd(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(50000 + 8860.36, 0.001));
      },
    );

    test(
      'a balance already applied by commitSmsBalanceUpdate is not double-applied when '
      'commitSmsAutoUpdate later runs for the same SMS',
      () async {
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(
          bankId,
          paymentSegments(),
          _paymentSms,
        );
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );

        await commitSmsBalanceUpdate(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
        );
        await commitSmsAutoUpdate(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(50000 + 8860.36, 0.001));
      },
    );
  });
}

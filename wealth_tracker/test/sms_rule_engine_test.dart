import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:wealth_tracker/core/models/sms_rule_segment.dart';
import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/sms/sms_rule_engine.dart';

/// The same "charged for EGP 958.54 at Breadfast on 27/08/26 ... ending
/// with#4912 ... available limit is EGP 85891.16" style wording the app's
/// old hardwired CIB pattern covered -- marked up here as a *rule* instead:
/// card number, value (set), everything else literal.
const _cardBalanceSample =
    'Your credit card ending with#4912 was charged for EGP 958.54 at '
    'Breadfast on 27/08/26. Card available limit is EGP 85891.16.';

List<SmsRuleSegment> _cardBalanceSegments() => [
  const SmsRuleSegment.literal('Your credit card ending with#'),
  const SmsRuleSegment.placeholder(text: '4912', tag: 'cardNumber'),
  const SmsRuleSegment.literal(
    ' was charged for EGP 958.54 at Breadfast on 27/08/26. '
    'Card available limit is EGP ',
  ),
  const SmsRuleSegment.placeholder(text: '85891.16', tag: 'value', role: 'set'),
  const SmsRuleSegment.literal('.'),
];

const _ledgerPaymentSample =
    'You paid EGP 250.00 to Dad Pharmacy on your behalf.';

List<SmsRuleSegment> _ledgerPaymentSegments() => [
  const SmsRuleSegment.literal('You paid EGP '),
  const SmsRuleSegment.placeholder(
    text: '250.00',
    tag: 'value',
    role: 'charge',
  ),
  const SmsRuleSegment.literal(' to '),
  const SmsRuleSegment.placeholder(text: 'Dad Pharmacy', tag: 'vendor'),
  const SmsRuleSegment.literal(' on your behalf.'),
];

void main() {
  group('compileSmsRulePattern / matchSmsRule', () {
    test('extracts a card number and a value from a real-shaped sample', () {
      final rule = SmsRule(
        id: 'r1',
        bankId: 'b1',
        operation: 'creditCardBalance',
        sampleText: _cardBalanceSample,
        segmentsJson: encodeSmsRuleSegments(_cardBalanceSegments()),
        targetCounterpartyId: null,
        currency: null,
        notifyOnMatch: false,
        createdAt: DateTime(2026),
        profileId: null,
      );

      final match = matchSmsRule(rule, _cardBalanceSample);

      expect(match, isNotNull);
      expect(match!.cardNumber, '4912');
      expect(match.value, closeTo(85891.16, 0.001));
      expect(match.valueRole, 'set');
    });

    test('tolerates different whitespace than the sample used', () {
      final rule = SmsRule(
        id: 'r1',
        bankId: 'b1',
        operation: 'creditCardBalance',
        sampleText: _cardBalanceSample,
        segmentsJson: encodeSmsRuleSegments(_cardBalanceSegments()),
        targetCounterpartyId: null,
        currency: null,
        notifyOnMatch: false,
        createdAt: DateTime(2026),
        profileId: null,
      );
      final differentlySpaced =
          'Your credit card ending with#7777 was charged for EGP 958.54 at '
          'Breadfast on 27/08/26.  Card available limit is EGP 12345.60.';

      final match = matchSmsRule(rule, differentlySpaced);

      expect(match, isNotNull);
      expect(match!.cardNumber, '7777');
      expect(match.value, closeTo(12345.60, 0.001));
    });

    test('does not match unrelated text', () {
      final rule = SmsRule(
        id: 'r1',
        bankId: 'b1',
        operation: 'creditCardBalance',
        sampleText: _cardBalanceSample,
        segmentsJson: encodeSmsRuleSegments(_cardBalanceSegments()),
        targetCounterpartyId: null,
        currency: null,
        notifyOnMatch: false,
        createdAt: DateTime(2026),
        profileId: null,
      );

      expect(matchSmsRule(rule, 'Your OTP is 123456.'), isNull);
    });

    test('a vendor placeholder stops at the next literal segment', () {
      final rule = SmsRule(
        id: 'r2',
        bankId: 'b1',
        operation: 'ledgerPayment',
        sampleText: _ledgerPaymentSample,
        segmentsJson: encodeSmsRuleSegments(_ledgerPaymentSegments()),
        targetCounterpartyId: null,
        currency: null,
        notifyOnMatch: false,
        createdAt: DateTime(2026),
        profileId: null,
      );

      final match = matchSmsRule(
        rule,
        'You paid EGP 99.50 to Dad Groceries on your behalf.',
      );

      expect(match, isNotNull);
      expect(match!.value, closeTo(99.50, 0.001));
      expect(match.vendor, 'Dad Groceries');
      expect(match.valueRole, 'charge');
    });

    test('invisible bidi marks around a value do not break matching', () {
      final rule = SmsRule(
        id: 'r1',
        bankId: 'b1',
        operation: 'creditCardBalance',
        sampleText: _cardBalanceSample,
        segmentsJson: encodeSmsRuleSegments(_cardBalanceSegments()),
        targetCounterpartyId: null,
        currency: null,
        notifyOnMatch: false,
        createdAt: DateTime(2026),
        profileId: null,
      );
      final withBidiMarks =
          'Your credit card ending with#4912 was charged for EGP 958.54 at '
          'Breadfast on 27/08/26. Card available limit is EGP '
          '‎85891.16‏.';

      final match = matchSmsRule(rule, withBidiMarks);

      expect(match, isNotNull);
      expect(match!.value, closeTo(85891.16, 0.001));
    });
  });

  group('applySmsRule', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<String> insertBank(String name) async {
      final id = const Uuid().v4();
      await db.into(db.banks).insert(BanksCompanion.insert(id: id, name: name));
      return id;
    }

    Future<void> insertCard({
      required String bank,
      required String lastFourDigits,
      double? currentAvailableBalance,
    }) {
      return db
          .into(db.creditCards)
          .insert(
            CreditCardsCompanion.insert(
              id: const Uuid().v4(),
              name: 'Test card',
              bank: bank,
              limitAmount: 100000,
              lastFourDigits: Value(lastFourDigits),
              currentAvailableBalance: Value(currentAvailableBalance),
            ),
          );
    }

    Future<void> insertBankAccount({
      required String bank,
      required String accountNumber,
      double? currentAvailableBalance,
    }) {
      return db
          .into(db.bankAccounts)
          .insert(
            BankAccountsCompanion.insert(
              id: const Uuid().v4(),
              name: 'Test account',
              bank: bank,
              accountNumber: Value(accountNumber),
              currentAvailableBalance: Value(currentAvailableBalance),
            ),
          );
    }

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

    test(
      'creditCardBalance "set" replaces the tracked balance outright',
      () async {
        final bankId = await insertBank('CIB');
        await insertCard(
          bank: 'CIB',
          lastFourDigits: '4912',
          currentAvailableBalance: 1000,
        );
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'creditCardBalance',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: null,
          currency: null,
          notifyOnMatch: true,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          cardNumber: '4912',
          value: 85891.16,
          valueRole: 'set',
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isTrue);
        expect(outcome.notificationTitle, isNotNull);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(85891.16, 0.001));
        expect(card.balanceUpdatedSource, 'sms');
      },
    );

    test('creditCardBalance "subtract" nets off the current balance', () async {
      final bankId = await insertBank('CIB');
      await insertCard(
        bank: 'CIB',
        lastFourDigits: '4912',
        currentAvailableBalance: 1000,
      );
      final rule = SmsRule(
        id: 'r1',
        bankId: bankId,
        operation: 'creditCardBalance',
        sampleText: '',
        segmentsJson: '[]',
        targetCounterpartyId: null,
        currency: null,
        notifyOnMatch: false,
        createdAt: DateTime(2026),
        profileId: null,
      );
      const match = SmsRuleMatch(
        cardNumber: '4912',
        value: 250,
        valueRole: 'subtract',
      );

      await applySmsRule(db, rule, match);

      final card = await db.select(db.creditCards).getSingle();
      expect(card.currentAvailableBalance, closeTo(750, 0.001));
    });

    test(
      'creditCardBalance does not cross into a same-number card at a different bank',
      () async {
        final cibBankId = await insertBank('CIB');
        await insertBank('NBE');
        await insertCard(bank: 'NBE', lastFourDigits: '4912');
        final rule = SmsRule(
          id: 'r1',
          bankId: cibBankId,
          operation: 'creditCardBalance',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: null,
          currency: null,
          notifyOnMatch: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          cardNumber: '4912',
          value: 500,
          valueRole: 'set',
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isFalse);
      },
    );

    test('bankAccountBalance "add" adds to the current balance', () async {
      final bankId = await insertBank('CIB');
      await insertBankAccount(
        bank: 'CIB',
        accountNumber: '1234567',
        currentAvailableBalance: 500,
      );
      final rule = SmsRule(
        id: 'r1',
        bankId: bankId,
        operation: 'bankAccountBalance',
        sampleText: '',
        segmentsJson: '[]',
        targetCounterpartyId: null,
        currency: null,
        notifyOnMatch: false,
        createdAt: DateTime(2026),
        profileId: null,
      );
      const match = SmsRuleMatch(
        cardNumber: '1234567',
        value: 1000,
        valueRole: 'add',
      );

      await applySmsRule(db, rule, match);

      final account = await db.select(db.bankAccounts).getSingle();
      expect(account.currentAvailableBalance, closeTo(1500, 0.001));
    });

    test('ledgerPayment adds a charge entry to the target ledger', () async {
      final bankId = await insertBank('CIB');
      final counterpartyId = await insertCounterparty('Dad');
      final rule = SmsRule(
        id: 'r1',
        bankId: bankId,
        operation: 'ledgerPayment',
        sampleText: '',
        segmentsJson: '[]',
        targetCounterpartyId: counterpartyId,
        currency: 'EGP',
        notifyOnMatch: true,
        createdAt: DateTime(2026),
        profileId: null,
      );
      const match = SmsRuleMatch(
        value: 250,
        valueRole: 'charge',
        vendor: 'Pharmacy',
      );

      final outcome = await applySmsRule(db, rule, match);

      expect(outcome.applied, isTrue);
      final entry = await db.select(db.ledgerTransactions).getSingle();
      expect(entry.counterpartyId, counterpartyId);
      expect(entry.amount, closeTo(250, 0.001));
      expect(entry.category, 'Pharmacy');
      expect(entry.source, 'sms');
    });

    test(
      'ledgerPayment "repayment" role records a negative (netting) amount',
      () async {
        final bankId = await insertBank('CIB');
        final counterpartyId = await insertCounterparty('Dad');
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'ledgerPayment',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: counterpartyId,
          currency: null,
          notifyOnMatch: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(value: 100, valueRole: 'repayment');

        await applySmsRule(db, rule, match);

        final entry = await db.select(db.ledgerTransactions).getSingle();
        expect(entry.amount, closeTo(-100, 0.001));
        expect(entry.category, 'Other');
      },
    );

    test('a rule with no matching card/account applies nothing', () async {
      final bankId = await insertBank('CIB');
      final rule = SmsRule(
        id: 'r1',
        bankId: bankId,
        operation: 'creditCardBalance',
        sampleText: '',
        segmentsJson: '[]',
        targetCounterpartyId: null,
        currency: null,
        notifyOnMatch: false,
        createdAt: DateTime(2026),
        profileId: null,
      );
      const match = SmsRuleMatch(
        cardNumber: '9999',
        value: 100,
        valueRole: 'set',
      );

      final outcome = await applySmsRule(db, rule, match);

      expect(outcome.applied, isFalse);
    });
  });
}

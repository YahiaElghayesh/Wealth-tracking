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

const _ledgerPaymentWithDateSample =
    'You paid EGP 250.00 to Dad Pharmacy on 27/08/26.';

/// Marks the date with the `ignore` tag -- exactly the "this varies, don't
/// require an exact match" escape hatch for a portion that isn't
/// cardNumber/value/vendor/sender/currency but still changes message to
/// message, which a rule with no way to mark it would otherwise bake into
/// its literal pattern as one specific, never-again-matching date.
List<SmsRuleSegment> _ledgerPaymentWithDateSegments() => [
  const SmsRuleSegment.literal('You paid EGP '),
  const SmsRuleSegment.placeholder(
    text: '250.00',
    tag: 'value',
    role: 'charge',
  ),
  const SmsRuleSegment.literal(' to '),
  const SmsRuleSegment.placeholder(text: 'Dad Pharmacy', tag: 'vendor'),
  const SmsRuleSegment.literal(' on '),
  const SmsRuleSegment.placeholder(text: '27/08/26', tag: 'ignore'),
  const SmsRuleSegment.literal('.'),
];

const _ledgerPaymentWithCurrencySample =
    'You paid 50.00 USD to Dad Pharmacy on your behalf.';

List<SmsRuleSegment> _ledgerPaymentWithCurrencySegments() => [
  const SmsRuleSegment.literal('You paid '),
  const SmsRuleSegment.placeholder(text: '50.00', tag: 'value', role: 'charge'),
  const SmsRuleSegment.literal(' '),
  const SmsRuleSegment.placeholder(text: 'USD', tag: 'currency'),
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
        name: null,
        currency: null,
        notifyOnMatch: false,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
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
        name: null,
        currency: null,
        notifyOnMatch: false,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
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
        name: null,
        currency: null,
        notifyOnMatch: false,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
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
        name: null,
        currency: null,
        notifyOnMatch: false,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
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

    test(
      "an 'ignore'-tagged date matches even when the real SMS's date differs "
      'from the sample it was built from',
      () {
        final rule = SmsRule(
          id: 'r2b',
          bankId: 'b1',
          operation: 'ledgerPayment',
          sampleText: _ledgerPaymentWithDateSample,
          segmentsJson: encodeSmsRuleSegments(_ledgerPaymentWithDateSegments()),
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );

        final match = matchSmsRule(
          rule,
          'You paid EGP 250.00 to Dad Pharmacy on 03/01/27.',
        );

        expect(match, isNotNull);
        expect(match!.value, closeTo(250.00, 0.001));
        expect(match.vendor, 'Dad Pharmacy');
      },
    );

    test('invisible bidi marks around a value do not break matching', () {
      final rule = SmsRule(
        id: 'r1',
        bankId: 'b1',
        operation: 'creditCardBalance',
        sampleText: _cardBalanceSample,
        segmentsJson: encodeSmsRuleSegments(_cardBalanceSegments()),
        targetCounterpartyId: null,
        name: null,
        currency: null,
        notifyOnMatch: false,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
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

    test('a currency tag captures an ISO code directly', () {
      final rule = SmsRule(
        id: 'r3',
        bankId: 'b1',
        operation: 'ledgerPayment',
        sampleText: _ledgerPaymentWithCurrencySample,
        segmentsJson: encodeSmsRuleSegments(
          _ledgerPaymentWithCurrencySegments(),
        ),
        targetCounterpartyId: null,
        name: null,
        currency: 'EGP',
        notifyOnMatch: false,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
        createdAt: DateTime(2026),
        profileId: null,
      );

      final match = matchSmsRule(rule, _ledgerPaymentWithCurrencySample);

      expect(match, isNotNull);
      expect(match!.currency, 'USD');
    });

    test('a currency tag resolves a bare symbol to its ISO code', () {
      final rule = SmsRule(
        id: 'r3',
        bankId: 'b1',
        operation: 'ledgerPayment',
        sampleText: _ledgerPaymentWithCurrencySample,
        segmentsJson: encodeSmsRuleSegments(
          _ledgerPaymentWithCurrencySegments(),
        ),
        targetCounterpartyId: null,
        name: null,
        currency: 'EGP',
        notifyOnMatch: false,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
        createdAt: DateTime(2026),
        profileId: null,
      );

      final match = matchSmsRule(
        rule,
        r'You paid 75.00 $ to Dad Groceries on your behalf.',
      );

      expect(match, isNotNull);
      expect(match!.currency, 'USD');
    });

    test(
      'a currency tag that captures an unrecognized token resolves to null, without failing the rest of the match',
      () {
        final rule = SmsRule(
          id: 'r3',
          bankId: 'b1',
          operation: 'ledgerPayment',
          sampleText: _ledgerPaymentWithCurrencySample,
          segmentsJson: encodeSmsRuleSegments(
            _ledgerPaymentWithCurrencySegments(),
          ),
          targetCounterpartyId: null,
          name: null,
          currency: 'EGP',
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );

        final match = matchSmsRule(
          rule,
          'You paid 75.00 ZZZ to Dad Groceries on your behalf.',
        );

        expect(match, isNotNull);
        expect(match!.currency, isNull);
        expect(match.value, closeTo(75.00, 0.001));
        expect(match.vendor, 'Dad Groceries');
      },
    );

    test(
      'strict mode fails when the untagged wording between tags changes',
      () {
        final rule = SmsRule(
          id: 'r1',
          bankId: 'b1',
          operation: 'creditCardBalance',
          sampleText: _cardBalanceSample,
          segmentsJson: encodeSmsRuleSegments(_cardBalanceSegments()),
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        final differentMerchantAndDate =
            'Your credit card ending with#7777 was charged for EGP 123.45 at '
            'CoffeeShop on 01/01/27. Card available limit is EGP 50000.00.';

        expect(matchSmsRule(rule, differentMerchantAndDate), isNull);
      },
    );

    test(
      'flexible mode tolerates a changed merchant/date/amount between tags, keeping only the anchor words next to each tag',
      () {
        final rule = SmsRule(
          id: 'r1',
          bankId: 'b1',
          operation: 'creditCardBalance',
          sampleText: _cardBalanceSample,
          segmentsJson: encodeSmsRuleSegments(_cardBalanceSegments()),
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'flexible',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        final differentMerchantAndDate =
            'Your credit card ending with#7777 was charged for EGP 123.45 at '
            'CoffeeShop on 01/01/27. Card available limit is EGP 50000.00.';

        final match = matchSmsRule(rule, differentMerchantAndDate);

        expect(match, isNotNull);
        expect(match!.cardNumber, '7777');
        expect(match.value, closeTo(50000.00, 0.001));
      },
    );

    test('flexible mode still requires the anchor words to be present', () {
      final rule = SmsRule(
        id: 'r1',
        bankId: 'b1',
        operation: 'creditCardBalance',
        sampleText: _cardBalanceSample,
        segmentsJson: encodeSmsRuleSegments(_cardBalanceSegments()),
        targetCounterpartyId: null,
        name: null,
        currency: null,
        notifyOnMatch: false,
        matchMode: 'flexible',
        enabled: true,
        autoAddCharges: false,
        createdAt: DateTime(2026),
        profileId: null,
      );

      expect(
        matchSmsRule(rule, 'Your OTP is 123456, do not share it.'),
        isNull,
      );
    });

    test(
      "a 'transactionCurrency' tag is captured independently of 'currency' "
      '-- an international-transaction SMS naming a foreign currency for '
      "the charge itself, while the card's own available limit stays in "
      'its native currency with no currency tag on it at all',
      () {
        const sample =
            'Your credit card ending with#4912 was charged for USD 22.80 '
            'at ANTHROPIC CLAU on 06/09/26. Available limit is EGP '
            '47041.09.';
        final segments = [
          const SmsRuleSegment.literal('Your credit card ending with#'),
          const SmsRuleSegment.placeholder(text: '4912', tag: 'cardNumber'),
          const SmsRuleSegment.literal(' was charged for '),
          const SmsRuleSegment.placeholder(
            text: 'USD',
            tag: 'transactionCurrency',
          ),
          const SmsRuleSegment.literal(' '),
          const SmsRuleSegment.placeholder(
            text: '22.80',
            tag: 'transactionValue',
            role: 'subtract',
          ),
          const SmsRuleSegment.literal(' at '),
          const SmsRuleSegment.placeholder(
            text: 'ANTHROPIC CLAU',
            tag: 'vendor',
          ),
          const SmsRuleSegment.literal(
            ' on 06/09/26. Available limit is EGP ',
          ),
          const SmsRuleSegment.placeholder(
            text: '47041.09',
            tag: 'value',
            role: 'set',
          ),
          const SmsRuleSegment.literal('.'),
        ];
        final rule = SmsRule(
          id: 'r1',
          bankId: 'b1',
          operation: 'creditCardBalance',
          sampleText: sample,
          segmentsJson: encodeSmsRuleSegments(segments),
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );

        final match = matchSmsRule(rule, sample);

        expect(match, isNotNull);
        expect(match!.cardNumber, '4912');
        expect(match.transactionCurrency, 'USD');
        expect(match.transactionValue, closeTo(22.80, 0.001));
        expect(match.currency, isNull);
        expect(match.value, closeTo(47041.09, 0.001));
      },
    );
  });

  group('findUnsatisfiedRequirements', () {
    final rule = SmsRule(
      id: 'r1',
      bankId: 'b1',
      operation: 'creditCardBalance',
      sampleText: _cardBalanceSample,
      segmentsJson: encodeSmsRuleSegments(_cardBalanceSegments()),
      targetCounterpartyId: null,
      name: null,
      currency: null,
      notifyOnMatch: false,
      matchMode: 'strict',
      enabled: true,
      autoAddCharges: false,
      createdAt: DateTime(2026),
      profileId: null,
    );

    test('returns empty for a rule that actually matches', () {
      expect(findUnsatisfiedRequirements(rule, _cardBalanceSample), isEmpty);
    });

    test(
      "reports a strict rule's literal text that doesn't appear anywhere "
      'in the message, independent of where any tag happens to land',
      () {
        const divergent =
            'Your credit card ending with#4912 was charged for something '
            'else entirely, a completely different message from here on.';

        final unsatisfied = findUnsatisfiedRequirements(rule, divergent);

        expect(unsatisfied, hasLength(1));
        expect(
          unsatisfied.single.description,
          '" was charged for EGP 958.54 at Breadfast on 27/08/26. '
          'Card available limit is EGP "',
        );
      },
    );

    test('reports every unmet literal when nothing matches at all', () {
      const unrelated = 'Your OTP is 123456, do not share it with anyone.';

      final unsatisfied = findUnsatisfiedRequirements(rule, unrelated);

      expect(unsatisfied, hasLength(2));
      expect(
        unsatisfied[0].description,
        contains('Your credit card ending with#'),
      );
      expect(unsatisfied[1].description, contains('.'));
    });

    test(
      "a vendor/sender/'ignore' tag correctly covering its portion of the "
      "message doesn't get blamed for a mismatch that's actually in the "
      'literal text after it -- regression coverage for the previous '
      'approach (walking the pattern incrementally), which could blame a '
      'correctly-placed free-form tag for a completely unrelated literal '
      "mismatch further along, since that tag's own greedy/non-greedy "
      'behavior is not well-defined when only part of the pattern is '
      'checked in isolation.',
      () {
        final ignoreRule = SmsRule(
          id: 'r2',
          bankId: 'b1',
          operation: 'creditCardBalance',
          sampleText: 'Card #4912 from SomeVendor. Thanks for shopping.',
          segmentsJson: encodeSmsRuleSegments([
            const SmsRuleSegment.literal('Card #'),
            const SmsRuleSegment.placeholder(text: '4912', tag: 'cardNumber'),
            const SmsRuleSegment.literal(' from '),
            const SmsRuleSegment.placeholder(
              text: 'SomeVendor',
              tag: 'ignore',
            ),
            const SmsRuleSegment.literal('. Thanks for shopping.'),
          ]),
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const divergent =
            'Card #4912 from SomeVendor. Totally different ending here.';

        final unsatisfied = findUnsatisfiedRequirements(ignoreRule, divergent);

        expect(unsatisfied, hasLength(1));
        expect(
          unsatisfied.single.description,
          contains('Thanks for shopping.'),
        );
      },
    );

    test(
      "a flexible rule's long literal is checked as its two anchor "
      'phrases, not the full raw wording -- only an anchor actually '
      'missing is reported, and one present anywhere is not, even far '
      'from where the wildcarded middle would normally sit',
      () {
        final flexibleRule = SmsRule(
          id: 'r3',
          bankId: 'b1',
          operation: 'creditCardBalance',
          sampleText:
              'Card #4912 from SomeVendor. Please note this charge is '
              'final and cannot be reversed once processed today.',
          segmentsJson: encodeSmsRuleSegments([
            const SmsRuleSegment.literal('Card #'),
            const SmsRuleSegment.placeholder(text: '4912', tag: 'cardNumber'),
            const SmsRuleSegment.literal(
              ' from SomeVendor. Please note this charge is final and '
              'cannot be reversed once processed today.',
            ),
          ]),
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'flexible',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        // Keeps the head anchor ("from SomeVendor") but replaces the tail
        // anchor ("processed today.") with something else entirely --
        // only the tail should be reported as unsatisfied.
        const divergent = 'Card #4912 from SomeVendor. Something unrelated.';

        final unsatisfied = findUnsatisfiedRequirements(
          flexibleRule,
          divergent,
        );

        expect(unsatisfied, hasLength(1));
        expect(unsatisfied.single.description, contains('processed today.'));
        expect(unsatisfied.single.description, isNot(contains('SomeVendor')));
      },
    );

    test(
      'reports a requirement that only appears earlier in the message '
      "than the rule's other requirements allow, as out of order -- not "
      'as flatly missing -- since checking every requirement anywhere in '
      "the message independently can't tell those two cases apart, and "
      "they call for different fixes (the text isn't there at all, vs. "
      "the message just doesn't say things in the order this rule "
      'assumes)',
      () {
        final orderRule = SmsRule(
          id: 'r4',
          bankId: 'b1',
          operation: 'creditCardBalance',
          sampleText: 'AAA123BBB',
          segmentsJson: encodeSmsRuleSegments([
            const SmsRuleSegment.literal('AAA'),
            const SmsRuleSegment.placeholder(text: '123', tag: 'ignore'),
            const SmsRuleSegment.literal('BBB'),
          ]),
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        // Both "AAA" and "BBB" are present, but in the wrong relative
        // order -- "BBB" only appears before "AAA", never after it.
        const reversed = 'BBB456AAA';

        final unsatisfied = findUnsatisfiedRequirements(orderRule, reversed);

        expect(unsatisfied, hasLength(1));
        expect(unsatisfied.single.description, contains('"BBB"'));
        expect(unsatisfied.single.description, contains('out of order'));
      },
    );
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
      String? currency,
      String? supplementaryLastFourDigits,
    }) {
      return db
          .into(db.creditCards)
          .insert(
            CreditCardsCompanion.insert(
              id: const Uuid().v4(),
              name: 'Test card',
              bank: bank,
              limitAmount: 100000,
              currency: currency == null
                  ? const Value.absent()
                  : Value(currency),
              lastFourDigits: Value(lastFourDigits),
              supplementaryLastFourDigits: Value(supplementaryLastFourDigits),
              currentAvailableBalance: Value(currentAvailableBalance),
            ),
          );
    }

    Future<void> insertRate(String symbol, double priceUsd) {
      return db
          .into(db.priceCache)
          .insertOnConflictUpdate(
            PriceCacheCompanion.insert(
              symbol: symbol,
              priceUsd: priceUsd,
              fetchedAt: DateTime(2026),
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
          name: null,
          currency: null,
          notifyOnMatch: true,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
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
        // A "set" match has no meaningful signed delta -- the matched value
        // *is* the new balance, not an amount added/subtracted from it, so
        // the notification shouldn't say that one number twice.
        expect(
          '85,891.16'.allMatches(outcome.notificationBody!).length,
          1,
        );
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(85891.16, 0.001));
        expect(card.balanceUpdatedSource, 'sms');
      },
    );

    test(
      "creditCardBalance shows a 'transactionValue' tag's own signed amount "
      "in the notification, separate from the 'set' value that's actually "
      'applied',
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
          name: null,
          currency: null,
          notifyOnMatch: true,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          cardNumber: '4912',
          value: 85891.16,
          valueRole: 'set',
          transactionValue: 250.50,
          transactionValueRole: 'subtract',
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isTrue);
        expect(outcome.notificationBody, contains('-EGP 250.50'));
        expect(outcome.notificationBody, contains('EGP 85,891.16'));
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(85891.16, 0.001));
      },
    );

    test(
      "a 'transactionCurrency' tag shows the transaction in its own "
      "currency, independent of the card's own currency the balance is "
      'tracked (and shown) in',
      () async {
        final bankId = await insertBank('CIB');
        await insertCard(
          bank: 'CIB',
          lastFourDigits: '4912',
          currentAvailableBalance: 1000,
          currency: 'EGP',
        );
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'creditCardBalance',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: true,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          cardNumber: '4912',
          value: 47041.09,
          valueRole: 'set',
          transactionValue: 22.80,
          transactionValueRole: 'subtract',
          transactionCurrency: 'USD',
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isTrue);
        // The transaction itself shows in USD, unconverted -- not silently
        // relabeled (or converted) into the card's own EGP.
        expect(outcome.notificationBody, contains('-USD 22.80'));
        // But the balance itself is set to exactly the untouched EGP figure
        // -- no currency tag was marked on `value`, so it's applied as-is.
        expect(outcome.notificationBody, contains('EGP 47,041.09'));
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(47041.09, 0.001));
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
        name: null,
        currency: null,
        notifyOnMatch: false,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
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
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
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

    test(
      "creditCardBalance matches a card by its supplementary card's number, "
      'updating the same shared balance',
      () async {
        final bankId = await insertBank('CIB');
        await insertCard(
          bank: 'CIB',
          lastFourDigits: '4912',
          supplementaryLastFourDigits: '7788',
          currentAvailableBalance: 1000,
        );
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'creditCardBalance',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          cardNumber: '7788',
          value: 500,
          valueRole: 'set',
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isTrue);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(500, 0.001));
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
        name: null,
        currency: null,
        notifyOnMatch: false,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
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
        name: null,
        currency: 'EGP',
        notifyOnMatch: true,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
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
      'ledgerPayment routes a charge to the vendor-mapped ledger over the '
      "rule's own fallback ledger, case-insensitively",
      () async {
        final bankId = await insertBank('CIB');
        final fallbackId = await insertCounterparty('Fallback');
        final amazonId = await insertCounterparty('Amazon ledger');
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'ledgerPayment',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: fallbackId,
          name: null,
          currency: 'EGP',
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          vendorTargetsJson: encodeVendorTargets([
            VendorLedgerTarget(vendor: 'Amazon', counterpartyId: amazonId),
          ]),
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          value: 100,
          valueRole: 'charge',
          vendor: 'amazon', // different case than the mapping's "Amazon"
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isTrue);
        final entry = await db.select(db.ledgerTransactions).getSingle();
        expect(entry.counterpartyId, amazonId);
      },
    );

    test(
      "ledgerPayment falls back to the rule's own ledger when the matched "
      "vendor isn't in the vendor mapping",
      () async {
        final bankId = await insertBank('CIB');
        final fallbackId = await insertCounterparty('Fallback');
        final amazonId = await insertCounterparty('Amazon ledger');
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'ledgerPayment',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: fallbackId,
          name: null,
          currency: 'EGP',
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          vendorTargetsJson: encodeVendorTargets([
            VendorLedgerTarget(vendor: 'Amazon', counterpartyId: amazonId),
          ]),
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          value: 100,
          valueRole: 'charge',
          vendor: 'Uber',
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isTrue);
        final entry = await db.select(db.ledgerTransactions).getSingle();
        expect(entry.counterpartyId, fallbackId);
      },
    );

    test(
      'ledgerPayment applies nothing for a charge whose vendor matches no '
      "mapping and whose rule has no fallback ledger either -- there's "
      'nothing to auto-apply to, which is what leaves it reviewable',
      () async {
        final bankId = await insertBank('CIB');
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'ledgerPayment',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: null,
          name: null,
          currency: 'EGP',
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: true,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          value: 100,
          valueRole: 'charge',
          vendor: 'Uber',
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isFalse);
        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
      },
    );

    test(
      "ledgerPayment always uses the rule's own fallback ledger for a "
      'repayment, ignoring any vendor mapping',
      () async {
        final bankId = await insertBank('CIB');
        final fallbackId = await insertCounterparty('Fallback');
        final amazonId = await insertCounterparty('Amazon ledger');
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'ledgerPayment',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: fallbackId,
          name: null,
          currency: 'EGP',
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          vendorTargetsJson: encodeVendorTargets([
            VendorLedgerTarget(vendor: 'Amazon', counterpartyId: amazonId),
          ]),
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          value: 100,
          valueRole: 'repayment',
          vendor: 'Amazon',
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isTrue);
        final entry = await db.select(db.ledgerTransactions).getSingle();
        expect(entry.counterpartyId, fallbackId);
      },
    );

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
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
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

    test(
      'ledgerPayment uses the matched currency over the rule\'s default when both are present',
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
          name: null,
          currency: 'EGP',
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          value: 50,
          valueRole: 'charge',
          vendor: 'Pharmacy',
          currency: 'USD',
        );

        await applySmsRule(db, rule, match);

        final entry = await db.select(db.ledgerTransactions).getSingle();
        expect(entry.currency, 'USD');
      },
    );

    test(
      'ledgerPayment falls back to the rule\'s default currency when nothing was matched',
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
          name: null,
          currency: 'EGP',
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          value: 50,
          valueRole: 'charge',
          vendor: 'Pharmacy',
        );

        await applySmsRule(db, rule, match);

        final entry = await db.select(db.ledgerTransactions).getSingle();
        expect(entry.currency, 'EGP');
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
        name: null,
        currency: null,
        notifyOnMatch: false,
        matchMode: 'strict',
        enabled: true,
        autoAddCharges: false,
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

    test(
      'creditCardBalance converts a matched currency that differs from the card\'s own',
      () async {
        final bankId = await insertBank('CIB');
        await insertCard(
          bank: 'CIB',
          lastFourDigits: '4912',
          currentAvailableBalance: 1000,
          currency: 'EGP',
        );
        await insertRate('USD', 1.0);
        await insertRate('EGP', 0.02); // 1 EGP = $0.02, i.e. $1 = 50 EGP
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'creditCardBalance',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          cardNumber: '4912',
          value: 100,
          valueRole: 'add',
          currency: 'USD',
        );

        await applySmsRule(db, rule, match);

        final card = await db.select(db.creditCards).getSingle();
        // $100 converts to 5000 EGP at this rate, added to the existing 1000.
        expect(card.currentAvailableBalance, closeTo(6000, 0.001));
      },
    );

    test(
      "a converted delta's notification shows the raw matched amount and "
      "currency, not the converted one -- without this, a rule that only "
      "tags 'value'/'currency' (there's no separate number in the message "
      "to also tag as 'transactionValue'/'transactionCurrency') would show "
      "the card's own converted currency in the notification with no "
      "indication it was ever converted, silently disagreeing with what "
      'the real SMS actually said',
      () async {
        final bankId = await insertBank('CIB');
        await insertCard(
          bank: 'CIB',
          lastFourDigits: '4912',
          currentAvailableBalance: 1000,
          currency: 'EGP',
        );
        await insertRate('USD', 1.0);
        await insertRate('EGP', 0.02); // 1 EGP = $0.02, i.e. $1 = 50 EGP
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'creditCardBalance',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: true,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          cardNumber: '4912',
          value: 100,
          valueRole: 'add',
          currency: 'USD',
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isTrue);
        expect(outcome.notificationBody, contains('+USD 100'));
        expect(outcome.notificationBody, isNot(contains('5,000')));
        // The "now" balance is still reported in the card's own currency --
        // only the signed delta uses the SMS's own currency.
        expect(outcome.notificationBody, contains('EGP 6,000'));
      },
    );

    test(
      'creditCardBalance applies the value as-is when the matched currency already matches the card\'s own',
      () async {
        final bankId = await insertBank('CIB');
        await insertCard(
          bank: 'CIB',
          lastFourDigits: '4912',
          currentAvailableBalance: 1000,
          currency: 'EGP',
        );
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'creditCardBalance',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          cardNumber: '4912',
          value: 250,
          valueRole: 'add',
          currency: 'EGP',
        );

        await applySmsRule(db, rule, match);

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(1250, 0.001));
      },
    );

    test(
      'creditCardBalance skips applying rather than guessing when a matched currency has no cached rate',
      () async {
        final bankId = await insertBank('CIB');
        await insertCard(
          bank: 'CIB',
          lastFourDigits: '4912',
          currentAvailableBalance: 1000,
          currency: 'EGP',
        );
        final rule = SmsRule(
          id: 'r1',
          bankId: bankId,
          operation: 'creditCardBalance',
          sampleText: '',
          segmentsJson: '[]',
          targetCounterpartyId: null,
          name: null,
          currency: null,
          notifyOnMatch: false,
          matchMode: 'strict',
          enabled: true,
          autoAddCharges: false,
          createdAt: DateTime(2026),
          profileId: null,
        );
        const match = SmsRuleMatch(
          cardNumber: '4912',
          value: 100,
          valueRole: 'add',
          currency: 'USD',
        );

        final outcome = await applySmsRule(db, rule, match);

        expect(outcome.applied, isFalse);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(1000, 0.001));
      },
    );
  });
}

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/sms/bank_sms_parser.dart';
import 'package:wealth_tracker/data/sms/card_balance_updater.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<CreditCard> insertCard({
    required String lastFourDigits,
    String currency = 'EGP',
    double limit = 100000,
    double? currentAvailableBalance,
  }) async {
    final id = const Uuid().v4();
    await db.into(db.creditCards).insert(
          CreditCardsCompanion.insert(
            id: id,
            name: 'Test card',
            bank: 'Test bank',
            limitAmount: limit,
            currency: Value(currency),
            lastFourDigits: Value(lastFourDigits),
            currentAvailableBalance: Value(currentAvailableBalance),
            profileId: const Value('test-profile'),
          ),
        );
    return (db.select(db.creditCards)..where((c) => c.id.equals(id))).getSingle();
  }

  test('prefers the balance the SMS itself stated over deriving one', () async {
    final card = await insertCard(lastFourDigits: '4912', currentAvailableBalance: 50000);
    final parsed = ParsedBankSms(
      vendor: 'Breadfast',
      amount: 959,
      currency: 'EGP',
      occurredAt: DateTime(2026, 1, 1),
      isCharge: true,
      lastFourDigits: '4912',
      availableBalanceAfter: 85891.16,
    );

    final updated = await updateCardBalanceFromSms(db, parsed, profileId: 'test-profile');

    expect(updated, isNotNull);
    expect(updated!.currentAvailableBalance, 85891.16);
    expect(updated.balanceUpdatedAt, isNotNull);
    expect(card.currentAvailableBalance, 50000); // original row untouched
  });

  test('a charge with no stated balance subtracts from what was last known', () async {
    await insertCard(lastFourDigits: '1234', currentAvailableBalance: 10000);
    final parsed = ParsedBankSms(
      vendor: 'Amazon',
      amount: 200,
      currency: 'EGP',
      occurredAt: DateTime(2026, 1, 1),
      isCharge: true,
      lastFourDigits: '1234',
    );

    final updated = await updateCardBalanceFromSms(db, parsed, profileId: 'test-profile');

    expect(updated!.currentAvailableBalance, 9800);
  });

  test('a payment/credit with no stated balance adds instead of subtracting', () async {
    await insertCard(lastFourDigits: '1234', currentAvailableBalance: 10000);
    final parsed = ParsedBankSms(
      vendor: 'Payment received',
      amount: 500,
      currency: 'EGP',
      occurredAt: DateTime(2026, 1, 1),
      isCharge: false,
      lastFourDigits: '1234',
    );

    final updated = await updateCardBalanceFromSms(db, parsed, profileId: 'test-profile');

    expect(updated!.currentAvailableBalance, 10500);
  });

  test('a charge with nothing known yet falls back to the card limit', () async {
    await insertCard(lastFourDigits: '1234', limit: 5000);
    final parsed = ParsedBankSms(
      vendor: 'First charge',
      amount: 300,
      currency: 'EGP',
      occurredAt: DateTime(2026, 1, 1),
      isCharge: true,
      lastFourDigits: '1234',
    );

    final updated = await updateCardBalanceFromSms(db, parsed, profileId: 'test-profile');

    expect(updated!.currentAvailableBalance, 4700);
  });

  test('no matching card returns null and touches nothing', () async {
    await insertCard(lastFourDigits: '1234');
    final parsed = ParsedBankSms(
      vendor: 'Somewhere',
      amount: 100,
      currency: 'EGP',
      occurredAt: DateTime(2026, 1, 1),
      isCharge: true,
      lastFourDigits: '9999',
    );

    expect(await updateCardBalanceFromSms(db, parsed, profileId: 'test-profile'), isNull);
  });

  test('a currency mismatch between the SMS and the card is not applied', () async {
    await insertCard(lastFourDigits: '1234', currency: 'EGP');
    final parsed = ParsedBankSms(
      vendor: 'Somewhere',
      amount: 100,
      currency: 'USD',
      occurredAt: DateTime(2026, 1, 1),
      isCharge: true,
      lastFourDigits: '1234',
    );

    expect(await updateCardBalanceFromSms(db, parsed, profileId: 'test-profile'), isNull);
  });

  test('a stated balance in the card\'s currency is applied even if the charge itself was a different currency', () async {
    await insertCard(lastFourDigits: '8455', currency: 'EGP');
    final parsed = ParsedBankSms(
      vendor: 'HODJAPASHA CULT',
      amount: 85,
      currency: 'USD',
      occurredAt: DateTime(2026, 8, 26, 22, 27),
      isCharge: true,
      lastFourDigits: '8455',
      availableBalanceAfter: 491269.64,
      availableBalanceCurrency: 'EGP',
    );

    final updated = await updateCardBalanceFromSms(db, parsed, profileId: 'test-profile');

    expect(updated, isNotNull);
    expect(updated!.currentAvailableBalance, 491269.64);
  });

  test('no last-4-digits on the SMS returns null (nothing to match against)', () async {
    await insertCard(lastFourDigits: '1234');
    final parsed = ParsedBankSms(
      vendor: 'Somewhere',
      amount: 100,
      currency: 'EGP',
      occurredAt: DateTime(2026, 1, 1),
      isCharge: true,
    );

    expect(await updateCardBalanceFromSms(db, parsed, profileId: 'test-profile'), isNull);
  });
}

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
    await db.into(db.counterparties).insert(
          CounterpartiesCompanion.insert(id: id, name: name, profileId: const Value('test-profile')),
        );
    return id;
  }

  Future<void> insertVendorRule({
    required String vendorPattern,
    required String counterpartyId,
    required String category,
  }) {
    return db.into(db.vendorRules).insert(
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
      await insertVendorRule(vendorPattern: 'Breadfast', counterpartyId: counterpartyId, category: 'Groceries');

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
      expect(rows.single.amount, 959.0);
      expect(rows.single.currency, 'EGP');
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

    test('the same SMS is only ever committed once, even across repeated calls', () async {
      final counterpartyId = await insertCounterparty('Dad');
      await insertVendorRule(vendorPattern: 'Breadfast', counterpartyId: counterpartyId, category: 'Groceries');

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
    });
  });
}

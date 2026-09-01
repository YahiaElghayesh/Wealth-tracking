import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// Scoped to one [profileId] -- see `CalculatorRepository`'s doc comment
/// for the pattern (every query filters to it, every insert stamps it, the
/// provider rebuilds on profile switch).
class RecurringPaymentRepository {
  RecurringPaymentRepository(this._db, this.profileId);

  final AppDatabase _db;
  final String profileId;
  static const _uuid = Uuid();

  Stream<List<RecurringPayment>> watchAll() {
    return (_db.select(_db.recurringPayments)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<void> add({
    required String name,
    required double amount,
    required String currency,
    required bool isExactAmount,
    required int dayOfMonth,
  }) async {
    final count = await (_db.select(
      _db.recurringPayments,
    )..where((t) => t.profileId.equals(profileId))).get();
    await _db
        .into(_db.recurringPayments)
        .insert(
          RecurringPaymentsCompanion.insert(
            id: _uuid.v4(),
            name: name,
            amount: amount,
            currency: Value(currency),
            isExactAmount: Value(isExactAmount),
            dayOfMonth: dayOfMonth,
            sortOrder: Value(count.length),
            profileId: Value(profileId),
          ),
        );
  }

  Future<void> update(RecurringPayment payment) {
    return _db.update(_db.recurringPayments).replace(payment);
  }

  Future<void> delete(String id) {
    return (_db.delete(
      _db.recurringPayments,
    )..where((t) => t.id.equals(id))).go();
  }
}

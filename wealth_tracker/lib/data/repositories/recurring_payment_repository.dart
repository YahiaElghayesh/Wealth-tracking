import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/recurring_payment_frequency.dart';
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
    required RecurringPaymentFrequency frequency,
    int? dayOfMonth,
    int? intervalDays,
    DateTime? intervalAnchorDate,
    int? yearlyMonth,
    int? yearlyDay,
    String? notes,
    String paymentMode = 'auto',
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
            // The column is NOT NULL regardless of frequency (see its own
            // doc comment in tables.dart) -- 1 is a meaningless
            // placeholder for any frequency that doesn't actually use it.
            dayOfMonth: dayOfMonth ?? 1,
            sortOrder: Value(count.length),
            profileId: Value(profileId),
            frequency: Value(frequency.stored),
            intervalDays: Value(intervalDays),
            intervalAnchorDate: Value(intervalAnchorDate),
            yearlyMonth: Value(yearlyMonth),
            yearlyDay: Value(yearlyDay),
            notes: Value(notes),
            paymentMode: Value(paymentMode),
          ),
        );
  }

  Future<void> update(RecurringPayment payment) {
    return _db.update(_db.recurringPayments).replace(payment);
  }

  /// Toggles the "mark as paid" state for the payment's current billing
  /// cycle -- see recurring_payment_due.dart for what "current" means per
  /// frequency. `paid: false` clears it back to pending (an accidental-tap
  /// undo), not just a one-way action.
  Future<void> setPaid(String id, bool paid) {
    return (_db.update(
      _db.recurringPayments,
    )..where((t) => t.id.equals(id))).write(
      RecurringPaymentsCompanion(
        lastPaidAt: Value(paid ? DateTime.now() : null),
      ),
    );
  }

  Future<void> delete(String id) {
    return (_db.delete(
      _db.recurringPayments,
    )..where((t) => t.id.equals(id))).go();
  }
}

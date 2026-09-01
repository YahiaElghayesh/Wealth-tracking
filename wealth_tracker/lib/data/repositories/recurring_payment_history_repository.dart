import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../ledger/ledger_calculator.dart' show convertToSettlement;
import '../recurring/recurring_payment_due.dart';

/// Scoped to one [profileId] -- see `CalculatorRepository`'s doc comment
/// for the pattern.
class RecurringPaymentHistoryRepository {
  RecurringPaymentHistoryRepository(this._db, this.profileId);

  final AppDatabase _db;
  final String profileId;
  static const _uuid = Uuid();

  Stream<List<RecurringPaymentHistoryData>> watchAll() {
    return (_db.select(_db.recurringPaymentHistory)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.year),
            (t) => OrderingTerm.asc(t.month),
          ]))
        .watch();
  }

  /// Records a permanent snapshot of the most recently *completed*
  /// calendar month's recurring-payments total/paid, if one hasn't
  /// already been recorded -- called on every app open (see
  /// `recurringPaymentHistoryAutoRecordProvider`) so the record fills in
  /// on its own, with no "Save" button to remember to press, the moment
  /// the calendar rolls past a month that's due for one.
  ///
  /// Necessarily best-effort: [payments] is read as it's defined *right
  /// now*, not as it stood at the end of that month (nothing else in this
  /// feature keeps that history), so a payment added, edited, or deleted
  /// since then is reflected retroactively into a record meant to
  /// describe the past. Reuses the exact same due-date/paid logic
  /// (recurring_payment_due.dart) the live "this month" totals use, just
  /// evaluated as of that past month's last day instead of today.
  Future<void> ensureRecorded(
    List<RecurringPayment> payments,
    Map<String, double> pricesUsdPerUnit,
  ) async {
    final today = DateTime.now();
    // Day 0 of the current month is the last calendar day of the
    // *previous* one -- the most recently completed month as of today.
    final lastMonthEnd = DateTime(today.year, today.month, 0);

    final existing =
        await (_db.select(_db.recurringPaymentHistory)..where(
              (t) =>
                  t.profileId.equals(profileId) &
                  t.year.equals(lastMonthEnd.year) &
                  t.month.equals(lastMonthEnd.month),
            ))
            .getSingleOrNull();
    if (existing != null) return;

    var total = 0.0;
    var paid = 0.0;
    for (final payment in payments) {
      if (!recurringPaymentIsDueThisMonth(payment, lastMonthEnd)) continue;
      final converted = convertToSettlement(
        payment.amount,
        payment.currency,
        pricesUsdPerUnit,
      );
      if (converted == null) continue;
      total += converted;
      if (recurringPaymentIsPaidForCurrentCycle(payment, lastMonthEnd)) {
        paid += converted;
      }
    }
    // Nothing to record when the feature had nothing due that month at
    // all -- avoids seeding a string of meaningless zero rows before the
    // user ever added a recurring payment.
    if (total <= 0) return;

    await _db
        .into(_db.recurringPaymentHistory)
        .insert(
          RecurringPaymentHistoryCompanion.insert(
            id: _uuid.v4(),
            profileId: Value(profileId),
            year: lastMonthEnd.year,
            month: lastMonthEnd.month,
            totalAmount: total,
            paidAmount: paid,
            recordedAt: DateTime.now(),
          ),
        );
  }
}

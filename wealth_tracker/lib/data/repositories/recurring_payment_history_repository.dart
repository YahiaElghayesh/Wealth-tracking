import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/recurring_payment_history_item.dart';
import '../db/database.dart';
import '../recurring/recurring_payment_month_breakdown.dart';

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
  /// calendar month's recurring-payments total/paid/per-item breakdown, if
  /// one hasn't already been recorded -- called on every app open (see
  /// `recurringPaymentHistoryAutoRecordProvider`) so the record fills in
  /// on its own, with no "Save" button to remember to press, the moment
  /// the calendar rolls past a month that's due for one.
  ///
  /// Necessarily best-effort: [payments] is read as it's defined *right
  /// now*, not as it stood at the end of that month (nothing else in this
  /// feature keeps that history), so a payment added, edited, or deleted
  /// since then is reflected retroactively into a record meant to
  /// describe the past. Reuses the exact same due-date/paid logic the live
  /// "this month" totals use (see [computeRecurringPaymentsMonthBreakdown]),
  /// just evaluated as of that past month's last day instead of today.
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

    final breakdown = computeRecurringPaymentsMonthBreakdown(
      payments,
      lastMonthEnd,
      pricesUsdPerUnit,
    );
    // Nothing to record when the feature had nothing due that month at
    // all -- avoids seeding a string of meaningless zero rows before the
    // user ever added a recurring payment.
    if (breakdown.total <= 0) return;

    await _db
        .into(_db.recurringPaymentHistory)
        .insert(
          RecurringPaymentHistoryCompanion.insert(
            id: _uuid.v4(),
            profileId: Value(profileId),
            year: lastMonthEnd.year,
            month: lastMonthEnd.month,
            totalAmount: breakdown.total,
            paidAmount: breakdown.paid,
            recordedAt: DateTime.now(),
            itemsJson: Value(
              jsonEncode(breakdown.items.map((e) => e.toJson()).toList()),
            ),
          ),
        );
  }
}

extension RecurringPaymentHistoryDataItems on RecurringPaymentHistoryData {
  List<RecurringPaymentHistoryItem> get items {
    final decoded = jsonDecode(itemsJson);
    if (decoded is! List) return const [];
    return decoded
        .cast<Map<String, dynamic>>()
        .map(RecurringPaymentHistoryItem.fromJson)
        .toList();
  }

  /// True for a row recorded before the per-item breakdown existed --
  /// [itemsJson] is always `'[]'` then, which on its own is indistinguishable
  /// from a month that genuinely had zero due payments, except that case
  /// can never reach this row at all: [RecurringPaymentHistoryRepository
  /// .ensureRecorded] only ever inserts one when [totalAmount] is
  /// positive, which requires at least one contributing item.
  bool get itemsAreLegacyMissing => items.isEmpty && totalAmount > 0;
}

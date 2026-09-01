import '../../core/models/recurring_payment_frequency.dart';
import '../db/database.dart';

/// [date] with any time-of-day component stripped, so day-based arithmetic
/// below never trips over a stray hour/minute/millisecond difference.
DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// [year]-[month]-[day], clamped to the last real day of that month when
/// [day] overshoots it (e.g. day 31 in February) -- the same clamping
/// [RecurringPayment.dayOfMonth]'s own doc comment describes.
DateTime _clampedDate(int year, int month, int day) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > daysInMonth ? daysInMonth : day);
}

/// This payment's current billing occurrence, relative to [today] --
/// always *this* period's date, even if it's still upcoming or already
/// passed:
/// - 'monthly': this calendar month's [RecurringPayment.dayOfMonth].
/// - 'yearly': this calendar year's [RecurringPayment.yearlyMonth] /
///   [RecurringPayment.yearlyDay].
/// - 'interval': the next multiple of [RecurringPayment.intervalDays] on
///   or after [RecurringPayment.intervalAnchorDate] that is also on or
///   after [today] -- computed fresh from the anchor every time rather
///   than stored and advanced, so a missed "mark as paid" tap can never
///   leave it out of sync.
DateTime recurringPaymentOccurrenceDate(
  RecurringPayment payment,
  DateTime today,
) {
  final frequency = RecurringPaymentFrequency.fromStored(payment.frequency);
  switch (frequency) {
    case RecurringPaymentFrequency.monthly:
      return _clampedDate(today.year, today.month, payment.dayOfMonth);
    case RecurringPaymentFrequency.yearly:
      final month = payment.yearlyMonth ?? today.month;
      final day = payment.yearlyDay ?? 1;
      return _clampedDate(today.year, month, day);
    case RecurringPaymentFrequency.interval:
      final interval = payment.intervalDays ?? 30;
      final anchor = _dateOnly(payment.intervalAnchorDate ?? today);
      if (interval <= 0) return anchor;
      final todayOnly = _dateOnly(today);
      final daysSinceAnchor = todayOnly.difference(anchor).inDays;
      final cyclesElapsed = daysSinceAnchor <= 0
          ? 0
          : (daysSinceAnchor / interval).ceil();
      return anchor.add(Duration(days: cyclesElapsed * interval));
  }
}

/// The start of the billing cycle [recurringPaymentOccurrenceDate] belongs
/// to -- the boundary a "mark as paid" tap has to land on or after in
/// order to count for the *current* cycle rather than a previous one:
/// - 'monthly': the 1st of this calendar month.
/// - 'yearly': January 1st of this calendar year.
/// - 'interval': [intervalDays] before the current occurrence -- i.e. the
///   previous occurrence date.
DateTime recurringPaymentCycleStart(RecurringPayment payment, DateTime today) {
  final frequency = RecurringPaymentFrequency.fromStored(payment.frequency);
  switch (frequency) {
    case RecurringPaymentFrequency.monthly:
      return DateTime(today.year, today.month, 1);
    case RecurringPaymentFrequency.yearly:
      return DateTime(today.year, 1, 1);
    case RecurringPaymentFrequency.interval:
      final interval = payment.intervalDays ?? 30;
      final occurrence = recurringPaymentOccurrenceDate(payment, today);
      return occurrence.subtract(Duration(days: interval));
  }
}

/// Whether [payment] has already been marked paid for its *current*
/// billing cycle (see [recurringPaymentCycleStart]) -- a paid-mark left
/// over from an earlier cycle doesn't count, so a payment automatically
/// reads as pending again once a new cycle starts.
bool recurringPaymentIsPaidForCurrentCycle(
  RecurringPayment payment,
  DateTime today,
) {
  final lastPaidAt = payment.lastPaidAt;
  if (lastPaidAt == null) return false;
  final cycleStart = recurringPaymentCycleStart(payment, today);
  return !_dateOnly(lastPaidAt).isBefore(cycleStart);
}

/// Whether [payment]'s current occurrence (see
/// [recurringPaymentOccurrenceDate]) falls within [today]'s calendar
/// month -- monthly payments always do; yearly ones only in the one month
/// a year their [RecurringPayment.yearlyMonth] matches; interval ones
/// whenever their next-due date happens to land this month. Drives
/// whether a payment counts toward this month's total at all.
bool recurringPaymentIsDueThisMonth(RecurringPayment payment, DateTime today) {
  final occurrence = recurringPaymentOccurrenceDate(payment, today);
  return occurrence.year == today.year && occurrence.month == today.month;
}

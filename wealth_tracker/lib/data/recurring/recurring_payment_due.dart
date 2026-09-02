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
/// to -- for 'interval' this doubles as the date that cycle's charge was
/// actually due (see [recurringPaymentDueDateForCurrentCycle]):
/// - 'monthly': the 1st of this calendar month.
/// - 'yearly': January 1st of this calendar year.
/// - 'interval': [intervalDays] before the current occurrence -- i.e. the
///   previous occurrence date, which for an "every N days" bill *is* when
///   this cycle's charge happened.
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

/// The date [payment]'s charge for the *current* cycle is actually due --
/// distinct from [recurringPaymentOccurrenceDate], which for 'interval'
/// always points at the *next* (upcoming) occurrence and so can never
/// itself be used to tell "already due" apart from "not yet due":
/// - 'monthly'/'yearly': the specific day within the period (can be
///   upcoming or already passed -- there's a real "before due" gap to
///   detect, e.g. day 20 of a 30-day month).
/// - 'interval': the previous occurrence -- the cycle's own charge date
///   *is* the cycle's start, so once a cycle has begun its charge is
///   already due, with no equivalent gap.
DateTime recurringPaymentDueDateForCurrentCycle(
  RecurringPayment payment,
  DateTime today,
) {
  final frequency = RecurringPaymentFrequency.fromStored(payment.frequency);
  return frequency == RecurringPaymentFrequency.interval
      ? recurringPaymentCycleStart(payment, today)
      : recurringPaymentOccurrenceDate(payment, today);
}

/// Whether [payment] counts as paid for its *current* billing cycle --
/// either because the user tapped "mark as paid" *on or after the cycle's
/// actual due date* (a [RecurringPayment.lastPaidAt] on/after
/// [recurringPaymentDueDateForCurrentCycle], not merely
/// [recurringPaymentCycleStart] -- a tap before the due date itself is
/// recorded but doesn't count as paid yet, see [_PaidToggle]'s own
/// handling of that case), or, automatically, because the cycle's due
/// date has already arrived even without an explicit tap -- so a bill
/// someone always pays on time (or that's charged automatically) reads as
/// paid the moment its date comes due, not only once manually confirmed.
/// Either way this reverts to pending on its own once a new cycle starts,
/// since both the manual mark and the automatic date check are
/// re-evaluated fresh against whatever "today" and "the current cycle"
/// mean at read time.
bool recurringPaymentIsPaidForCurrentCycle(
  RecurringPayment payment,
  DateTime today,
) {
  final dueDate = recurringPaymentDueDateForCurrentCycle(payment, today);
  final lastPaidAt = payment.lastPaidAt;
  if (lastPaidAt != null && !_dateOnly(lastPaidAt).isBefore(dueDate)) {
    return true;
  }
  return !dueDate.isAfter(_dateOnly(today));
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

import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/recurring/recurring_payment_due.dart';

RecurringPayment _payment({
  String frequency = 'monthly',
  int dayOfMonth = 1,
  int? intervalDays,
  DateTime? intervalAnchorDate,
  int? yearlyMonth,
  int? yearlyDay,
  DateTime? lastPaidAt,
}) {
  return RecurringPayment(
    id: 'p1',
    name: 'Netflix',
    amount: 100,
    currency: 'EGP',
    isExactAmount: true,
    dayOfMonth: dayOfMonth,
    sortOrder: 0,
    frequency: frequency,
    intervalDays: intervalDays,
    intervalAnchorDate: intervalAnchorDate,
    yearlyMonth: yearlyMonth,
    yearlyDay: yearlyDay,
    lastPaidAt: lastPaidAt,
  );
}

void main() {
  group('recurringPaymentOccurrenceDate', () {
    test('monthly returns this month\'s day-of-month', () {
      final payment = _payment(frequency: 'monthly', dayOfMonth: 15);
      final occurrence = recurringPaymentOccurrenceDate(
        payment,
        DateTime(2026, 3, 5),
      );
      expect(occurrence, DateTime(2026, 3, 15));
    });

    test('monthly clamps a day past a shorter month\'s last day', () {
      final payment = _payment(frequency: 'monthly', dayOfMonth: 31);
      final occurrence = recurringPaymentOccurrenceDate(
        payment,
        DateTime(2026, 2, 10),
      );
      expect(occurrence, DateTime(2026, 2, 28));
    });

    test('yearly returns this year\'s month/day', () {
      final payment = _payment(
        frequency: 'yearly',
        yearlyMonth: 6,
        yearlyDay: 20,
      );
      final occurrence = recurringPaymentOccurrenceDate(
        payment,
        DateTime(2026, 3, 5),
      );
      expect(occurrence, DateTime(2026, 6, 20));
    });

    test(
      'interval returns the anchor itself when today is on or before it',
      () {
        final payment = _payment(
          frequency: 'interval',
          intervalDays: 10,
          intervalAnchorDate: DateTime(2026, 3, 1),
        );
        final occurrence = recurringPaymentOccurrenceDate(
          payment,
          DateTime(2026, 2, 15),
        );
        expect(occurrence, DateTime(2026, 3, 1));
      },
    );

    test(
      'interval advances by whole multiples of intervalDays past the anchor',
      () {
        final payment = _payment(
          frequency: 'interval',
          intervalDays: 10,
          intervalAnchorDate: DateTime(2026, 3, 1),
        );
        // 12 days after the anchor -- the next multiple of 10 on/after today
        // is day 20 (2 full cycles past the anchor).
        final occurrence = recurringPaymentOccurrenceDate(
          payment,
          DateTime(2026, 3, 13),
        );
        expect(occurrence, DateTime(2026, 3, 21));
      },
    );

    test(
      'interval lands exactly on today when today is itself an occurrence',
      () {
        final payment = _payment(
          frequency: 'interval',
          intervalDays: 10,
          intervalAnchorDate: DateTime(2026, 3, 1),
        );
        final occurrence = recurringPaymentOccurrenceDate(
          payment,
          DateTime(2026, 3, 21),
        );
        expect(occurrence, DateTime(2026, 3, 21));
      },
    );
  });

  group('recurringPaymentIsPaidForCurrentCycle', () {
    test('never marked paid reads as pending', () {
      final payment = _payment(frequency: 'monthly', dayOfMonth: 15);
      expect(
        recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 3, 20)),
        isFalse,
      );
    });

    test('monthly: paid earlier this month still reads as paid', () {
      final payment = _payment(
        frequency: 'monthly',
        dayOfMonth: 15,
        lastPaidAt: DateTime(2026, 3, 15),
      );
      expect(
        recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 3, 28)),
        isTrue,
      );
    });

    test('monthly: a paid-mark from last month reads as pending again', () {
      final payment = _payment(
        frequency: 'monthly',
        dayOfMonth: 15,
        lastPaidAt: DateTime(2026, 2, 15),
      );
      expect(
        recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 3, 1)),
        isFalse,
      );
    });

    test('yearly: paid this calendar year reads as paid', () {
      final payment = _payment(
        frequency: 'yearly',
        yearlyMonth: 1,
        yearlyDay: 5,
        lastPaidAt: DateTime(2026, 1, 5),
      );
      expect(
        recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 11, 1)),
        isTrue,
      );
    });

    test('yearly: a paid-mark from last year reads as pending again', () {
      final payment = _payment(
        frequency: 'yearly',
        yearlyMonth: 1,
        yearlyDay: 5,
        lastPaidAt: DateTime(2025, 1, 5),
      );
      expect(
        recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 1, 1)),
        isFalse,
      );
    });

    test('interval: paid within the current cycle window reads as paid', () {
      final payment = _payment(
        frequency: 'interval',
        intervalDays: 10,
        intervalAnchorDate: DateTime(2026, 3, 1),
        lastPaidAt: DateTime(2026, 3, 12),
      );
      // Occurrence for "today" 3/13 is 3/21 (next multiple >= today);
      // cycle start is 3/11 -- the 3/12 paid-mark falls inside it.
      expect(
        recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 3, 13)),
        isTrue,
      );
    });

    test(
      'interval: paid before the current cycle started reads as pending',
      () {
        final payment = _payment(
          frequency: 'interval',
          intervalDays: 10,
          intervalAnchorDate: DateTime(2026, 3, 1),
          lastPaidAt: DateTime(2026, 3, 1),
        );
        expect(
          recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 3, 13)),
          isFalse,
        );
      },
    );
  });

  group('recurringPaymentIsDueThisMonth', () {
    test('monthly is always due this month', () {
      final payment = _payment(frequency: 'monthly', dayOfMonth: 15);
      expect(
        recurringPaymentIsDueThisMonth(payment, DateTime(2026, 7, 1)),
        isTrue,
      );
    });

    test('yearly is only due in its own month', () {
      final payment = _payment(
        frequency: 'yearly',
        yearlyMonth: 6,
        yearlyDay: 20,
      );
      expect(
        recurringPaymentIsDueThisMonth(payment, DateTime(2026, 6, 1)),
        isTrue,
      );
      expect(
        recurringPaymentIsDueThisMonth(payment, DateTime(2026, 7, 1)),
        isFalse,
      );
    });

    test('interval is due only in the month its next occurrence lands in', () {
      final payment = _payment(
        frequency: 'interval',
        intervalDays: 45,
        intervalAnchorDate: DateTime(2026, 1, 1),
      );
      // Next occurrence on/after 2026-01-20 is 2026-02-15.
      expect(
        recurringPaymentIsDueThisMonth(payment, DateTime(2026, 1, 20)),
        isFalse,
      );
      expect(
        recurringPaymentIsDueThisMonth(payment, DateTime(2026, 2, 10)),
        isTrue,
      );
    });
  });
}

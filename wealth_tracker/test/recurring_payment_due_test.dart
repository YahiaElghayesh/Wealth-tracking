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
    test('never marked paid, and not yet due, reads as pending', () {
      final payment = _payment(frequency: 'monthly', dayOfMonth: 15);
      expect(
        recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 3, 10)),
        isFalse,
      );
    });

    test(
      'monthly: never manually marked, but the due date already passed, auto-reads as paid',
      () {
        // The reported bug: day 1 bills unpaid on day 2 still showed as
        // pending with nothing marked -- a bill someone always pays on
        // time should read as paid once its date comes, not only once
        // someone taps it.
        final payment = _payment(frequency: 'monthly', dayOfMonth: 1);
        expect(
          recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 3, 2)),
          isTrue,
        );
      },
    );

    test(
      'monthly: marked paid before the due date itself does not read as '
      'paid yet -- the reported "shows paid days before it\'s even due" bug',
      () {
        final payment = _payment(
          frequency: 'monthly',
          dayOfMonth: 4,
          lastPaidAt: DateTime(2026, 9, 2),
        );
        expect(
          recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 9, 2)),
          isFalse,
        );
      },
    );

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

    test(
      'yearly: a paid-mark from last year, before this year\'s date is due, reads as pending',
      () {
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
      },
    );

    test(
      'yearly: never manually marked, but this year\'s date already passed, auto-reads as paid',
      () {
        final payment = _payment(
          frequency: 'yearly',
          yearlyMonth: 1,
          yearlyDay: 5,
        );
        expect(
          recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 1, 10)),
          isTrue,
        );
      },
    );

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

    test('interval: an "every N days" bill has no gap before its due date -- '
        'once its cycle has started, it auto-reads as paid even unmarked', () {
      final payment = _payment(
        frequency: 'interval',
        intervalDays: 10,
        intervalAnchorDate: DateTime(2026, 3, 1),
      );
      // Cycle start (the last actual charge date) for "today" 3/13 is
      // 3/11 -- unlike monthly/yearly, an interval bill's charge date
      // *is* its cycle's start, so there's no "not yet due" window
      // inside an already-started cycle.
      expect(
        recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 3, 13)),
        isTrue,
      );
    });

    test(
      'interval: before the very first cycle has even started reads as pending',
      () {
        final payment = _payment(
          frequency: 'interval',
          intervalDays: 10,
          intervalAnchorDate: DateTime(2026, 3, 15),
        );
        expect(
          recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 3, 1)),
          isFalse,
        );
      },
    );

    test('interval: a long interval whose anchor is only a few days out does '
        'not read as already paid -- the real "Talabat Pro" bug (30-day '
        'interval, anchor 2 days ahead of today) reproduced exactly', () {
      // recurringPaymentCycleStart used to compute this as
      // occurrence(9/4) - 30 days = 8/5, and since 8/5 is before today
      // (9/2) that read as "already due" -- weeks before the anchor
      // (the bill's actual first-ever charge) had even arrived.
      final payment = _payment(
        frequency: 'interval',
        intervalDays: 30,
        intervalAnchorDate: DateTime(2026, 9, 4),
      );
      expect(
        recurringPaymentIsPaidForCurrentCycle(payment, DateTime(2026, 9, 2)),
        isFalse,
      );
    });
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

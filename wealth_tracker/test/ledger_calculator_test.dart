import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/ledger/ledger_calculator.dart';

const _prices = {'USD': 1.0, 'EGP': 1 / 48.5};

LedgerTransaction _txn({
  required DateTime date,
  required double amount,
  required String category,
  String currency = 'EGP',
}) {
  return LedgerTransaction(
    id: 'id',
    counterpartyId: 'cp',
    date: date,
    amount: amount,
    currency: currency,
    category: category,
    description: null,
    createdAt: date,
  );
}

void main() {
  group('runningBalance', () {
    test('sums payments and nets out repayments, all in the same currency', () {
      final txns = [
        _txn(date: DateTime(2026, 1, 5), amount: 100, category: 'Groceries'),
        _txn(date: DateTime(2026, 1, 10), amount: 40, category: 'Fuel'),
        _txn(date: DateTime(2026, 1, 20), amount: -50, category: 'Repayment'),
      ];

      final result = runningBalance(txns, _prices);

      expect(result.amount, closeTo(90, 0.001));
      expect(result.unconvertedCount, 0);
    });

    test('converts a USD entry into the EGP settlement total', () {
      final txns = [
        _txn(date: DateTime(2026, 1, 5), amount: 100, category: 'Groceries'),
        _txn(date: DateTime(2026, 1, 6), amount: 20, category: 'Subscription', currency: 'USD'),
      ];

      final result = runningBalance(txns, _prices);

      expect(result.amount, closeTo(100 + 20 * 48.5, 0.001));
    });

    test('excludes entries whose currency has no known rate, rather than mis-counting them', () {
      final txns = [
        _txn(date: DateTime(2026, 1, 5), amount: 100, category: 'Groceries', currency: 'TRY'),
      ];

      final result = runningBalance(txns, _prices);

      expect(result.amount, 0);
      expect(result.unconvertedCount, 1);
    });
  });

  group('monthlyCategoryTotals', () {
    test('groups by category, excludes repayments and other months', () {
      final txns = [
        _txn(date: DateTime(2026, 1, 5), amount: 100, category: 'Groceries'),
        _txn(date: DateTime(2026, 1, 8), amount: 20, category: 'Groceries'),
        _txn(date: DateTime(2026, 1, 10), amount: 40, category: 'Fuel'),
        _txn(date: DateTime(2026, 1, 20), amount: -50, category: 'Repayment'),
        _txn(date: DateTime(2026, 2, 1), amount: 999, category: 'Groceries'),
      ];

      final totals = monthlyCategoryTotals(txns, DateTime(2026, 1), _prices);

      expect(totals['Groceries'], closeTo(120, 0.001));
      expect(totals['Fuel'], closeTo(40, 0.001));
      expect(monthlyExpenseTotal(txns, DateTime(2026, 1), _prices), closeTo(160, 0.001));
      expect(monthlyRepaymentTotal(txns, DateTime(2026, 1), _prices), closeTo(50, 0.001));
    });
  });

  group('monthlySpendTrend', () {
    test('returns one entry per month, oldest first, zero-filling months with no entries', () {
      final txns = [
        _txn(date: DateTime(2026, 1, 5), amount: 100, category: 'Groceries'),
        _txn(date: DateTime(2026, 3, 5), amount: 40, category: 'Fuel'),
      ];

      final trend = monthlySpendTrend(txns, _prices, months: 3, asOf: DateTime(2026, 3, 15));

      expect(trend.map((m) => m.month), [DateTime(2026, 1), DateTime(2026, 2), DateTime(2026, 3)]);
      expect(trend[0].amount, closeTo(100, 0.001));
      expect(trend[1].amount, 0);
      expect(trend[2].amount, closeTo(40, 0.001));
    });

    test('rolls over the year boundary correctly', () {
      final trend = monthlySpendTrend(const [], _prices, months: 3, asOf: DateTime(2026, 1, 15));
      expect(trend.map((m) => m.month), [DateTime(2025, 11), DateTime(2025, 12), DateTime(2026, 1)]);
    });
  });

  group('categoryTotalsAllTime', () {
    test('sums expenses by category across every month, excluding repayments', () {
      final txns = [
        _txn(date: DateTime(2026, 1, 5), amount: 100, category: 'Talabat'),
        _txn(date: DateTime(2026, 2, 5), amount: 50, category: 'Talabat'),
        _txn(date: DateTime(2026, 2, 6), amount: 30, category: 'Amazon'),
        _txn(date: DateTime(2026, 3, 1), amount: -20, category: 'Repayment'),
      ];

      final totals = categoryTotalsAllTime(txns, _prices);

      expect(totals['Talabat'], closeTo(150, 0.001));
      expect(totals['Amazon'], closeTo(30, 0.001));
      expect(totals.containsKey('Repayment'), isFalse);
    });
  });
}

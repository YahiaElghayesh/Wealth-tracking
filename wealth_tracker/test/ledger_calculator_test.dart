import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/ledger/ledger_calculator.dart';

LedgerTransaction _txn({
  required DateTime date,
  required double amount,
  required String category,
}) {
  return LedgerTransaction(
    id: 'id',
    counterpartyId: 'cp',
    date: date,
    amount: amount,
    category: category,
    description: null,
    createdAt: date,
  );
}

void main() {
  group('runningBalance', () {
    test('sums payments and nets out repayments', () {
      final txns = [
        _txn(date: DateTime(2026, 1, 5), amount: 100, category: 'Groceries'),
        _txn(date: DateTime(2026, 1, 10), amount: 40, category: 'Fuel'),
        _txn(date: DateTime(2026, 1, 20), amount: -50, category: 'Repayment'),
      ];

      expect(runningBalance(txns), 90);
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

      final totals = monthlyCategoryTotals(txns, DateTime(2026, 1));

      expect(totals, {'Groceries': 120, 'Fuel': 40});
      expect(monthlyExpenseTotal(txns, DateTime(2026, 1)), 160);
      expect(monthlyRepaymentTotal(txns, DateTime(2026, 1)), 50);
    });
  });
}

import '../db/database.dart';

/// Sum of all entries for a counterparty. Positive means they owe the
/// user; negative would mean the user owes them (shouldn't normally
/// happen, but isn't disallowed).
double runningBalance(Iterable<LedgerTransaction> transactions) {
  return transactions.fold(0.0, (sum, t) => sum + t.amount);
}

bool _isSameMonth(DateTime date, DateTime month) {
  return date.year == month.year && date.month == month.month;
}

/// Expense entries (positive amounts) for [month], grouped and summed by
/// category. Repayments are excluded — they reduce the balance but aren't
/// part of "what was spent this month".
Map<String, double> monthlyCategoryTotals(
  Iterable<LedgerTransaction> transactions,
  DateTime month,
) {
  final totals = <String, double>{};
  for (final t in transactions) {
    if (t.amount <= 0 || !_isSameMonth(t.date, month)) continue;
    totals[t.category] = (totals[t.category] ?? 0) + t.amount;
  }
  return totals;
}

double monthlyExpenseTotal(Iterable<LedgerTransaction> transactions, DateTime month) {
  return monthlyCategoryTotals(transactions, month).values.fold(0.0, (a, b) => a + b);
}

double monthlyRepaymentTotal(Iterable<LedgerTransaction> transactions, DateTime month) {
  var total = 0.0;
  for (final t in transactions) {
    if (t.amount < 0 && _isSameMonth(t.date, month)) total += -t.amount;
  }
  return total;
}

import '../../core/models/currency.dart';
import '../db/database.dart';

/// Converts [amount] (in [currency]) into [settlementCurrency] using the
/// same "USD value per unit" price map net worth uses. Returns `null` if
/// either currency's rate isn't known yet, rather than silently treating a
/// missing rate as 1:1.
double? convertToSettlement(
  double amount,
  String currency,
  Map<String, double> pricesUsdPerUnit, {
  String settlementCurrency = defaultCurrency,
}) {
  final rate = pricesUsdPerUnit[currency];
  final settlementRate = pricesUsdPerUnit[settlementCurrency];
  if (rate == null || settlementRate == null) return null;
  return amount * rate / settlementRate;
}

/// Aggregate total in [settlementCurrency], plus how many entries couldn't
/// be converted (missing FX rate) and were excluded rather than
/// mis-counted as zero.
class ConvertedTotal {
  const ConvertedTotal(this.amount, this.unconvertedCount);

  final double amount;
  final int unconvertedCount;
}

/// Sum of all entries for a counterparty, converted to [settlementCurrency].
/// Positive means they owe the user; negative would mean the user owes
/// them (shouldn't normally happen, but isn't disallowed).
ConvertedTotal runningBalance(
  Iterable<LedgerTransaction> transactions,
  Map<String, double> pricesUsdPerUnit, {
  String settlementCurrency = defaultCurrency,
}) {
  var total = 0.0;
  var unconverted = 0;
  for (final t in transactions) {
    final converted = convertToSettlement(
      t.amount,
      t.currency,
      pricesUsdPerUnit,
      settlementCurrency: settlementCurrency,
    );
    if (converted == null) {
      unconverted++;
    } else {
      total += converted;
    }
  }
  return ConvertedTotal(total, unconverted);
}

bool _isSameMonth(DateTime date, DateTime month) {
  return date.year == month.year && date.month == month.month;
}

/// Expense entries (positive amounts) for [month], grouped and summed by
/// category, converted to [settlementCurrency]. Repayments are excluded —
/// they reduce the balance but aren't part of "what was spent this month".
Map<String, double> monthlyCategoryTotals(
  Iterable<LedgerTransaction> transactions,
  DateTime month,
  Map<String, double> pricesUsdPerUnit, {
  String settlementCurrency = defaultCurrency,
}) {
  final totals = <String, double>{};
  for (final t in transactions) {
    if (t.amount <= 0 || !_isSameMonth(t.date, month)) continue;
    final converted = convertToSettlement(
      t.amount,
      t.currency,
      pricesUsdPerUnit,
      settlementCurrency: settlementCurrency,
    );
    if (converted == null) continue;
    totals[t.category] = (totals[t.category] ?? 0) + converted;
  }
  return totals;
}

double monthlyExpenseTotal(
  Iterable<LedgerTransaction> transactions,
  DateTime month,
  Map<String, double> pricesUsdPerUnit, {
  String settlementCurrency = defaultCurrency,
}) {
  return monthlyCategoryTotals(transactions, month, pricesUsdPerUnit, settlementCurrency: settlementCurrency)
      .values
      .fold(0.0, (a, b) => a + b);
}

/// One month's worth of spend, for charting a trend over time.
class MonthlySpend {
  const MonthlySpend(this.month, this.amount);

  /// First day of the month.
  final DateTime month;
  final double amount;
}

/// Expense totals for the last [months] calendar months (oldest first),
/// ending with the month containing [asOf] (defaults to now). Months with
/// no entries still appear with an amount of 0, so a chart's x-axis stays
/// evenly spaced.
List<MonthlySpend> monthlySpendTrend(
  Iterable<LedgerTransaction> transactions,
  Map<String, double> pricesUsdPerUnit, {
  int months = 6,
  DateTime? asOf,
  String settlementCurrency = defaultCurrency,
}) {
  final end = asOf ?? DateTime.now();
  final result = <MonthlySpend>[];
  for (var i = months - 1; i >= 0; i--) {
    final month = DateTime(end.year, end.month - i);
    final total = monthlyExpenseTotal(
      transactions,
      month,
      pricesUsdPerUnit,
      settlementCurrency: settlementCurrency,
    );
    result.add(MonthlySpend(month, total));
  }
  return result;
}

/// Expense entries (positive amounts), grouped and summed by category
/// across every transaction (not scoped to a single month), converted to
/// [settlementCurrency] — "what have we actually spent the most on."
Map<String, double> categoryTotalsAllTime(
  Iterable<LedgerTransaction> transactions,
  Map<String, double> pricesUsdPerUnit, {
  String settlementCurrency = defaultCurrency,
}) {
  final totals = <String, double>{};
  for (final t in transactions) {
    if (t.amount <= 0) continue;
    final converted = convertToSettlement(
      t.amount,
      t.currency,
      pricesUsdPerUnit,
      settlementCurrency: settlementCurrency,
    );
    if (converted == null) continue;
    totals[t.category] = (totals[t.category] ?? 0) + converted;
  }
  return totals;
}

double monthlyRepaymentTotal(
  Iterable<LedgerTransaction> transactions,
  DateTime month,
  Map<String, double> pricesUsdPerUnit, {
  String settlementCurrency = defaultCurrency,
}) {
  var total = 0.0;
  for (final t in transactions) {
    if (t.amount < 0 && _isSameMonth(t.date, month)) {
      final converted = convertToSettlement(
        -t.amount,
        t.currency,
        pricesUsdPerUnit,
        settlementCurrency: settlementCurrency,
      );
      if (converted != null) total += converted;
    }
  }
  return total;
}

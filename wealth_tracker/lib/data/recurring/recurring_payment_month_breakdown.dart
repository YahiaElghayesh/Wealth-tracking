import '../../core/models/recurring_payment_history_item.dart';
import '../db/database.dart';
import '../ledger/ledger_calculator.dart' show convertToSettlement;
import 'recurring_payment_due.dart';

/// One month's recurring-payments picture -- total, paid, and which
/// specific payments made up each -- computed the same way whether it's
/// the live current month (recurringPaymentsMonthSummaryProvider) or a
/// past one being recorded into history for good
/// (RecurringPaymentHistoryRepository.ensureRecorded), so those two never
/// drift out of sync with each other the way two separately hand-rolled
/// loops eventually would.
class RecurringPaymentsMonthBreakdown {
  const RecurringPaymentsMonthBreakdown({
    required this.total,
    required this.paid,
    required this.hasMinimums,
    required this.items,
  });

  final double total;
  final double paid;

  /// Whether at least one payment counted into [total] is a
  /// minimum-amount entry -- callers use this to label the total as an
  /// estimate rather than a hard figure.
  final bool hasMinimums;

  /// One entry per payment due this month, in the same order [payments]
  /// was given in.
  final List<RecurringPaymentHistoryItem> items;

  double get pending => total - paid;
}

/// [asOf] is evaluated as "the current month" for due-date/paid purposes --
/// pass today for the live picture, or a past month's last calendar day to
/// describe that month instead (see [recurringPaymentIsPaidForCurrentCycle]
/// and friends for exactly what "current cycle" means per frequency). An
/// entry whose currency has no known FX rate yet is skipped rather than
/// mis-counted as zero, same convention as [ledgersTotalProvider].
RecurringPaymentsMonthBreakdown computeRecurringPaymentsMonthBreakdown(
  List<RecurringPayment> payments,
  DateTime asOf,
  Map<String, double> pricesUsdPerUnit,
) {
  var total = 0.0;
  var paidTotal = 0.0;
  var hasMinimums = false;
  final items = <RecurringPaymentHistoryItem>[];
  for (final payment in payments) {
    if (!recurringPaymentIsDueThisMonth(payment, asOf)) continue;
    final converted = convertToSettlement(
      payment.amount,
      payment.currency,
      pricesUsdPerUnit,
    );
    if (converted == null) continue;
    total += converted;
    if (!payment.isExactAmount) hasMinimums = true;
    final isPaid = recurringPaymentIsPaidForCurrentCycle(payment, asOf);
    if (isPaid) paidTotal += converted;
    items.add(
      RecurringPaymentHistoryItem(
        name: payment.name,
        amount: converted,
        paid: isPaid,
      ),
    );
  }
  return RecurringPaymentsMonthBreakdown(
    total: total,
    paid: paidTotal,
    hasMinimums: hasMinimums,
    items: items,
  );
}

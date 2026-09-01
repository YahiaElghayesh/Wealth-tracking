import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../../data/recurring/recurring_payment_due.dart';
import '../../../data/repositories/recurring_payment_repository.dart';
import '../../networth/providers/asset_providers.dart'
    show pricesUsdPerUnitProvider, databaseProvider;
import '../../settings/providers/settings_providers.dart'
    show activeProfileIdProvider;

final recurringPaymentRepositoryProvider = Provider<RecurringPaymentRepository>(
  (ref) {
    return RecurringPaymentRepository(
      ref.watch(databaseProvider),
      ref.watch(activeProfileIdProvider),
    );
  },
);

final recurringPaymentsStreamProvider = StreamProvider<List<RecurringPayment>>((
  ref,
) {
  return ref.watch(recurringPaymentRepositoryProvider).watchAll();
});

/// This month's recurring-payments picture: what's due, what's already
/// been marked paid, and what's still pending -- see
/// recurring_payment_due.dart for what "due this month" and "paid" mean
/// per frequency. A minimum-amount entry is still counted at its own
/// stated floor, the best available estimate of the real bill without
/// knowing it in advance. An entry whose currency has no known FX rate yet
/// is skipped rather than mis-counted as zero, same convention as
/// [ledgersTotalProvider].
class RecurringPaymentsMonthSummary {
  const RecurringPaymentsMonthSummary({
    required this.total,
    required this.paid,
    required this.pending,
    required this.hasMinimums,
  });

  final double total;
  final double paid;
  final double pending;

  /// Whether at least one payment counted into [total] is a
  /// minimum-amount entry -- callers use this to label the total as an
  /// estimate rather than a hard figure.
  final bool hasMinimums;
}

final recurringPaymentsMonthSummaryProvider =
    Provider<RecurringPaymentsMonthSummary>((ref) {
      final payments =
          ref.watch(recurringPaymentsStreamProvider).valueOrNull ?? const [];
      final prices = ref.watch(pricesUsdPerUnitProvider);
      final today = DateTime.now();

      var total = 0.0;
      var paid = 0.0;
      var hasMinimums = false;
      for (final payment in payments) {
        if (!recurringPaymentIsDueThisMonth(payment, today)) continue;
        final converted = convertToSettlement(
          payment.amount,
          payment.currency,
          prices,
        );
        if (converted == null) continue;
        total += converted;
        if (!payment.isExactAmount) hasMinimums = true;
        if (recurringPaymentIsPaidForCurrentCycle(payment, today)) {
          paid += converted;
        }
      }
      return RecurringPaymentsMonthSummary(
        total: total,
        paid: paid,
        pending: total - paid,
        hasMinimums: hasMinimums,
      );
    });

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recurring_payment_history_item.dart';
import '../../../data/db/database.dart';
import '../../../data/recurring/recurring_payment_month_breakdown.dart';
import '../../../data/repositories/recurring_payment_history_repository.dart';
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
    required this.items,
  });

  final double total;
  final double paid;
  final double pending;

  /// Whether at least one payment counted into [total] is a
  /// minimum-amount entry -- callers use this to label the total as an
  /// estimate rather than a hard figure.
  final bool hasMinimums;

  /// Which specific payments make up [total]/[paid] this month -- lets a
  /// caller (the history screen's "in progress" current-month tile) show
  /// the same per-item breakdown a past, already-recorded month does.
  final List<RecurringPaymentHistoryItem> items;
}

final recurringPaymentsMonthSummaryProvider =
    Provider<RecurringPaymentsMonthSummary>((ref) {
      final payments =
          ref.watch(recurringPaymentsStreamProvider).valueOrNull ?? const [];
      final prices = ref.watch(pricesUsdPerUnitProvider);
      final breakdown = computeRecurringPaymentsMonthBreakdown(
        payments,
        DateTime.now(),
        prices,
      );
      return RecurringPaymentsMonthSummary(
        total: breakdown.total,
        paid: breakdown.paid,
        pending: breakdown.pending,
        hasMinimums: breakdown.hasMinimums,
        items: breakdown.items,
      );
    });

final recurringPaymentHistoryRepositoryProvider =
    Provider<RecurringPaymentHistoryRepository>((ref) {
      return RecurringPaymentHistoryRepository(
        ref.watch(databaseProvider),
        ref.watch(activeProfileIdProvider),
      );
    });

final recurringPaymentHistoryStreamProvider =
    StreamProvider<List<RecurringPaymentHistoryData>>((ref) {
      return ref.watch(recurringPaymentHistoryRepositoryProvider).watchAll();
    });

/// Fires (fire-and-forget) whenever this rebuilds with a real payments
/// list: if the calendar has moved past a month with no history record
/// yet, writes one -- see [RecurringPaymentHistoryRepository.ensureRecorded]
/// for why this can't just be computed live the way the current month's
/// total is. Watched from `RecurringPaymentsScreen`'s build, the same
/// "provider as a side-effect trigger" pattern `knownCardsSyncProvider`
/// and friends already use elsewhere in this app.
final recurringPaymentHistoryAutoRecordProvider = Provider<void>((ref) {
  final repository = ref.watch(recurringPaymentHistoryRepositoryProvider);
  final payments = ref.watch(recurringPaymentsStreamProvider).valueOrNull;
  final prices = ref.watch(pricesUsdPerUnitProvider);
  if (payments == null) return;
  unawaited(repository.ensureRecorded(payments, prices));
});

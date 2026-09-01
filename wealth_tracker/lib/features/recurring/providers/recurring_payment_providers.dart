import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
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

/// Sum of every recurring payment, converted to the app's settlement
/// currency -- a minimum-amount entry is still counted at its own stated
/// floor, the best available estimate of the monthly total without knowing
/// the real (possibly higher) bill in advance. An entry whose currency has
/// no known FX rate yet is skipped rather than mis-counted as zero, same
/// convention as [ledgersTotalProvider].
final recurringPaymentsTotalProvider = Provider<double>((ref) {
  final payments =
      ref.watch(recurringPaymentsStreamProvider).valueOrNull ?? const [];
  final prices = ref.watch(pricesUsdPerUnitProvider);
  var total = 0.0;
  for (final payment in payments) {
    final converted = convertToSettlement(
      payment.amount,
      payment.currency,
      prices,
    );
    if (converted != null) total += converted;
  }
  return total;
});

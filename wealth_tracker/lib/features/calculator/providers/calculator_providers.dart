import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../../data/repositories/calculator_repository.dart';
import '../../ledger/providers/ledger_providers.dart';
import '../../networth/providers/asset_providers.dart' show pricesUsdPerUnitProvider, databaseProvider;
import '../../settings/providers/settings_providers.dart' show activeProfileIdProvider;

final calculatorRepositoryProvider = Provider<CalculatorRepository>((ref) {
  return CalculatorRepository(ref.watch(databaseProvider), ref.watch(activeProfileIdProvider));
});

final creditCardsStreamProvider = StreamProvider<List<CreditCard>>((ref) {
  return ref.watch(calculatorRepositoryProvider).watchCards();
});

final manualInputsStreamProvider = StreamProvider<List<ManualInput>>((ref) {
  return ref.watch(calculatorRepositoryProvider).watchManualInputs();
});

final calculatorHistoryStreamProvider = StreamProvider<List<CalculatorSnapshot>>((ref) {
  return ref.watch(calculatorRepositoryProvider).watchSnapshots();
});

/// Sum of every *Calculator-included* ledger's balance, in the app's
/// default settlement currency — money owed to the user minus money the
/// user owes, combined across every counterparty that hasn't opted out via
/// its "Include in Calculator" flag.
final ledgersTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsStreamProvider).valueOrNull ?? const [];
  final counterparties = ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];
  final excludedIds = {for (final c in counterparties) if (!c.includeInCalculator) c.id};
  final included =
      excludedIds.isEmpty ? transactions : transactions.where((t) => !excludedIds.contains(t.counterpartyId)).toList();
  final prices = ref.watch(pricesUsdPerUnitProvider);
  return runningBalance(included, prices).amount;
});

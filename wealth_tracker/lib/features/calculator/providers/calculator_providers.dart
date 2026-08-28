import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/calculator_card.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../../data/repositories/calculator_repository.dart';
import '../../ledger/providers/ledger_providers.dart';
import '../../networth/providers/asset_providers.dart' show pricesUsdPerUnitProvider, databaseProvider;

final calculatorRepositoryProvider = Provider<CalculatorRepository>((ref) {
  return CalculatorRepository(ref.watch(databaseProvider));
});

final cardLimitsStreamProvider = StreamProvider<Map<CalculatorCard, double>>((ref) {
  return ref.watch(calculatorRepositoryProvider).watchCardLimits();
});

final calculatorHistoryStreamProvider = StreamProvider<List<CalculatorSnapshot>>((ref) {
  return ref.watch(calculatorRepositoryProvider).watchSnapshots();
});

/// Sum of every ledger's balance, in the app's default settlement currency —
/// money owed to the user minus money the user owes, combined across every
/// counterparty.
final ledgersTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsStreamProvider).valueOrNull ?? const [];
  final prices = ref.watch(pricesUsdPerUnitProvider);
  return runningBalance(transactions, prices).amount;
});

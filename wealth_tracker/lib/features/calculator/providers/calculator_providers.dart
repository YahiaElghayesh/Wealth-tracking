import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/calculator_input.dart';
import '../../../data/calculator/current_money_calculator.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../../data/repositories/calculator_repository.dart';
import '../../ledger/providers/ledger_providers.dart';
import '../../networth/providers/asset_providers.dart' show pricesUsdPerUnitProvider, databaseProvider;

final calculatorRepositoryProvider = Provider<CalculatorRepository>((ref) {
  return CalculatorRepository(ref.watch(databaseProvider));
});

final calculatorInputsStreamProvider = StreamProvider<Map<CalculatorInputKey, double>>((ref) {
  return ref.watch(calculatorRepositoryProvider).watchAll();
});

/// Sum of every ledger's balance, in the app's default settlement currency —
/// money owed to the user minus money the user owes, combined across every
/// counterparty.
final ledgersTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionsStreamProvider).valueOrNull ?? const [];
  final prices = ref.watch(pricesUsdPerUnitProvider);
  return runningBalance(transactions, prices).amount;
});

final currentMoneyProvider = Provider<double>((ref) {
  final ledgersTotal = ref.watch(ledgersTotalProvider);
  final inputs = ref.watch(calculatorInputsStreamProvider).valueOrNull ?? const {};
  return calculateCurrentMoney(ledgersTotal: ledgersTotal, inputs: inputs);
});

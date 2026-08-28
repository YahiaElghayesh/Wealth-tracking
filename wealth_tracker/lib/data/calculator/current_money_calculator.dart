import '../../core/models/calculator_input.dart';

/// Current liquid cash on hand, replicating the user's manual routine:
/// start from what all the ledgers net out to (money owed to them minus
/// money they owe others, summed across every counterparty), subtract the
/// apartment savings set aside and each credit card's current owed balance,
/// then add back the CIB account balance.
double calculateCurrentMoney({
  required double ledgersTotal,
  required Map<CalculatorInputKey, double> inputs,
}) {
  final apartmentSavings = inputs[CalculatorInputKey.apartmentSavings] ?? 0;
  final cibAccountBalance = inputs[CalculatorInputKey.cibAccountBalance] ?? 0;
  final cardsOwed = CalculatorInputKey.cards.fold(0.0, (sum, card) => sum + (inputs[card] ?? 0));

  return ledgersTotal - apartmentSavings - cardsOwed + cibAccountBalance;
}

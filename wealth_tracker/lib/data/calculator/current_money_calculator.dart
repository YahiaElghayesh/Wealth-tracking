import '../../core/models/calculator_card.dart';
import '../../core/models/calculator_custom_item.dart';

/// A card's current owed balance, derived from what the user actually
/// reads off their banking app — the balance still available to spend —
/// rather than an amount-owed figure they'd have to compute by hand.
double cardOwedAmount({required double limit, required double availableBalance}) {
  return limit - availableBalance;
}

/// Current liquid cash on hand, replicating the user's manual routine:
/// start from what all the ledgers net out to (money owed to them minus
/// money they owe others, summed across every counterparty), subtract the
/// apartment savings set aside and each credit card's owed balance, add
/// back the CIB account balance, then apply any custom +/- adjustments.
double calculateCurrentMoney({
  required double ledgersTotal,
  required double apartmentSavings,
  required double cibAccountBalance,
  required Map<CalculatorCard, double> cardOwed,
  List<CustomCalculatorItem> customItems = const [],
}) {
  final cardsOwedTotal = cardOwed.values.fold(0.0, (sum, owed) => sum + owed);
  final customTotal = customItems.fold(0.0, (sum, item) => sum + item.signedAmount);

  return ledgersTotal - apartmentSavings - cardsOwedTotal + cibAccountBalance + customTotal;
}

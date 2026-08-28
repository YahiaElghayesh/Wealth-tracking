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
///
/// [cardOwedAmounts] must already be converted to the same currency as
/// every other argument here — cards can be tracked in any currency, so
/// that conversion happens at the call site (same pattern the ledger uses),
/// not in this currency-agnostic pure function.
double calculateCurrentMoney({
  required double ledgersTotal,
  required double apartmentSavings,
  required double cibAccountBalance,
  required List<double> cardOwedAmounts,
  List<CustomCalculatorItem> customItems = const [],
}) {
  final cardsOwedTotal = cardOwedAmounts.fold(0.0, (sum, owed) => sum + owed);
  final customTotal = customItems.fold(0.0, (sum, item) => sum + item.signedAmount);

  return ledgersTotal - apartmentSavings - cardsOwedTotal + cibAccountBalance + customTotal;
}

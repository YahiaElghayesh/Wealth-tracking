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
///
/// [manualInputAmounts] are each already signed and converted by the caller
/// (same convention as [cardOwedAmounts]) -- e.g. apartment savings
/// (subtracted) comes in negative, a balance to add comes in positive.
///
/// [bankAccountAmounts] are each already converted (same convention as
/// [cardOwedAmounts]) and always added -- a bank account's available
/// balance is straightforwardly liquid cash, unlike a card (which has to
/// be turned into an owed figure via its limit first).
double calculateCurrentMoney({
  required double ledgersTotal,
  required List<double> cardOwedAmounts,
  required List<double> manualInputAmounts,
  List<double> bankAccountAmounts = const [],
  List<CustomCalculatorItem> customItems = const [],
}) {
  final cardsOwedTotal = cardOwedAmounts.fold(0.0, (sum, owed) => sum + owed);
  final manualInputsTotal = manualInputAmounts.fold(0.0, (sum, amt) => sum + amt);
  final bankAccountsTotal = bankAccountAmounts.fold(0.0, (sum, amt) => sum + amt);
  final customTotal = customItems.fold(0.0, (sum, item) => sum + item.signedAmount);

  return ledgersTotal - cardsOwedTotal + manualInputsTotal + bankAccountsTotal + customTotal;
}

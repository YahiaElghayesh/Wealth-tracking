import '../../data/ledger/ledger_calculator.dart' show convertToSettlement;
import '../models/currency.dart';

/// A value paired with its conversion into whichever of EGP/USD it isn't
/// -- [nativeAmount]/[nativeCurrency] is the currency the value is
/// actually denominated in (what it's "paid in"), always shown first/
/// bigger/prominent; [convertedAmount]/[convertedCurrency] is the
/// secondary figure, always shown second/smaller/neutral, prefixed with
/// "≈". [convertedAmount] is null when the FX rate isn't known yet.
class DualCurrencyAmounts {
  const DualCurrencyAmounts({
    required this.nativeCurrency,
    required this.nativeAmount,
    required this.convertedCurrency,
    required this.convertedAmount,
  });

  final String nativeCurrency;
  final double nativeAmount;
  final String convertedCurrency;
  final double? convertedAmount;
}

/// Pairs [nativeAmount] (denominated in [nativeCurrency]) with its
/// converted counterpart -- EGP when [nativeCurrency] is USD, USD
/// otherwise (covers EGP and any other supported currency alike, since
/// USD is this app's one universal cross-currency unit everywhere else:
/// asset values, ledger totals, recurring-payment totals).
DualCurrencyAmounts dualCurrencyAmounts({
  required String nativeCurrency,
  required double nativeAmount,
  required Map<String, double> pricesUsdPerUnit,
}) {
  final convertedCurrency = nativeCurrency == 'USD' ? defaultCurrency : 'USD';
  final converted = convertToSettlement(
    nativeAmount,
    nativeCurrency,
    pricesUsdPerUnit,
    settlementCurrency: convertedCurrency,
  );
  return DualCurrencyAmounts(
    nativeCurrency: nativeCurrency,
    nativeAmount: nativeAmount,
    convertedCurrency: convertedCurrency,
    convertedAmount: converted,
  );
}

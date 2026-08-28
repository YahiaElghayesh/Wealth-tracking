import 'package:intl/intl.dart';

final _usdFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _egpFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);
final _plainNumber = NumberFormat('#,##0.00');

String formatUsd(double value) => _usdFormat.format(value);

String formatEgp(double value) => _egpFormat.format(value);

/// Formats [value] with its ISO currency code (e.g. "1,234.56 SAR") — used
/// wherever the currency isn't fixed to USD/EGP, since intl's locale-based
/// symbols for SAR/AED/TRY aren't reliably unambiguous.
String formatMoney(double value, String currencyCode) {
  return '${_plainNumber.format(value)} $currencyCode';
}

import 'package:intl/intl.dart';

final _usdFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _egpFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);
final _usdFormatWhole = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
final _egpFormatWhole = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
final _plainNumber = NumberFormat('#,##0.00');

String formatUsd(double value) => _usdFormat.format(value);

String formatEgp(double value) => _egpFormat.format(value);

/// Whole-number forms (rounded, no cents) — used on the Net Worth page,
/// where a precise fraction of a currency unit adds noise without adding
/// information at the scale asset values are shown at.
String formatUsdWhole(double value) => _usdFormatWhole.format(value);

String formatEgpWhole(double value) => _egpFormatWhole.format(value);

/// Formats [value] with its ISO currency code (e.g. "1,234.56 SAR") — used
/// wherever the currency isn't fixed to USD/EGP, since intl's locale-based
/// symbols for SAR/AED/TRY aren't reliably unambiguous.
String formatMoney(double value, String currencyCode) {
  return '${_plainNumber.format(value)} $currencyCode';
}

/// K/M-abbreviated form for space-constrained spots (the home-screen
/// widget's liquid/non-liquid rows) — "E£1.25M" / "$103.4K" instead of the
/// full "EGP 1,250,000.00" / "$103,400.00", matching the mockup's `.wv`
/// pattern for those rows.
String _short(double value, String prefix) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 1000000) return '$sign$prefix${(abs / 1000000).toStringAsFixed(2)}M';
  if (abs >= 1000) return '$sign$prefix${(abs / 1000).toStringAsFixed(1)}K';
  return '$sign$prefix${abs.toStringAsFixed(0)}';
}

String formatShortEgp(double value) => _short(value, 'E£');

String formatShortUsd(double value) => _short(value, r'$');

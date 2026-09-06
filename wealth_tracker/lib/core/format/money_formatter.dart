import 'package:intl/intl.dart';

final _usdFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _egpFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);
final _usdFormatWhole = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
final _egpFormatWhole = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
final _plainNumber = NumberFormat('#,##0.00');
final _plainNumberWhole = NumberFormat('#,##0');

/// A whole number (e.g. 270.0) prints as "270", not "270.00" -- the ".00"
/// added nothing but visual noise, and stood out oddly next to a genuinely
/// fractional amount like "22.80" shown right above it. A value that
/// actually has a fraction still prints it in full either way; this only
/// ever suppresses an all-zero fractional part, never rounds one away.
bool _isWhole(double value) => value == value.roundToDouble();

String formatUsd(double value) =>
    (_isWhole(value) ? _usdFormatWhole : _usdFormat).format(value);

String formatEgp(double value) =>
    (_isWhole(value) ? _egpFormatWhole : _egpFormat).format(value);

/// Whole-number forms (always rounded, no cents even for a fractional
/// value) — used on the Net Worth page, where a precise fraction of a
/// currency unit adds noise without adding information at the scale asset
/// values are shown at. Distinct from [formatUsd]/[formatEgp] simply not
/// showing a fraction that isn't there -- these two always round.
String formatUsdWhole(double value) => _usdFormatWhole.format(value);

String formatEgpWhole(double value) => _egpFormatWhole.format(value);

/// Formats [value] with its ISO currency code (e.g. "1,234.56 SAR") — used
/// wherever the currency isn't fixed to USD/EGP, since intl's locale-based
/// symbols for SAR/AED/TRY aren't reliably unambiguous. Same ".00"
/// suppression as [formatUsd]/[formatEgp] for a value with no fraction.
String formatMoney(double value, String currencyCode) {
  final formatter = _isWhole(value) ? _plainNumberWhole : _plainNumber;
  return '${formatter.format(value)} $currencyCode';
}

/// Whole-number form for an arbitrary currency code -- [formatEgpWhole]/
/// [formatUsdWhole] for EGP/USD (their own symbol-based formatting), and
/// [formatMoney]'s plain "N CODE" form, rounded, for anything else. Used
/// wherever a value's currency isn't fixed ahead of time (e.g. an asset or
/// recurring payment shown in whichever currency it's actually
/// denominated in).
String formatCurrencyWhole(double value, String currencyCode) {
  switch (currencyCode) {
    case 'EGP':
      return formatEgpWhole(value);
    case 'USD':
      return formatUsdWhole(value);
    default:
      return '${value.round()} $currencyCode';
  }
}

/// Exact, unrounded counterpart to [formatCurrencyWhole] -- [formatEgp]/
/// [formatUsd]'s own symbol-based formatting for EGP/USD, [formatMoney]
/// for anything else. Recurring payments are entered to the cent (e.g.
/// "22.80"), so rounding that display down to "23" showed a different
/// number than what was actually typed in and saved.
String formatCurrencyExact(double value, String currencyCode) {
  switch (currencyCode) {
    case 'EGP':
      return formatEgp(value);
    case 'USD':
      return formatUsd(value);
    default:
      return formatMoney(value, currencyCode);
  }
}

/// K/M-abbreviated form for space-constrained spots (the home-screen
/// widget's liquid/non-liquid rows) — "E£1.25M" / "$103.4K" instead of the
/// full "EGP 1,250,000.00" / "$103,400.00", matching the mockup's `.wv`
/// pattern for those rows.
String _short(double value, String prefix) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 1000000)
    return '$sign$prefix${(abs / 1000000).toStringAsFixed(2)}M';
  if (abs >= 1000) return '$sign$prefix${(abs / 1000).toStringAsFixed(1)}K';
  return '$sign$prefix${abs.toStringAsFixed(0)}';
}

String formatShortEgp(double value) => _short(value, 'E£');

String formatShortUsd(double value) => _short(value, r'$');

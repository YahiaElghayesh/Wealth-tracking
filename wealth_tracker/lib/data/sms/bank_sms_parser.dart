/// A single card charge extracted from a bank SMS.
class ParsedBankSms {
  const ParsedBankSms({
    required this.vendor,
    required this.amount,
    required this.currency,
    required this.occurredAt,
  });

  final String vendor;

  /// Always a whole number — the user doesn't want fractional amounts from
  /// auto-captured entries, so this is rounded up from whatever the SMS
  /// actually said (e.g. 958.54 -> 959).
  final double amount;

  final String currency;
  final DateTime occurredAt;
}

/// Matches CIB's card-charge alert, e.g.:
/// "Your credit card ending with#4912 was charged for EGP 958.54 at
/// Breadfast on 27/08/26 at 13:30. Card available limit is EGP 85891.16.
/// For more details, please visit https://cib.eg/mb"
///
/// Other banks (e.g. NBE) use a different wording — this only recognizes
/// the CIB format until a sample of theirs is available to match against.
final _cibChargePattern = RegExp(
  r'charged for\s+([A-Za-z]{3})\s*([\d,]+(?:\.\d+)?)\s+at\s+(.+?)\s+on\s+'
  r'(\d{1,2})/(\d{1,2})/(\d{2,4})\s+at\s+(\d{1,2}):(\d{2})',
  caseSensitive: false,
);

/// Parses a bank SMS body into a card charge, or `null` if it doesn't match
/// any known bank format.
ParsedBankSms? parseBankSms(String body) {
  final match = _cibChargePattern.firstMatch(body);
  if (match == null) return null;

  final currency = match.group(1)!.toUpperCase();
  final amountStr = match.group(2)!.replaceAll(',', '');
  final amount = double.tryParse(amountStr);
  if (amount == null) return null;

  final vendor = match.group(3)!.trim();
  if (vendor.isEmpty) return null;

  final day = int.parse(match.group(4)!);
  final month = int.parse(match.group(5)!);
  var year = int.parse(match.group(6)!);
  if (year < 100) year += 2000;
  final hour = int.parse(match.group(7)!);
  final minute = int.parse(match.group(8)!);

  return ParsedBankSms(
    vendor: vendor,
    amount: amount.ceilToDouble(),
    currency: currency,
    occurredAt: DateTime(year, month, day, hour, minute),
  );
}

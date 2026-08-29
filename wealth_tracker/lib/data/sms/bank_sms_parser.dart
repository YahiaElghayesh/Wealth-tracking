/// A single card transaction extracted from a bank SMS — either a charge
/// (a purchase, reduces the card's available balance) or a credit (a
/// payment or refund, increases it).
class ParsedBankSms {
  const ParsedBankSms({
    required this.vendor,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.isCharge,
    this.lastFourDigits,
    this.availableBalanceAfter,
  });

  final String vendor;

  /// Always a whole number — the user doesn't want fractional amounts from
  /// auto-captured entries, so this is rounded up from whatever the SMS
  /// actually said (e.g. 958.54 -> 959).
  final double amount;

  final String currency;
  final DateTime occurredAt;

  /// true = a purchase/charge (subtracts from the card's available
  /// balance); false = a payment or refund credited to the card (adds to
  /// it).
  final bool isCharge;

  /// The last 4 digits printed on the card, when the SMS states them (e.g.
  /// "ending with#4912") — lets this be matched to a specific [CreditCard]
  /// for balance tracking. Null if the bank's wording doesn't include it.
  final String? lastFourDigits;

  /// The available-to-spend balance the bank states *after* this
  /// transaction (e.g. "Card available limit is EGP 85891.16"), when
  /// present — the most reliable way to update a tracked card balance,
  /// since it doesn't depend on knowing the balance beforehand. Null if the
  /// SMS doesn't state one, in which case the balance has to be derived by
  /// adding/subtracting [amount] from whatever was last known instead.
  final double? availableBalanceAfter;
}

/// One matcher for a specific bank's SMS wording. [isCharge] is fixed per
/// pattern since a bank's charge-alert and payment-alert templates always
/// differ in wording, not just in the numbers.
class _BankSmsPattern {
  const _BankSmsPattern(this.regex, {required this.isCharge});

  final RegExp regex;
  final bool isCharge;
}

/// Matches CIB's card-charge alert, e.g.:
/// "Your credit card ending with#4912 was charged for EGP 958.54 at
/// Breadfast on 27/08/26 at 13:30. Card available limit is EGP 85891.16.
/// For more details, please visit https://cib.eg/mb"
///
/// The available-limit portion is optional in the pattern itself (wrapped
/// in `(?:...)?`) so a charge SMS that's worded slightly differently still
/// parses the vendor/amount/date rather than failing outright — that field
/// just comes back null. The last-4-digits text ("ending with#4912") is
/// deliberately *not* woven into this sequential pattern — it sits before
/// "charged for" as an optional segment, and an optional group positioned
/// at the very start of a match only ever gets tried at the match's
/// starting offset; since skipping it doesn't cause the rest of the regex
/// to fail, the engine never backtracks to actually find it further into
/// the string. [_lastFourPattern] below extracts it independently instead.
final _cibChargePattern = _BankSmsPattern(
  RegExp(
    r'.*?'
    r'charged for\s+([A-Za-z]{3})\s*([\d,]+(?:\.\d+)?)\s+at\s+(.+?)\s+on\s+'
    r'(\d{1,2})/(\d{1,2})/(\d{2,4})\s+at\s+(\d{1,2}):(\d{2})'
    r'(?:.*?available limit is\s+([A-Za-z]{3})\s*([\d,]+(?:\.\d+)?))?',
    caseSensitive: false,
    dotAll: true,
  ),
  isCharge: true,
);

/// Every recognized bank format, tried in order — add a new bank or a new
/// message type (e.g. a payment/refund alert) here once a real sample of
/// its exact wording is available. Guessing at wording without one risks a
/// pattern that silently never matches the real thing.
final _patterns = [_cibChargePattern];

/// Extracts the card's last 4 digits from wording like "ending with#4912",
/// independently of whichever bank pattern matched — see the comment on
/// [_cibChargePattern] for why this can't just be another capture group in
/// the main sequential pattern.
final _lastFourPattern = RegExp(r'ending with#\s*(\d{4})', caseSensitive: false);

/// Parses a bank SMS body into a card transaction, or `null` if it doesn't
/// match any known bank format.
ParsedBankSms? parseBankSms(String body) {
  for (final pattern in _patterns) {
    final match = pattern.regex.firstMatch(body);
    if (match == null) continue;

    final currency = match.group(1)!.toUpperCase();
    final amountStr = match.group(2)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null) continue;

    final vendor = match.group(3)!.trim();
    if (vendor.isEmpty) continue;

    final day = int.parse(match.group(4)!);
    final month = int.parse(match.group(5)!);
    var year = int.parse(match.group(6)!);
    if (year < 100) year += 2000;
    final hour = int.parse(match.group(7)!);
    final minute = int.parse(match.group(8)!);

    final lastFour = _lastFourPattern.firstMatch(body)?.group(1);
    final availCurrency = match.group(9);
    final availAmountStr = match.group(10)?.replaceAll(',', '');
    final availAmount = availAmountStr == null ? null : double.tryParse(availAmountStr);
    // Only trust the stated balance when it's actually in the card's own
    // currency — mixing currencies here would silently corrupt a tracked
    // balance.
    final availableBalanceAfter = (availAmount != null && availCurrency?.toUpperCase() == currency)
        ? availAmount
        : null;

    return ParsedBankSms(
      vendor: vendor,
      amount: amount.ceilToDouble(),
      currency: currency,
      occurredAt: DateTime(year, month, day, hour, minute),
      isCharge: pattern.isCharge,
      lastFourDigits: lastFour,
      availableBalanceAfter: availableBalanceAfter,
    );
  }
  return null;
}

/// Strips invisible Unicode bidi/formatting characters banks commonly
/// embed in Arabic SMS text to control how a Western-digit number (an
/// amount, a card's last-4-digits) displays inside right-to-left prose —
/// RLM/LRM marks, explicit embedding/override/isolate direction controls,
/// and zero-width joiners -- none of which `\s` matches in either Dart's
/// or Kotlin's regex engine, so one sitting between two pieces every
/// pattern below expects adjacent (e.g. "رد" and "EGP", or "بـ#" and
/// "4912") would silently break the match with no visible sign why, since
/// these characters render as nothing at all. Also folds a non-breaking
/// space to a plain one and Arabic-Indic digits (٠-٩) to Western ones, for
/// the same reason -- a locale-driven rendering choice, not a per-bank
/// format difference, so this normalization applies uniformly before any
/// pattern below ever runs rather than needing to be baked into each one.
String _normalizeSmsBody(String body) {
  // U+200B-U+200F: zero-width space/non-joiner/joiner, LTR mark, RTL mark.
  // U+202A-U+202E: explicit embedding/override direction controls.
  // U+2066-U+2069: explicit isolate direction controls.
  // U+061C: Arabic letter mark.
  final withoutBidiMarks = body.replaceAll(
    RegExp('[\u200B-\u200F\u202A-\u202E\u2066-\u2069\u061C]'),
    '',
  );
  final withNormalSpaces = withoutBidiMarks.replaceAll(' ', ' ');
  const arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';
  const extendedArabicIndicDigits = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in withNormalSpaces.runes) {
    final char = String.fromCharCode(rune);
    final arabicIndex = arabicIndicDigits.indexOf(char);
    final extendedIndex = extendedArabicIndicDigits.indexOf(char);
    if (arabicIndex != -1) {
      buffer.write(arabicIndex);
    } else if (extendedIndex != -1) {
      buffer.write(extendedIndex);
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

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
    this.availableBalanceCurrency,
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

  /// The currency [availableBalanceAfter] is denominated in — usually the
  /// same as [currency] (a EGP purchase reported against a EGP balance),
  /// but not always: NBE's alerts state the available balance in EGP even
  /// for a foreign-currency purchase (a card billed in EGP that was simply
  /// used abroad), so this is tracked separately rather than assumed equal
  /// to [currency]. Null when [availableBalanceAfter] is null, or (for
  /// callers built before this field existed) when the bank format didn't
  /// distinguish the two — treated as equal to [currency] in that case.
  final String? availableBalanceCurrency;
}

/// One matcher for a specific bank's SMS wording, paired with the function
/// that turns a match into a [ParsedBankSms] — a plain regex isn't enough
/// on its own because different banks number their capture groups
/// completely differently (CIB states day/month/year and an
/// optionally-present available-limit at the end; NBE states month/day
/// with no year and an always-present available balance in a fixed
/// currency), so each pattern owns its own extraction logic instead of the
/// parsing loop assuming one shared group layout.
class _BankSmsPattern {
  const _BankSmsPattern(this.regex, this.extract);

  final RegExp regex;
  final ParsedBankSms? Function(RegExpMatch match, String body) extract;
}

/// Extracts the card's last 4 digits from wording like "ending with#4912"
/// or the shorter "card #4912" / "card#4912" (a second, real CIB charge
/// wording -- "Your credit card #4912 was charged for USD 1.00 at
/// DIGITALOCEAN.CO..." -- that says just as much but without "ending
/// with"), independently of whichever bank pattern matched — CIB's charge
/// alert puts this before "charged for" as an optional segment, and an
/// optional group positioned at the very start of a match only ever gets
/// tried at the match's starting offset; since skipping it doesn't cause
/// the rest of the regex to fail, the engine never backtracks to actually
/// find it further into the string. So this is extracted independently
/// instead. Without the shorter form, a real charge with this wording
/// still parsed (vendor/amount/date all came through) but with a null
/// last-four, which [updateCardBalanceFromSms] treats as "no card to
/// update" and silently no-ops on -- the reported "charge notification
/// never updates the tracked balance" bug.
final _cibLastFourPattern = RegExp(
  r'card\s*(?:ending with)?\s*#\s*(\d{4})',
  caseSensitive: false,
);

/// Matches CIB's card-charge alert, e.g.:
/// "Your credit card ending with#4912 was charged for EGP 958.54 at
/// Breadfast on 27/08/26 at 13:30. Card available limit is EGP 85891.16.
/// For more details, please visit https://cib.eg/mb"
///
/// The available-limit portion is optional in the pattern itself (wrapped
/// in `(?:...)?`) so a charge SMS that's worded slightly differently still
/// parses the vendor/amount/date rather than failing outright — that field
/// just comes back null.
final _cibChargePattern = _BankSmsPattern(
  RegExp(
    r'.*?'
    r'charged for\s+([A-Za-z]{3})\s*([\d,]+(?:\.\d+)?)\s+at\s+(.+?)\s+on\s+'
    r'(\d{1,2})/(\d{1,2})/(\d{2,4})\s+at\s+(\d{1,2}):(\d{2})'
    r'(?:.*?available limit is\s+([A-Za-z]{3})\s*([\d,]+(?:\.\d+)?))?',
    caseSensitive: false,
    dotAll: true,
  ),
  (match, body) {
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

    final lastFour = _cibLastFourPattern.firstMatch(body)?.group(1);
    final availCurrency = match.group(9);
    final availAmountStr = match.group(10)?.replaceAll(',', '');
    final availAmount = availAmountStr == null
        ? null
        : double.tryParse(availAmountStr);
    // Only trust the stated balance when it's actually in the same
    // currency as the charge — mixing currencies here would silently
    // corrupt a tracked balance.
    final availableBalanceAfter =
        (availAmount != null && availCurrency?.toUpperCase() == currency)
        ? availAmount
        : null;

    return ParsedBankSms(
      vendor: vendor,
      amount: amount.ceilToDouble(),
      currency: currency,
      occurredAt: DateTime(year, month, day, hour, minute),
      isCharge: true,
      lastFourDigits: lastFour,
      availableBalanceAfter: availableBalanceAfter,
      availableBalanceCurrency: availableBalanceAfter == null ? null : currency,
    );
  },
);

/// Matches NBE's Arabic card-charge alert, e.g.:
/// "تم خصم USD 84.44 من بطاقة الائتمان رقم 8455 عند HODJAPASHA CULT يوم
/// 08-26 الساعة 22:27 المتاح 491269.64 جم والمتبقي من حد الاستخدام الشهري
/// بالعملة الأجنبية بما يعادل 154722.75 جم للمزيد اتصل ب 19623."
///
/// The date is month-day with no year (assumed to be the current year,
/// rolled back one if that would put it in the future — e.g. a
/// late-December SMS parsed the following January). Unlike CIB, the
/// "المتاح" (available) figure is always in EGP regardless of the charge's
/// own currency, since NBE cards are billed in EGP even when used abroad
/// — captured via [ParsedBankSms.availableBalanceCurrency] rather than
/// assumed to match [ParsedBankSms.currency].
final _nbeChargePattern = _BankSmsPattern(
  RegExp(
    r'تم\s*خصم\s*([A-Za-z]{3})\s*([\d,]+(?:\.\d+)?)\s*من\s*بطاقة\s*الائتمان\s*رقم\s*(\d{4})\s*'
    r'عند\s*(.+?)\s*يوم\s*(\d{1,2})-(\d{1,2})\s*الساعة\s*(\d{1,2}):(\d{2})\s*المتاح\s*([\d,]+(?:\.\d+)?)\s*جم',
    dotAll: true,
  ),
  (match, body) {
    final currency = match.group(1)!.toUpperCase();
    final amountStr = match.group(2)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null) return null;

    final lastFour = match.group(3);
    final vendor = match.group(4)!.trim();
    if (vendor.isEmpty) return null;

    final month = int.parse(match.group(5)!);
    final day = int.parse(match.group(6)!);
    final hour = int.parse(match.group(7)!);
    final minute = int.parse(match.group(8)!);

    final now = DateTime.now();
    var occurredAt = DateTime(now.year, month, day, hour, minute);
    if (occurredAt.isAfter(now.add(const Duration(days: 1)))) {
      occurredAt = DateTime(now.year - 1, month, day, hour, minute);
    }

    final availAmountStr = match.group(9)!.replaceAll(',', '');
    final availAmount = double.tryParse(availAmountStr);

    return ParsedBankSms(
      vendor: vendor,
      amount: amount.ceilToDouble(),
      currency: currency,
      occurredAt: occurredAt,
      isCharge: true,
      lastFourDigits: lastFour,
      availableBalanceAfter: availAmount,
      availableBalanceCurrency: availAmount == null ? null : 'EGP',
    );
  },
);

/// Matches CIB's Arabic card-*payment* alert (settling/paying down the
/// card, the opposite of a charge), e.g.:
/// "نشكركم على سداد مبلغ 8860.36 جم لبطاقة رقم 8455 يوم 28/08"
/// ("Thank you for paying 8860.36 EGP toward card number 8455 on 28/08.")
///
/// Neither an available-balance figure nor a year is ever stated in this
/// format, unlike the charge alert -- the year uses the same "assume
/// current, roll back if that would be in the future" logic as
/// [_nbeChargePattern]. [ParsedBankSms.amount] is deliberately NOT rounded
/// up the way a charge's is: that rounding exists so an auto-captured
/// *ledger entry* doesn't carry an ugly fraction, but a payment alert never
/// becomes a ledger entry (see [parseBankSms] callers) -- it only ever
/// feeds the card balance's fallback add-the-amount math, where rounding
/// up would silently overstate the real balance.
final _cibPaymentPattern = _BankSmsPattern(
  RegExp(
    r'نشكركم\s*على\s*سداد\s*مبلغ\s*([\d,]+(?:\.\d+)?)\s*جم\s*لبطاقة\s*رقم\s*(\d{4})\s*يوم\s*(\d{1,2})/(\d{1,2})',
    dotAll: true,
  ),
  (match, body) {
    final amountStr = match.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null) return null;

    final lastFour = match.group(2);
    final day = int.parse(match.group(3)!);
    final month = int.parse(match.group(4)!);

    final now = DateTime.now();
    var occurredAt = DateTime(now.year, month, day);
    if (occurredAt.isAfter(now.add(const Duration(days: 1)))) {
      occurredAt = DateTime(now.year - 1, month, day);
    }

    return ParsedBankSms(
      vendor: 'Card payment',
      amount: amount,
      currency: 'EGP',
      occurredAt: occurredAt,
      isCharge: false,
      lastFourDigits: lastFour,
    );
  },
);

/// Matches NBE's Arabic card-*payment* alert, e.g.:
/// "تم سداد مبلغ 100000.00 جم فى بطاقتكم الائتمانية المنتهية بـ 4912
/// بتاريخ 21-08-26"
/// ("100000.00 EGP has been paid into your credit card ending with 4912
/// on 21-08-26.")
///
/// Unlike [_nbeChargePattern]'s two-segment month-day date, this states a
/// full day-month-year date and no time -- occurredAt is set to midnight
/// on that date. No available-balance figure is stated either, so (like
/// [_cibPaymentPattern]) this only feeds the card balance's fallback
/// add-the-amount math, hence the same un-rounded [amount].
final _nbePaymentPattern = _BankSmsPattern(
  RegExp(
    r'تم\s*سداد\s*مبلغ\s*([\d,]+(?:\.\d+)?)\s*جم\s*فى\s*بطاقتكم\s*الائتمانية\s*المنتهية\s*بـ\s*(\d{4})\s*'
    r'بتاريخ\s*(\d{1,2})-(\d{1,2})-(\d{2,4})',
    dotAll: true,
  ),
  (match, body) {
    final amountStr = match.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null) return null;

    final lastFour = match.group(2);
    final day = int.parse(match.group(3)!);
    final month = int.parse(match.group(4)!);
    var year = int.parse(match.group(5)!);
    if (year < 100) year += 2000;

    return ParsedBankSms(
      vendor: 'Card payment',
      amount: amount,
      currency: 'EGP',
      occurredAt: DateTime(year, month, day),
      isCharge: false,
      lastFourDigits: lastFour,
    );
  },
);

/// Matches this Arabic *refund* alert wording (money returned to the card,
/// e.g. a refunded online order) -- distinct from a payment/settlement, and
/// the SMS itself says so explicitly (this amount doesn't count toward the
/// month's minimum due, only the available balance), e.g.:
/// "لقد تم رد EGP1500.00 على بطاقتكم الائتمانية المنتهية بـ# 4912 من Amazon
/// Marketplace. يرجى ملاحظة أن هذا المبلغ سيتم إضافته إلى رصيد بطاقتك ولا
/// يتم اعتباره بمثابة دفعة للمديونيات المستحقة لهذا الشهر."
///
/// Originally logged as NBE's wording from an earlier sample, but a later
/// real sample of the identical text was confirmed sent by CIB -- so this
/// wording isn't exclusive to one bank, and the pattern is (deliberately)
/// not named or gated on either. Nothing in this file ever checks which
/// bank sent a message: a pattern matches purely on the text itself, and
/// [updateCardBalanceFromSms] matches the resulting last-4-digits against
/// every registered card regardless of that card's own (user-typed, purely
/// informational) "Bank" field. A new real sample should be added here by
/// what it says, not by which bank is assumed to have sent it.
///
/// No date is stated anywhere in this format, unlike every other pattern
/// here -- occurredAt falls back to the moment this SMS is processed. Like
/// a payment alert, the amount is NOT rounded up (never becomes a ledger
/// entry, only feeds the card balance's fallback add-the-amount math).
final _arabicRefundPattern = _BankSmsPattern(
  RegExp(
    r'تم\s*رد\s*([A-Za-z]{3})\s*([\d,]+(?:\.\d+)?)\s*على\s*بطاقتكم\s*الائتمانية\s*المنتهية\s*بـ#?\s*(\d{4})',
    dotAll: true,
  ),
  (match, body) {
    final currency = match.group(1)!.toUpperCase();
    final amountStr = match.group(2)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null) return null;

    final lastFour = match.group(3);

    return ParsedBankSms(
      vendor: 'Card refund',
      amount: amount,
      currency: currency,
      occurredAt: DateTime.now(),
      isCharge: false,
      lastFourDigits: lastFour,
    );
  },
);

/// Matches CIB's *English* card-refund alert, e.g.:
/// "The transaction on your credit card#4912 from DIGITALOCEAN.CO with
/// USD 1.00 on 02/09/26 at 14:52 has been refunded. Please try again.
/// Thank you"
///
/// A different wording from [_arabicRefundPattern] for the same kind of
/// event -- money returned to the card -- and, unlike that one, this
/// English format states the vendor, currency, amount, date and time
/// explicitly (the same information [_cibChargePattern]'s charge alert
/// states), all captured here the same way. Like every other
/// payment/refund alert, the amount is NOT rounded up (never becomes a
/// ledger entry, only feeds the card balance's fallback add-the-amount
/// math).
final _cibEnglishRefundPattern = _BankSmsPattern(
  RegExp(
    r'transaction on your credit\s*card\s*#?\s*(\d{4})\s+from\s+(.+?)\s+with\s+'
    r'([A-Za-z]{3})\s*([\d,]+(?:\.\d+)?)\s+on\s+(\d{1,2})/(\d{1,2})/(\d{2,4})'
    r'\s+at\s+(\d{1,2}):(\d{2})\s+has\s*been\s*refunded',
    caseSensitive: false,
    dotAll: true,
  ),
  (match, body) {
    final lastFour = match.group(1);
    final vendor = match.group(2)!.trim();
    if (vendor.isEmpty) return null;

    final currency = match.group(3)!.toUpperCase();
    final amountStr = match.group(4)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null) return null;

    final day = int.parse(match.group(5)!);
    final month = int.parse(match.group(6)!);
    var year = int.parse(match.group(7)!);
    if (year < 100) year += 2000;
    final hour = int.parse(match.group(8)!);
    final minute = int.parse(match.group(9)!);

    return ParsedBankSms(
      vendor: vendor,
      amount: amount,
      currency: currency,
      occurredAt: DateTime(year, month, day, hour, minute),
      isCharge: false,
      lastFourDigits: lastFour,
    );
  },
);

/// Every recognized bank format, tried in order — add a new bank or a new
/// message type (e.g. a payment/refund alert) here once a real sample of
/// its exact wording is available. Guessing at wording without one risks a
/// pattern that silently never matches the real thing.
final _patterns = [
  _cibChargePattern,
  _cibPaymentPattern,
  _cibEnglishRefundPattern,
  _nbeChargePattern,
  _nbePaymentPattern,
  _arabicRefundPattern,
];

/// Parses a bank SMS body into a card transaction, or `null` if it doesn't
/// match any known bank format. [body] is run through [_normalizeSmsBody]
/// first -- see its doc comment for why a raw, unnormalized SMS can defeat
/// every pattern here despite looking identical to a human reader.
ParsedBankSms? parseBankSms(String body) {
  final normalized = _normalizeSmsBody(body);
  for (final pattern in _patterns) {
    final match = pattern.regex.firstMatch(normalized);
    if (match == null) continue;
    final parsed = pattern.extract(match, normalized);
    if (parsed != null) return parsed;
  }
  return null;
}

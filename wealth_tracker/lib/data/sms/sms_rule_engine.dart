import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/format/money_formatter.dart';
import '../../core/models/currency.dart';
import '../../core/models/sms_rule_segment.dart';
import '../../core/models/supplementary_card_numbers.dart';
import '../db/database.dart';
import '../ledger/ledger_calculator.dart' show convertToSettlement;

/// Strips invisible Unicode bidi/formatting characters banks commonly
/// embed in Arabic SMS text around numbers, and folds a non-breaking space
/// to a plain one and Arabic-Indic digits (٠-٩) to Western ones -- the
/// same normalization the app's old hardwired parser applied, since none
/// of it is a per-bank format difference, just a locale-driven rendering
/// choice that would otherwise silently break matching with no visible
/// sign why (these characters render as nothing at all).
///
/// Applied uniformly to both a rule's own sample text (once, right after
/// it's pasted, before any marking happens -- so marked offsets are never
/// invalidated by characters this strips) and to every real incoming SMS
/// before matching.
String normalizeSmsBody(String body) {
  final withoutBidiMarks = body.replaceAll(
    RegExp('[\u200B-\u200F\u202A-\u202E\u2066-\u2069\u061C]'),
    '',
  );
  final withNormalSpaces = withoutBidiMarks.replaceAll('\u00A0', ' ');
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

/// Escapes a literal segment's text for use inside the compiled pattern,
/// while still tolerating variable amounts of whitespace the way the
/// app's old hardwired patterns did -- a run of whitespace in the sample
/// becomes `\s+` rather than a literal match on that exact run, since a
/// real SMS can wrap or space itself slightly differently. Whitespace at
/// the very start/end of the literal text is preserved as `\s+` too, not
/// trimmed away -- trimming it would let a bare word like "at" match
/// *inside* an adjacent vendor name that merely contains "at" as a
/// substring, instead of requiring the standalone word the sample had.
String _escapeLiteral(String text) {
  if (text.isEmpty) return '';
  return text.splitMapJoin(
    RegExp(r'\s+'),
    onMatch: (_) => r'\s+',
    onNonMatch: (nonWs) => RegExp.escape(nonWs),
  );
}

/// How many words of a literal segment 'flexible' mode keeps as an anchor
/// on each side before wildcarding the rest -- see [_escapeLiteralFlexible].
const _flexibleEdgeWords = 2;

/// 'flexible'-mode counterpart to [_escapeLiteral]: a short literal segment
/// (at most [_flexibleEdgeWords] * 2 words) is kept exactly as-is, same as
/// strict mode, since shortening it further would leave nothing to anchor
/// the match at all. A longer one keeps only its first and last
/// [_flexibleEdgeWords] words -- the part most likely to be fixed bank
/// wording right next to a tag -- and replaces everything between them
/// with a `.*?` gap, tolerating a merchant name, a date, or an extra
/// clause a single sample can never fully predict. Leading/trailing
/// whitespace is preserved as `\s+` exactly like strict mode either way.
String _escapeLiteralFlexible(String text) {
  final parts = RegExp(r'^(\s*)(.*?)(\s*)$', dotAll: true).firstMatch(text)!;
  final leading = parts.group(1)!;
  final core = parts.group(2)!;
  final trailing = parts.group(3)!;
  if (core.isEmpty) return _escapeLiteral(text);

  final words = core.split(RegExp(r'\s+'));
  final leadPattern = leading.isEmpty ? '' : r'\s+';
  final trailPattern = trailing.isEmpty ? '' : r'\s+';
  if (words.length <= _flexibleEdgeWords * 2) {
    return '$leadPattern${_escapeLiteral(core)}$trailPattern';
  }

  final head = words.take(_flexibleEdgeWords).join(' ');
  final tail = words.skip(words.length - _flexibleEdgeWords).join(' ');
  return '$leadPattern${_escapeLiteral(head)}.*?${_escapeLiteral(tail)}$trailPattern';
}

/// Builds one capture-group pattern for a placeholder segment. A
/// card/account number is a plain digit run; a value (or a
/// `transactionValue`, notification-only -- see [SmsRuleSegment]'s own doc
/// comment) tolerates thousands separators and a decimal point; a currency
/// is a short run of Latin or Arabic letters or a common symbol (an ISO
/// code like "EGP", an Arabic word like "جنيه", or a symbol like "$") --
/// see [_resolveCurrencyToken] for how each of those is actually
/// recognized; a vendor/sender name, or an `ignore` tag (a date, time, or
/// reference number the user marked as "this varies, don't require it to
/// match"), is free text, captured non-greedily so it stops at the next
/// literal segment rather than swallowing it (or greedily if this is the
/// very last segment, with nothing after it to stop at).
String _placeholderPattern(SmsRuleSegment segment, bool isLast) {
  switch (segment.tag) {
    case 'cardNumber':
      return r'(\d+)';
    case 'value':
    case 'transactionValue':
      return r'([\d,]+(?:\.\d+)?)';
    case 'currency':
    case 'transactionCurrency':
      return '([A-Za-z\u0600-\u06FF\$€₺]{1,12})';
    default: // vendor, sender, ignore
      return isLast ? r'(.+)' : r'(.+?)';
  }
}

/// Common symbols or Arabic words banks use in place of an ISO code,
/// mapped to whichever [supportedCurrencies] entry they mean -- an ISO
/// code captured directly (e.g. "EGP", "USD") already matches one of
/// those verbatim (case-insensitively) and needs no lookup here. Lookup
/// keys are matched case-insensitively for the Latin symbol/word case too
/// (see _resolveCurrencyToken), but Arabic script has no case to fold.
const _currencyAliases = {
  r'$': 'USD',
  '€': 'EUR', // €
  '₺': 'TRY', // ₺
  'جنيه': 'EGP', // جنيه (junayh, Egyptian pound)
  'جم': 'EGP', // جم (the abbreviation CIB/NBE alerts use)
  'دولار': 'USD', // دولار (dollar)
  'يورو': 'EUR', // يورو (euro)
  'ريال': 'SAR', // ريال (riyal)
  'درهم': 'AED', // درهم (dirham)
  'ليرة': 'TRY', // ليرة (lira)
};

/// Resolves whatever a `currency` placeholder actually captured -- an ISO
/// code in English, an Arabic currency word, or a symbol -- to one of
/// [supportedCurrencies], or null if it's not recognized. The caller then
/// falls back to the rule's own default currency (for a ledger-payment
/// rule) or leaves the value unconverted (for a balance rule, when it
/// already matches the card's/account's own currency) -- same as when no
/// `currency` tag was marked at all.
String? _resolveCurrencyToken(String raw) {
  final token = raw.trim();
  final upper = token.toUpperCase();
  if (supportedCurrencies.contains(upper)) return upper;
  return _currencyAliases[token];
}

/// Compiles a rule's marked-up sample into a matcher -- alternating fixed
/// literal text and numbered capture groups for each placeholder, in the
/// same order they appear in [segments]. [flexible] selects which literal
/// escaper is used ([_escapeLiteral] for 'strict' mode, [_escapeLiteralFlexible]
/// for 'flexible') -- see [SmsRule.matchMode].
RegExp compileSmsRulePattern(
  List<SmsRuleSegment> segments, {
  bool flexible = false,
}) {
  final buffer = StringBuffer();
  for (var i = 0; i < segments.length; i++) {
    final segment = segments[i];
    if (segment.isLiteral) {
      buffer.write(
        flexible
            ? _escapeLiteralFlexible(segment.text)
            : _escapeLiteral(segment.text),
      );
    } else {
      buffer.write(_placeholderPattern(segment, i == segments.length - 1));
    }
  }
  return RegExp(buffer.toString(), caseSensitive: false, dotAll: true);
}

List<SmsRuleSegment> decodeSmsRuleSegments(String segmentsJson) {
  final decoded = jsonDecode(segmentsJson);
  if (decoded is! List) return const [];
  return decoded
      .cast<Map<String, dynamic>>()
      .map(SmsRuleSegment.fromJson)
      .toList();
}

String encodeSmsRuleSegments(List<SmsRuleSegment> segments) {
  return jsonEncode(segments.map((s) => s.toJson()).toList());
}

/// What a real SMS's matched, tagged portions actually said -- extracted
/// by [matchSmsRule], consumed by [applySmsRule]. Any field a rule didn't
/// mark a portion for is simply null; whether that's fine or fatal for a
/// given [SmsRule.operation] is [applySmsRule]'s call, not this one's.
class SmsRuleMatch {
  const SmsRuleMatch({
    this.cardNumber,
    this.value,
    this.valueRole,
    this.vendor,
    this.sender,
    this.currency,
    this.transactionValue,
    this.transactionValueRole,
    this.transactionCurrency,
  });

  final String? cardNumber;
  final double? value;

  /// 'set' | 'add' | 'subtract' for a balance rule, 'charge' | 'repayment'
  /// for a ledger-payment rule -- copied straight from whichever [value]
  /// placeholder segment supplied [value].
  final String? valueRole;
  final String? vendor;
  final String? sender;

  /// Resolved from a `currency` placeholder, if the rule marked one and it
  /// was recognized -- one of [supportedCurrencies], or null if there was
  /// no `currency` tag or its capture wasn't recognized. For a
  /// 'ledgerPayment' rule this picks which currency the entry is recorded
  /// in; for a balance rule it's compared against the card's/account's own
  /// currency to decide whether [applySmsRule] needs to convert first.
  final String? currency;

  /// From a `transactionValue` placeholder (balance rules only) -- see
  /// [SmsRuleSegment]'s own doc comment. Never fed into the balance math;
  /// only [applySmsRule]'s notification text uses it, alongside
  /// [transactionValueRole] ('add' | 'subtract', which sign to show it
  /// with).
  final double? transactionValue;
  final String? transactionValueRole;

  /// Resolved from a `transactionCurrency` placeholder -- a second,
  /// independent currency capture just for [transactionValue], for a
  /// message where the transaction itself was in a different currency than
  /// the balance figure [value]/[currency] describe (e.g. an EGP card
  /// charged for a USD purchase, which still reports its EGP available
  /// limit in the same text). Falls back to [currency] when the rule
  /// didn't mark a separate one -- same single-currency behavior as
  /// before this tag existed.
  final String? transactionCurrency;
}

/// One literal requirement of a rule that either doesn't appear in a real
/// message at all, or only appears earlier than it's allowed to (out of
/// order relative to an earlier requirement that already claimed that
/// part of the message) -- see [findUnsatisfiedRequirements].
class UnsatisfiedRequirement {
  const UnsatisfiedRequirement(this.description);
  final String description;
}

/// Every literal requirement of [rule] that [rawBody] doesn't actually
/// satisfy, checked in the same left-to-right order the rule itself
/// requires them in -- each search starts from wherever the previous
/// requirement's match ended, so a requirement that only exists
/// *earlier* in the message than that (out of the order the rule needs)
/// is caught too, not just one that's missing outright. Anything between
/// two requirements -- a card/account number, a value, a vendor name, or
/// an `ignore`-tagged portion -- is treated as an unconstrained gap here,
/// since checking a placeholder's own character class against a specific
/// position would reintroduce exactly the kind of position-dependent,
/// hard-to-reason-about check this function exists to avoid.
///
/// This replaces an earlier approach that tried to walk [rule]'s combined
/// pattern incrementally to find "the first segment that stops matching":
/// that depended on where a free-form vendor/sender/`ignore` tag's own
/// backtracking happened to land while only part of the pattern was
/// being tested, which turned out to produce a misleading answer --
/// flagging a real, correctly-tagged portion as the problem, past which
/// its own greedy/non-greedy behavior isn't even well-defined in
/// isolation. Checking each requirement's own position, independent of
/// any tag's capture behavior, sidesteps that.
///
/// A 'flexible' rule's long literal is checked as its two anchor phrases
/// separately, matching what [compileSmsRulePattern] actually requires
/// of it (see [_escapeLiteralFlexible]) rather than the full raw
/// wording -- flexible mode never actually requires the whole sentence,
/// only those two anchors, so reporting the whole thing as unsatisfied
/// would overstate what's really missing. Only meaningful to call after
/// [matchSmsRule] has already returned null for the same rule/body.
List<UnsatisfiedRequirement> findUnsatisfiedRequirements(
  SmsRule rule,
  String rawBody,
) {
  final segments = decodeSmsRuleSegments(rule.segmentsJson);
  final flexible = rule.matchMode == 'flexible';
  final body = normalizeSmsBody(rawBody);
  final results = <UnsatisfiedRequirement>[];
  var cursor = 0;

  void check(String requirement, String description) {
    if (requirement.trim().isEmpty) return;
    final pattern = RegExp(
      _escapeLiteral(requirement),
      caseSensitive: false,
      dotAll: true,
    );
    RegExpMatch? match;
    for (final m in pattern.allMatches(body, cursor)) {
      match = m;
      break;
    }
    if (match != null) {
      cursor = match.end;
      return;
    }
    final existsEarlier = pattern.hasMatch(body);
    results.add(
      UnsatisfiedRequirement(
        existsEarlier
            ? '$description -- appears, but earlier in the message than '
                  "this rule's other requirements allow (out of order)"
            : description,
      ),
    );
  }

  for (final segment in segments) {
    if (segment.isPlaceholder) continue;
    final text = segment.text;
    if (text.trim().isEmpty) continue;
    if (!flexible) {
      check(text, '"$text"');
      continue;
    }
    final core = RegExp(
      r'^\s*(.*?)\s*$',
      dotAll: true,
    ).firstMatch(text)!.group(1)!;
    if (core.isEmpty) continue;
    final words = core.split(RegExp(r'\s+'));
    if (words.length <= _flexibleEdgeWords * 2) {
      check(text, '"$text"');
      continue;
    }
    final head = words.take(_flexibleEdgeWords).join(' ');
    final tail = words.skip(words.length - _flexibleEdgeWords).join(' ');
    check(head, '"$head" (near the start of one part)');
    check(tail, '"$tail" (near the end of one part)');
  }
  return results;
}

/// Tries [rule]'s compiled pattern against [rawBody] (normalized first,
/// same as the sample it was built from), returning the extracted,
/// tagged portions on a match or `null` otherwise.
SmsRuleMatch? matchSmsRule(SmsRule rule, String rawBody) {
  final segments = decodeSmsRuleSegments(rule.segmentsJson);
  if (segments.isEmpty) return null;
  final pattern = compileSmsRulePattern(
    segments,
    flexible: rule.matchMode == 'flexible',
  );
  final body = normalizeSmsBody(rawBody);
  final match = pattern.firstMatch(body);
  if (match == null) return null;

  String? cardNumber;
  double? value;
  String? valueRole;
  String? vendor;
  String? sender;
  String? currency;
  double? transactionValue;
  String? transactionValueRole;
  String? transactionCurrency;
  var groupIndex = 1;
  for (final segment in segments) {
    if (!segment.isPlaceholder) continue;
    final captured = match.group(groupIndex);
    groupIndex++;
    if (captured == null) continue;
    switch (segment.tag) {
      case 'cardNumber':
        cardNumber = captured.trim();
      case 'value':
        value = double.tryParse(captured.replaceAll(',', '').trim());
        valueRole = segment.role;
      case 'vendor':
        vendor = captured.trim();
      case 'sender':
        sender = captured.trim();
      case 'currency':
        currency = _resolveCurrencyToken(captured);
      case 'transactionValue':
        transactionValue = double.tryParse(captured.replaceAll(',', '').trim());
        transactionValueRole = segment.role;
      case 'transactionCurrency':
        transactionCurrency = _resolveCurrencyToken(captured);
    }
  }
  return SmsRuleMatch(
    cardNumber: cardNumber,
    value: value,
    valueRole: valueRole,
    vendor: vendor,
    sender: sender,
    currency: currency,
    transactionValue: transactionValue,
    transactionValueRole: transactionValueRole,
    transactionCurrency: transactionCurrency,
  );
}

/// The result of [applySmsRule] -- [applied] tells the caller (and tests)
/// whether anything actually happened; the two notification fields are
/// only ever set alongside `applied: true`, and only when [SmsRule.
/// notifyOnMatch] is on, for the caller to hand to a local notification.
class SmsRuleApplyOutcome {
  const SmsRuleApplyOutcome({
    required this.applied,
    this.notificationTitle,
    this.notificationBody,
  });

  final bool applied;
  final String? notificationTitle;
  final String? notificationBody;
}

const _noop = SmsRuleApplyOutcome(applied: false);

/// Applies one already-matched rule to the database -- updating a credit
/// card's or bank account's tracked balance, or adding a ledger entry --
/// per [rule.operation]. Every path below searches across *every*
/// profile's cards/accounts, not just whichever is active, mirroring the
/// app's old cross-profile SMS balance-update behavior: a card on a
/// profile that isn't active right now should still get its SMS-driven
/// updates.
Future<SmsRuleApplyOutcome> applySmsRule(
  AppDatabase db,
  SmsRule rule,
  SmsRuleMatch match,
) {
  switch (rule.operation) {
    case 'creditCardBalance':
      return _applyCreditCardBalance(db, rule, match);
    case 'bankAccountBalance':
      return _applyBankAccountBalance(db, rule, match);
    case 'ledgerPayment':
      return _applyLedgerPayment(db, rule, match);
    default:
      return Future.value(_noop);
  }
}

Future<String?> _bankName(AppDatabase db, String bankId) async {
  final bank = await (db.select(
    db.banks,
  )..where((b) => b.id.equals(bankId))).getSingleOrNull();
  return bank?.name;
}

double _resolveNewValue(double current, double delta, String? role) {
  return switch (role) {
    'add' => current + delta,
    'subtract' => current - delta,
    _ => delta, // 'set', or a match with no explicit role
  };
}

/// The matched value itself, signed and with its currency -- e.g.
/// "+250.00 EGP" for an 'add', "-250.00 EGP" for a 'subtract'. A 'set'
/// role has no meaningful +/- (the message set the balance directly, it
/// didn't add or subtract from it), so that case, and any role-less
/// match, is shown unsigned.
String _signedValueText(double value, String? role, String currency) {
  return switch (role) {
    'add' => '+${formatMoney(value, currency)}',
    'subtract' => '-${formatMoney(value, currency)}',
    _ => formatMoney(value, currency),
  };
}

/// A balance-update notification's body -- shared by [_applyCreditCardBalance]
/// and [_applyBankAccountBalance]. [transactionValue] (shown in
/// [transactionValueCurrency] -- whatever the rule's own `transactionCurrency`
/// tag captured, or its `currency` tag if there's no separate one, never
/// converted -- see `transactionValue`'s own doc comment on [SmsRuleSegment]
/// for why it's display-only) takes priority when the rule tagged one: it's
/// what the notification shows signed, regardless of what [matchedValue]/[valueRole]
/// actually did to the balance, and regardless of what currency the balance
/// itself is tracked in -- a card billed in EGP can still be charged in USD,
/// and the notification should say so rather than silently relabeling (or
/// converting) that amount into the card's own currency. Without one, a
/// 'set' role shows just the new balance rather than repeating that exact
/// same number as if it were also a signed delta -- what [matchedValue]
/// holds *is* the new balance for a 'set', not an amount that was added or
/// subtracted, so showing "45,623.09 — now 45,623.09" said nothing twice
/// for no reason.
String _balanceUpdateNotificationBody({
  required String entityName,
  required double newBalance,
  required String currency,
  required double matchedValue,
  required String? valueRole,
  required double? transactionValue,
  required String? transactionValueRole,
  required String transactionValueCurrency,
}) {
  final nowText = '$entityName is now ${formatMoney(newBalance, currency)}.';
  if (transactionValue != null) {
    return '${_signedValueText(transactionValue, transactionValueRole, transactionValueCurrency)} — $nowText';
  }
  if (valueRole == 'set') return nowText;
  return '${_signedValueText(matchedValue, valueRole, currency)} — $nowText';
}

/// Converts [value] from [matchedCurrency] (what a `currency` tag actually
/// captured off the real SMS, if any) into [targetCurrency] (the card's/
/// account's own tracked currency) using the app's cached FX rates -- the
/// same `priceCache` table and conversion formula the ledger already uses
/// for a mixed-currency running balance. Returns null, meaning "don't
/// apply this", rather than guessing, when a conversion was actually
/// needed but a rate for either side isn't cached yet -- applying an
/// un-converted number as if it were already in [targetCurrency] would
/// silently corrupt the tracked balance, which is worse than skipping one
/// update until a rate is available.
Future<double?> _resolveMatchedValue(
  AppDatabase db,
  double value,
  String? matchedCurrency,
  String targetCurrency,
) async {
  if (matchedCurrency == null ||
      matchedCurrency.toUpperCase() == targetCurrency.toUpperCase()) {
    return value;
  }
  final rows = await db.select(db.priceCache).get();
  final ratesUsd = {for (final r in rows) r.symbol: r.priceUsd};
  return convertToSettlement(
    value,
    matchedCurrency,
    ratesUsd,
    settlementCurrency: targetCurrency,
  );
}

Future<SmsRuleApplyOutcome> _applyCreditCardBalance(
  AppDatabase db,
  SmsRule rule,
  SmsRuleMatch match,
) async {
  final cardNumber = match.cardNumber;
  final value = match.value;
  if (cardNumber == null || value == null) return _noop;

  final bankName = await _bankName(db, rule.bankId);
  final cards = await db.select(db.creditCards).get();
  CreditCard? card;
  for (final c in cards) {
    // Every supplementary card number is checked here too, not treated as
    // a card of its own -- each shares this card's limit and balance
    // outright, so an SMS naming any one of them should update the very
    // same row.
    final matchesNumber =
        (c.lastFourDigits != null && cardNumber.endsWith(c.lastFourDigits!)) ||
        decodeSupplementaryLastFour(
          c.supplementaryLastFourDigits,
        ).any(cardNumber.endsWith);
    if (!matchesNumber) continue;
    if (bankName != null && c.bank.toLowerCase() != bankName.toLowerCase()) {
      continue;
    }
    card = c;
    break;
  }
  if (card == null) return _noop;

  final convertedValue = await _resolveMatchedValue(
    db,
    value,
    match.currency,
    card.currency,
  );
  if (convertedValue == null) return _noop;

  final current = card.currentAvailableBalance ?? card.limitAmount;
  final newBalance = _resolveNewValue(current, convertedValue, match.valueRole);

  await db
      .update(db.creditCards)
      .replace(
        card.copyWith(
          currentAvailableBalance: Value(newBalance),
          balanceUpdatedAt: Value(DateTime.now()),
          balanceUpdatedSource: const Value('sms'),
        ),
      );

  return SmsRuleApplyOutcome(
    applied: true,
    notificationTitle: '${card.name} balance updated',
    notificationBody: _balanceUpdateNotificationBody(
      entityName: card.name,
      newBalance: newBalance,
      currency: card.currency,
      matchedValue: convertedValue,
      valueRole: match.valueRole,
      transactionValue: match.transactionValue,
      transactionValueRole: match.transactionValueRole,
      transactionValueCurrency:
          match.transactionCurrency ?? match.currency ?? card.currency,
    ),
  );
}

Future<SmsRuleApplyOutcome> _applyBankAccountBalance(
  AppDatabase db,
  SmsRule rule,
  SmsRuleMatch match,
) async {
  final accountNumber = match.cardNumber;
  final value = match.value;
  if (accountNumber == null || value == null) return _noop;

  final bankName = await _bankName(db, rule.bankId);
  final accounts = await db.select(db.bankAccounts).get();
  BankAccount? account;
  for (final a in accounts) {
    final number = a.accountNumber;
    if (number == null || !accountNumber.endsWith(number)) continue;
    if (bankName != null && a.bank.toLowerCase() != bankName.toLowerCase()) {
      continue;
    }
    account = a;
    break;
  }
  if (account == null) return _noop;

  final convertedValue = await _resolveMatchedValue(
    db,
    value,
    match.currency,
    account.currency,
  );
  if (convertedValue == null) return _noop;

  final current = account.currentAvailableBalance ?? 0;
  final newBalance = _resolveNewValue(current, convertedValue, match.valueRole);

  await db
      .update(db.bankAccounts)
      .replace(
        account.copyWith(
          currentAvailableBalance: Value(newBalance),
          balanceUpdatedAt: Value(DateTime.now()),
          balanceUpdatedSource: const Value('sms'),
        ),
      );

  return SmsRuleApplyOutcome(
    applied: true,
    notificationTitle: '${account.name} balance updated',
    notificationBody: _balanceUpdateNotificationBody(
      entityName: account.name,
      newBalance: newBalance,
      currency: account.currency,
      matchedValue: convertedValue,
      valueRole: match.valueRole,
      transactionValue: match.transactionValue,
      transactionValueRole: match.transactionValueRole,
      transactionValueCurrency:
          match.transactionCurrency ?? match.currency ?? account.currency,
    ),
  );
}

Future<SmsRuleApplyOutcome> _applyLedgerPayment(
  AppDatabase db,
  SmsRule rule,
  SmsRuleMatch match,
) async {
  final targetId = rule.targetCounterpartyId;
  final value = match.value;
  if (targetId == null || value == null) return _noop;

  final counterparty = await (db.select(
    db.counterparties,
  )..where((c) => c.id.equals(targetId))).getSingleOrNull();
  if (counterparty == null) return _noop;

  final isRepayment = match.valueRole == 'repayment';
  final signedAmount = isRepayment ? -value : value;
  final vendor = match.vendor?.trim();
  final category = (vendor != null && vendor.isNotEmpty) ? vendor : 'Other';
  final currency = match.currency ?? rule.currency ?? defaultCurrency;

  await db
      .into(db.ledgerTransactions)
      .insert(
        LedgerTransactionsCompanion.insert(
          id: const Uuid().v4(),
          counterpartyId: targetId,
          date: DateTime.now(),
          amount: signedAmount,
          currency: Value(currency),
          category: category,
          createdAt: DateTime.now(),
          profileId: Value(counterparty.profileId ?? defaultProfileId),
          source: const Value('sms'),
        ),
      );

  return SmsRuleApplyOutcome(
    applied: true,
    notificationTitle: 'Added to ${counterparty.name}',
    notificationBody:
        '${isRepayment ? '-' : '+'}${formatMoney(value, currency)} — from a recent SMS.',
  );
}

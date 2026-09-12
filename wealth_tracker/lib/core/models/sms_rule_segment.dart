/// One piece of an [SmsRule]'s marked-up sample text, in order -- either
/// fixed text the rule requires a real SMS to contain, or a portion the
/// user marked and tagged as something to extract. [text] is always the
/// substring from the original sample this segment covers (for a literal
/// segment, the exact text to match; for a placeholder, what was marked
/// there) -- concatenating every segment's [text] in order reconstructs
/// the sample exactly, which is what lets the SMS Rules screen redraw a
/// saved rule's tagged spans when editing it, since offsets alone aren't
/// stored anywhere.
///
/// [tag] is one of 'cardNumber', 'value', 'vendor', 'sender', 'currency',
/// 'ignore', 'transactionValue', or 'transactionCurrency' -- only set when
/// [type] is 'placeholder'. 'ignore' is the tag for a portion that isn't
/// any of the others but still changes message to message -- a date, a
/// time, a reference number -- so it needs to be marked as *something* to
/// keep the rule from requiring that exact value forever; its match is
/// discarded rather than fed into [SmsRuleMatch] the way every other tag's
/// is. 'transactionValue' (balance rules only) is similar but its match
/// *is* kept, purely to show in the balance-update notification -- unlike
/// 'value', it never affects the balance math itself, for a rule whose
/// 'value' is something else entirely (e.g. a card's new available limit
/// rather than what was actually charged). 'transactionCurrency' is a
/// second, independent 'currency' just for 'transactionValue', for a
/// message where the transaction was in a different currency than the
/// balance figure itself (e.g. an EGP card charged for a USD purchase) --
/// without one, 'transactionValue' is shown in whatever 'currency' tag the
/// rule captured instead. [role] only applies to a 'value' placeholder:
/// 'set' | 'add' | 'subtract' for a 'creditCardBalance' or
/// 'bankAccountBalance' rule, 'charge' | 'repayment' for a 'ledgerPayment'
/// rule -- or a 'transactionValue' placeholder: 'add' | 'subtract', purely
/// which sign the notification shows it with.
class SmsRuleSegment {
  const SmsRuleSegment.literal(this.text)
    : type = 'literal',
      tag = null,
      role = null;

  const SmsRuleSegment.placeholder({
    required this.text,
    required this.tag,
    this.role,
  }) : type = 'placeholder';

  final String type;
  final String text;
  final String? tag;
  final String? role;

  bool get isLiteral => type == 'literal';
  bool get isPlaceholder => type == 'placeholder';

  Map<String, dynamic> toJson() => {
    'type': type,
    'text': text,
    if (tag != null) 'tag': tag,
    if (role != null) 'role': role,
  };

  static SmsRuleSegment fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final text = json['text'] as String;
    if (type == 'literal') {
      return SmsRuleSegment.literal(text);
    }
    return SmsRuleSegment.placeholder(
      text: text,
      tag: json['tag'] as String,
      role: json['role'] as String?,
    );
  }
}

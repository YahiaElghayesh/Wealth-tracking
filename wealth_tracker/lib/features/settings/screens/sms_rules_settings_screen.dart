import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../core/models/sms_rule_segment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/currency_picker_field.dart';
import '../../../data/db/database.dart';
import '../../../data/sms/sms_rule_engine.dart';
import '../../ledger/providers/ledger_providers.dart';
import '../providers/sms_rule_providers.dart';
import 'banks_settings_screen.dart';
import 'sms_test_screen.dart';

/// The Unicode "first strong character" rule -- the same one browsers and
/// the phone's own SMS app use to pick a paragraph's base direction when
/// none is set explicitly. Needed because this screen's ambient
/// `Directionality` is LTR (an English-language settings screen), which
/// would otherwise misalign and visually reorder an Arabic-dominant real
/// bank SMS compared to how it renders in the SMS app itself -- making it
/// hard to tell what a drag-select is actually about to capture, especially
/// for a Latin/English substring (a vendor name, an amount) sitting inside
/// the Arabic. Scans for the first character that is strongly one
/// direction or the other; a message with no such character (pure digits/
/// punctuation) falls back to LTR.
TextDirection _detectSampleDirection(String text) {
  for (final rune in text.runes) {
    final isRtl =
        (rune >= 0x0590 && rune <= 0x05FF) || // Hebrew
        (rune >= 0x0600 && rune <= 0x06FF) || // Arabic
        (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
        (rune >= 0x08A0 && rune <= 0x08FF) || // Arabic Extended-A
        (rune >= 0xFB50 && rune <= 0xFDFF) || // Arabic Presentation Forms-A
        (rune >= 0xFE70 && rune <= 0xFEFF); // Arabic Presentation Forms-B
    if (isRtl) return TextDirection.rtl;
    final isLtrLetter =
        (rune >= 0x0041 && rune <= 0x005A) || // A-Z
        (rune >= 0x0061 && rune <= 0x007A) || // a-z
        (rune >= 0x00C0 && rune <= 0x02AF); // Latin-1 Supplement / Extended
    if (isLtrLetter) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}

const _operations = [
  ('creditCardBalance', 'Credit card balance'),
  ('bankAccountBalance', 'Bank account balance'),
  ('ledgerPayment', 'Ledger payment'),
];

String _operationLabel(String operation) => _operations
    .firstWhere((o) => o.$1 == operation, orElse: () => (operation, operation))
    .$2;

const _tagColors = {
  'cardNumber': Color(0x334C6EF5),
  'value': Color(0x3312B886),
  'vendor': Color(0x33F59F00),
  'sender': Color(0x33AE3EC9),
  'currency': Color(0x33FA5252),
  'ignore': Color(0x33868E96),
  'transactionValue': Color(0x33845EF7),
  'transactionCurrency': Color(0x33E64980),
};

const _tagLabels = {
  'cardNumber': 'Card/account number',
  'value': 'Value',
  'vendor': 'Vendor name',
  'sender': 'Sender name',
  'currency': 'Currency',
  'ignore': 'Varies (date, time, ref #...)',
  'transactionValue': 'Transaction amount (notification only)',
  'transactionCurrency': "Transaction amount's own currency",
};

const _balanceRoles = [
  ('set', 'Set to this'),
  ('add', 'Add to current'),
  ('subtract', 'Subtract from current'),
];
const _ledgerRoles = [
  ('charge', 'Charge (they owe more)'),
  ('repayment', 'Repayment (they owe less)'),
];

/// [SmsRuleSegment.role] options for a 'transactionValue' tag -- purely
/// which sign the balance-update notification shows next to it (see
/// `sms_rule_engine.dart`'s `_signedValueText`), never fed into
/// `_resolveNewValue`: this tag exists so a rule can say "the card was
/// charged 978.00" in its notification even when the actual `value` tag
/// it applies is something unrelated, like "Set to this" against the
/// card's *available limit* rather than the charge amount itself.
const _transactionValueRoles = [
  ('add', '+ Increased balance'),
  ('subtract', '− Decreased balance'),
];

String _roleLabel(String operation, String tag, String? role) {
  final options = tag == 'transactionValue'
      ? _transactionValueRoles
      : operation == 'ledgerPayment'
      ? _ledgerRoles
      : _balanceRoles;
  return options.firstWhere((o) => o.$1 == role, orElse: () => ('', '')).$2;
}

/// Replaces the app's old hardwired per-bank SMS parsing -- every rule here
/// is built from a real sample SMS the user pastes and marks up themselves
/// (see `sms_rule_engine.dart`), grouped by bank.
class SmsRulesSettingsScreen extends ConsumerWidget {
  const SmsRulesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(smsRulesStreamProvider);
    final banksAsync = ref.watch(banksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Test an SMS',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SmsTestScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_outlined),
            tooltip: 'Manage banks',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BanksSettingsScreen()),
            ),
          ),
        ],
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (rules) {
          final banks = banksAsync.valueOrNull ?? const [];
          if (banks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add a bank first, in Settings -> Banks, before building a rule for it.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BanksSettingsScreen(),
                        ),
                      ),
                      child: const Text('Add a bank'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (rules.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No rules yet. Tap + to build one from a real bank text.',
                ),
              ),
            );
          }
          final byBank = <String, List<SmsRule>>{};
          for (final rule in rules) {
            byBank.putIfAbsent(rule.bankId, () => []).add(rule);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final bank in banks)
                if (byBank[bank.id]?.isNotEmpty ?? false)
                  _BankRulesSection(bank: bank, rules: byBank[bank.id]!),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SmsRuleFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BankRulesSection extends StatefulWidget {
  const _BankRulesSection({required this.bank, required this.rules});

  final Bank bank;
  final List<SmsRule> rules;

  @override
  State<_BankRulesSection> createState() => _BankRulesSectionState();
}

class _BankRulesSectionState extends State<_BankRulesSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(widget.bank.name),
            subtitle: Text(
              '${widget.rules.length} rule${widget.rules.length == 1 ? '' : 's'}',
            ),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            for (final rule in widget.rules)
              Consumer(
                builder: (context, ref, _) => Dismissible(
                  key: ValueKey(rule.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete),
                  ),
                  onDismissed: (_) =>
                      ref.read(smsRuleRepositoryProvider).delete(rule.id),
                  child: ListTile(
                    leading: const Icon(Icons.rule_outlined),
                    title: Text(
                      (rule.name?.trim().isNotEmpty ?? false)
                          ? rule.name!
                          : _operationLabel(rule.operation),
                    ),
                    subtitle: Text(
                      '${(rule.name?.trim().isNotEmpty ?? false) ? '${_operationLabel(rule.operation)} · ' : ''}'
                      '${rule.enabled ? (rule.notifyOnMatch ? 'Notifies on match' : 'Silent') : 'Disabled'}'
                      ' · ${rule.matchMode == 'flexible' ? 'Flexible' : 'Strict'}',
                      style: TextStyle(color: context.appColors.textDim),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: rule.enabled,
                          onChanged: (v) => ref
                              .read(smsRuleRepositoryProvider)
                              .updateRule(rule.copyWith(enabled: v)),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SmsRuleFormScreen(existing: rule),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _TaggedSpan {
  _TaggedSpan({
    required this.start,
    required this.end,
    required this.tag,
    this.role,
  });
  int start;
  int end;
  String tag;
  String? role;
}

/// Add or edit one SMS Rule -- pick a bank and an operation, paste a real
/// sample SMS, then mark and tag the portions that vary from one real
/// message to the next (a card/account number, a value, a vendor/sender
/// name, or a currency -- tagging currency lets one rule cover payments or
/// balances in more than one currency instead of needing a rule per
/// currency; for a balance rule specifically, a mismatched currency is
/// converted using the app's cached FX rates before it's applied).
/// Everything left unmarked becomes fixed text the rule requires a real
/// SMS to contain, unless matching is set to Flexible, which only holds a
/// couple of words next to each tag to that standard and lets everything
/// else vary.
class SmsRuleFormScreen extends ConsumerStatefulWidget {
  const SmsRuleFormScreen({super.key, this.existing});

  final SmsRule? existing;

  @override
  ConsumerState<SmsRuleFormScreen> createState() => _SmsRuleFormScreenState();
}

class _SmsRuleFormScreenState extends ConsumerState<SmsRuleFormScreen> {
  late final TextEditingController _sampleController;
  late final TextEditingController _nameController;
  String? _bankId;
  String _operation = 'creditCardBalance';
  String? _targetCounterpartyId;
  String _currency = defaultCurrency;
  bool _notifyOnMatch = false;
  String _matchMode = 'strict';
  final List<_TaggedSpan> _tags = [];

  /// The sample text as of the last time [_tags]' start/end offsets were
  /// known to line up with it -- compared against on every keystroke in
  /// [_onSampleTextChanged] to catch the moment they stop lining up. Any
  /// edit to the text once a tag already exists shifts everything after
  /// the edit point, silently pointing every later tag at the wrong
  /// characters (or, if the edit shortened the text, past the end of it
  /// entirely -- a `RangeError` the moment anything tries to slice a
  /// stale tag out of the now-shorter string).
  String _lastKnownSampleText = '';

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _sampleController = TextEditingController(text: existing?.sampleText ?? '');
    _nameController = TextEditingController(text: existing?.name ?? '');
    if (existing != null) {
      _bankId = existing.bankId;
      _operation = existing.operation;
      _targetCounterpartyId = existing.targetCounterpartyId;
      _currency = existing.currency ?? defaultCurrency;
      _notifyOnMatch = existing.notifyOnMatch;
      _matchMode = existing.matchMode;
      var cursor = 0;
      for (final segment in decodeSmsRuleSegments(existing.segmentsJson)) {
        final len = segment.text.length;
        if (segment.isPlaceholder) {
          _tags.add(
            _TaggedSpan(
              start: cursor,
              end: cursor + len,
              tag: segment.tag!,
              role: segment.role,
            ),
          );
        }
        cursor += len;
      }
    }
    _lastKnownSampleText = _sampleController.text;
    _sampleController.addListener(_onSampleTextChanged);
  }

  /// Keeps the pasted sample normalized the same way a real incoming SMS
  /// is at match time ([normalizeSmsBody], sms_rule_engine.dart) -- before
  /// this existed, a sample pasted with its original invisible bidi marks/
  /// non-breaking spaces/Arabic-Indic digits still intact would compile a
  /// literal pattern containing those exact characters, which then could
  /// never match a real SMS (normalized before matching, so those
  /// characters are already gone from it) in *either* strict or flexible
  /// mode -- the reported "this SMS fails to register no matter what I
  /// choose" bug. Only runs while [_tags] is still empty: every tag's
  /// start/end offset is computed once, by walking the saved segments in
  /// [initState], and stays valid only as long as the text they index into
  /// never changes again -- rewriting it out from under an existing tag
  /// (a loaded rule, or one just tagged this session) would silently
  /// desync every offset after that point, misslicing every tag after the
  /// edit point (or throwing a `RangeError` outright once a tag's `end`
  /// no longer fits inside the shortened text). Once a tag exists, any
  /// further edit to the sample just clears every tag instead of letting
  /// that happen silently, forcing a clean retag against text that's
  /// actually still in sync with them.
  void _onSampleTextChanged() {
    if (_tags.isEmpty) {
      final normalized = normalizeSmsBody(_sampleController.text);
      if (normalized != _sampleController.text) {
        _sampleController.value = TextEditingValue(
          text: normalized,
          selection: TextSelection.collapsed(offset: normalized.length),
        );
        return; // The assignment above re-enters this listener to finish.
      }
      _lastKnownSampleText = _sampleController.text;
      setState(() {});
      return;
    }
    if (_sampleController.text != _lastKnownSampleText) {
      _lastKnownSampleText = _sampleController.text;
      _tags.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "The sample text changed, so every tag's position was reset "
            '-- please retag.',
          ),
        ),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _sampleController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Inserts the clipboard's text at the current cursor position (replacing
  /// the selection, if any) -- an explicit button doing exactly what the
  /// system long-press "Paste" would, for a device/keyboard where that
  /// menu doesn't reliably show up over this field.
  Future<void> _pasteSample() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    final oldText = _sampleController.text;
    final selection = _sampleController.selection;
    final start = selection.isValid
        ? selection.start.clamp(0, oldText.length)
        : oldText.length;
    final end = selection.isValid
        ? selection.end.clamp(0, oldText.length)
        : oldText.length;
    _sampleController.value = TextEditingValue(
      text: oldText.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  Future<void> _copySample() async {
    final text = _sampleController.text;
    if (text.isEmpty) return;
    final selection = _sampleController.selection;
    final toCopy = selection.isValid && !selection.isCollapsed
        ? text.substring(selection.start, selection.end)
        : text;
    await Clipboard.setData(ClipboardData(text: toCopy));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied')));
  }

  List<String> get _availableTags => switch (_operation) {
    // Vendor/sender/currency aren't used by a balance update itself (only
    // cardNumber/value are), but they're still offered here so a merchant
    // name or a differently-currencied transaction sitting in the sample
    // can be tagged instead of left as required literal text -- otherwise
    // the rule would only ever match that one merchant/currency again.
    // 'ignore' is offered for every operation for the same reason, for
    // whatever else in the sample isn't any of the others but still
    // changes message to message -- a date, a time, a reference number.
    // 'transactionValue' is balance-rule-only: a "Set to this" rule's own
    // `value` tag is often something like the card's new available limit,
    // not the amount actually charged/paid -- this lets the notification
    // still say what the transaction itself was for, without feeding that
    // number into the balance math at all. 'transactionCurrency' is the
    // same idea applied to currency: only needed when the transaction
    // itself was in a different currency than the balance figure `value`/
    // `currency` describe (e.g. an EGP card charged for a USD purchase).
    'creditCardBalance' || 'bankAccountBalance' => const [
      'cardNumber',
      'value',
      'vendor',
      'sender',
      'currency',
      'ignore',
      'transactionValue',
      'transactionCurrency',
    ],
    _ => const ['value', 'vendor', 'sender', 'currency', 'ignore'],
  };

  Future<void> _tagSelection() async {
    final selection = _sampleController.selection;
    if (selection.isCollapsed || selection.start < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a portion of the text first')),
      );
      return;
    }
    final overlaps = _tags.any(
      (t) => selection.start < t.end && t.start < selection.end,
    );
    if (overlaps) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That overlaps a portion already tagged')),
      );
      return;
    }

    // How far the boundary can be nudged in [_TagPickerDialog] without
    // running into a neighboring tag -- the nearest existing tag's end to
    // the left, and the nearest existing tag's start to the right (or the
    // text's own edges, with nothing tagged that way yet).
    var minStart = 0;
    for (final t in _tags) {
      if (t.end <= selection.start && t.end > minStart) minStart = t.end;
    }
    var maxEnd = _sampleController.text.length;
    for (final t in _tags) {
      if (t.start >= selection.end && t.start < maxEnd) maxEnd = t.start;
    }

    final result = await showDialog<(String, String?, int, int)>(
      context: context,
      builder: (context) => _TagPickerDialog(
        fullText: _sampleController.text,
        initialStart: selection.start,
        initialEnd: selection.end,
        minStart: minStart,
        maxEnd: maxEnd,
        availableTags: _availableTags,
        operation: _operation,
      ),
    );
    if (result == null) return;
    setState(() {
      _tags.add(
        _TaggedSpan(
          start: result.$3,
          end: result.$4,
          tag: result.$1,
          role: result.$2,
        ),
      );
      _tags.sort((a, b) => a.start.compareTo(b.start));
      _sampleController.selection = const TextSelection.collapsed(offset: -1);
    });
  }

  List<SmsRuleSegment> _buildSegments() {
    final text = _sampleController.text;
    final sorted = [..._tags]..sort((a, b) => a.start.compareTo(b.start));
    final segments = <SmsRuleSegment>[];
    var cursor = 0;
    for (final tag in sorted) {
      if (tag.start > cursor) {
        segments.add(SmsRuleSegment.literal(text.substring(cursor, tag.start)));
      }
      segments.add(
        SmsRuleSegment.placeholder(
          text: text.substring(tag.start, tag.end),
          tag: tag.tag,
          role: tag.role,
        ),
      );
      cursor = tag.end;
    }
    if (cursor < text.length) {
      segments.add(SmsRuleSegment.literal(text.substring(cursor)));
    }
    return segments;
  }

  /// A run of 2+ digits, with an optional decimal/thousands group -- "978",
  /// "978.00", "45,623.09" -- found inside an *untagged* (literal) segment.
  /// A number like this sitting in literal text is exactly what turned a
  /// past-tense purchase amount into a permanent requirement on a real
  /// rule (see [_showUntaggedNumbersWarning]'s own doc comment): it's
  /// baked in verbatim, either as a strict-mode exact match or, in
  /// flexible mode, as one of the couple of anchor words kept next to a
  /// tag -- either way, a real SMS with any other value there can never
  /// match again.
  static final _numberLikePattern = RegExp(r'\d{2,}(?:[.,]\d+)?');

  List<String> _untaggedNumbersIn(List<SmsRuleSegment> segments) {
    return [
      for (final segment in segments)
        if (segment.isLiteral)
          for (final match in _numberLikePattern.allMatches(segment.text))
            match.group(0)!,
    ];
  }

  /// A soft, dismissible check on Save -- not everything numeric in a
  /// literal segment is actually a problem (a fixed customer-service
  /// number in the message's boilerplate footer never changes, for
  /// instance), so this warns rather than blocks. Returns whether to go
  /// ahead and save; `true` when there was nothing to flag in the first
  /// place.
  Future<bool> _confirmUntaggedNumbers(List<SmsRuleSegment> segments) async {
    final numbers = _untaggedNumbersIn(segments);
    if (numbers.isEmpty) return true;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Untagged numbers in this rule'),
        content: Text(
          '${numbers.length == 1 ? 'This number isn\'t' : 'These numbers aren\'t'} '
          'tagged, so the rule requires ${numbers.length == 1 ? 'it' : 'them'} to '
          'appear exactly like this in every future SMS: '
          '${numbers.map((n) => '"$n"').join(', ')}.\n\n'
          'If any of these can be different next time -- an amount, a reference '
          'number, an extension -- go back and mark it (Value or "Varies") '
          'before saving, or this rule will stop matching once it does change. '
          'If it\'s always the same, it\'s fine to save as-is.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save anyway'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  String? _validate() {
    if (_bankId == null) return 'Pick a bank';
    if (_sampleController.text.trim().isEmpty) return 'Paste a sample SMS';
    if (_operation == 'ledgerPayment') {
      if (_targetCounterpartyId == null) {
        return 'Pick which ledger this adds to';
      }
      if (!_tags.any((t) => t.tag == 'value')) {
        return 'Mark the payment amount as a Value';
      }
    } else {
      if (!_tags.any((t) => t.tag == 'cardNumber')) {
        return 'Mark the card/account number';
      }
      if (!_tags.any((t) => t.tag == 'value')) {
        return 'Mark the balance amount as a Value';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final segments = _buildSegments();
    if (!await _confirmUntaggedNumbers(segments)) return;
    if (!mounted) return;
    final name = _nameController.text.trim();
    final repo = ref.read(smsRuleRepositoryProvider);
    if (_isEditing) {
      await repo.updateRule(
        widget.existing!.copyWith(
          name: Value(name.isEmpty ? null : name),
          bankId: _bankId!,
          operation: _operation,
          sampleText: _sampleController.text,
          segmentsJson: encodeSmsRuleSegments(segments),
          targetCounterpartyId: Value(
            _operation == 'ledgerPayment' ? _targetCounterpartyId : null,
          ),
          currency: Value(_operation == 'ledgerPayment' ? _currency : null),
          notifyOnMatch: _notifyOnMatch,
          matchMode: _matchMode,
        ),
      );
    } else {
      await repo.add(
        name: name.isEmpty ? null : name,
        bankId: _bankId!,
        operation: _operation,
        sampleText: _sampleController.text,
        segments: segments,
        targetCounterpartyId: _operation == 'ledgerPayment'
            ? _targetCounterpartyId
            : null,
        currency: _operation == 'ledgerPayment' ? _currency : null,
        notifyOnMatch: _notifyOnMatch,
        matchMode: _matchMode,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(smsRuleRepositoryProvider).delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  List<InlineSpan> _previewSpans() {
    final text = _sampleController.text;
    if (text.isEmpty) return const [];
    final sorted = [..._tags]..sort((a, b) => a.start.compareTo(b.start));
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final tag in sorted) {
      if (tag.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, tag.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(tag.start, tag.end),
          style: TextStyle(
            backgroundColor: _tagColors[tag.tag],
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      cursor = tag.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final banks = ref.watch(banksStreamProvider).valueOrNull ?? const [];
    final counterparties =
        ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];
    final colors = context.appColors;
    final sampleDirection = _detectSampleDirection(_sampleController.text);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit SMS rule' : 'Add SMS rule'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Rule name (optional)',
                hintText: 'e.g. Amazon refund',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: banks.any((b) => b.id == _bankId) ? _bankId : null,
              decoration: const InputDecoration(labelText: 'Bank'),
              items: banks
                  .map(
                    (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _bankId = v),
            ),
            const SizedBox(height: 16),
            Text(
              'What does this rule do?',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: _operations
                  .map(
                    (o) => ButtonSegment(
                      value: o.$1,
                      label: Text(o.$2, textAlign: TextAlign.center),
                    ),
                  )
                  .toList(),
              selected: {_operation},
              onSelectionChanged: (s) => setState(() {
                _operation = s.first;
                _tags.removeWhere((t) => !_availableTags.contains(t.tag));
              }),
            ),
            if (_operation == 'ledgerPayment') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue:
                    counterparties.any((c) => c.id == _targetCounterpartyId)
                    ? _targetCounterpartyId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Adds to which ledger',
                ),
                items: counterparties
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _targetCounterpartyId = v),
              ),
              const SizedBox(height: 12),
              CurrencyPickerField(
                value: _currency,
                labelText: 'Default currency',
                helperText:
                    'Used unless a Currency tag is marked and recognized in the message itself.',
                onChanged: (c) => setState(() => _currency = c),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Paste a real sample SMS',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Then select a portion of it below and tap "Tag selection" to mark what it is.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textDim),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sampleController,
              maxLines: 6,
              minLines: 3,
              textDirection: sampleDirection,
              decoration: const InputDecoration(
                hintText: 'Paste the SMS text here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            // Explicit buttons alongside the system long-press menu -- some
            // devices/keyboards don't reliably show a "Paste" option over
            // this field, so this is a guaranteed-to-work fallback for it.
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pasteSample,
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('Paste'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _sampleController.text.isEmpty
                      ? null
                      : _copySample,
                  icon: const Icon(Icons.content_copy, size: 18),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: const Icon(Icons.label_outline),
              label: const Text('Tag selection'),
              onPressed: _sampleController.text.isEmpty ? null : _tagSelection,
            ),
            if (_sampleController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Text.rich(
                  TextSpan(children: _previewSpans()),
                  textDirection: sampleDirection,
                ),
              ),
            ],
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in _tags)
                    InputChip(
                      label: Text(
                        '${_tagLabels[tag.tag]}: "${_sampleController.text.substring(tag.start, tag.end)}"'
                        '${tag.role == null ? '' : ' (${_roleLabel(_operation, tag.tag, tag.role)})'}',
                      ),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notify me when this rule activates'),
              subtitle: const Text(
                'Shows a notification from a recent matching SMS',
              ),
              value: _notifyOnMatch,
              onChanged: (v) => setState(() => _notifyOnMatch = v),
            ),
            const SizedBox(height: 20),
            Text('Matching', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              _matchMode == 'flexible'
                  ? 'Only a couple of words next to each tag are required -- '
                        'everything else can vary, at the cost of a small '
                        'chance of matching an unrelated message.'
                  : 'The untagged parts of your sample must appear in the '
                        'real SMS almost exactly.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'strict', label: Text('Strict')),
                ButtonSegment(value: 'flexible', label: Text('Flexible')),
              ],
              selected: {_matchMode},
              onSelectionChanged: (s) => setState(() => _matchMode = s.first),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

class _TagPickerDialog extends StatefulWidget {
  const _TagPickerDialog({
    required this.fullText,
    required this.initialStart,
    required this.initialEnd,
    required this.minStart,
    required this.maxEnd,
    required this.availableTags,
    required this.operation,
  });

  final String fullText;
  final int initialStart;
  final int initialEnd;
  final int minStart;
  final int maxEnd;
  final List<String> availableTags;
  final String operation;

  @override
  State<_TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends State<_TagPickerDialog> {
  late String _tag = widget.availableTags.first;
  String? _role;
  late int _start = widget.initialStart;
  late int _end = widget.initialEnd;

  @override
  void initState() {
    super.initState();
    _role = _defaultRoleFor(_tag);
  }

  String? _defaultRoleFor(String tag) => switch (tag) {
    'value' => widget.operation == 'ledgerPayment' ? 'charge' : 'set',
    'transactionValue' => 'subtract',
    _ => null,
  };

  String get _selectedText => widget.fullText.substring(_start, _end);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final roleOptions = _tag == 'transactionValue'
        ? _transactionValueRoles
        : widget.operation == 'ledgerPayment'
        ? _ledgerRoles
        : _balanceRoles;
    return AlertDialog(
      title: const Text('Tag this portion'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Directional, not just the ambient (LTR) dialog default: a
            // selection dragged across an Arabic/English or Arabic/digit
            // boundary is exactly the case bidi text makes hardest to select
            // precisely (see _detectSampleDirection's own doc comment), so
            // this preview -- showing back exactly the substring that was
            // captured -- needs to render it the same way the sample field
            // itself did, not silently reorder it into something that looks
            // "close enough" and hides an off-by-a-few-characters selection.
            // The +/- controls below exist because that drag can still land
            // on the wrong characters even so -- letting the boundary be
            // nudged one character at a time means a bad drag is fixable
            // instead of silently producing a rule that can never match.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                _selectedText,
                textDirection: _detectSampleDirection(_selectedText),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 0,
              runSpacing: 4,
              children: [
                Text('Start', style: Theme.of(context).textTheme.labelSmall),
                IconButton(
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Include one more character',
                  onPressed: _start > widget.minStart
                      ? () => setState(() => _start--)
                      : null,
                ),
                const SizedBox(width: 4),
                IconButton(
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Exclude the first character',
                  onPressed: _start < _end - 1
                      ? () => setState(() => _start++)
                      : null,
                ),
                const SizedBox(width: 16),
                Text('End', style: Theme.of(context).textTheme.labelSmall),
                IconButton(
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Exclude the last character',
                  onPressed: _end > _start + 1
                      ? () => setState(() => _end--)
                      : null,
                ),
                const SizedBox(width: 4),
                IconButton(
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Include one more character',
                  onPressed: _end < widget.maxEnd
                      ? () => setState(() => _end++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('What is this?'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in widget.availableTags)
                  ChoiceChip(
                    label: Text(_tagLabels[tag]!),
                    selected: _tag == tag,
                    onSelected: (_) => setState(() {
                      _tag = tag;
                      _role = _defaultRoleFor(_tag);
                    }),
                  ),
              ],
            ),
            if (_tag == 'value' || _tag == 'transactionValue') ...[
              const SizedBox(height: 16),
              const Text('What should it do?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in roleOptions)
                    ChoiceChip(
                      label: Text(option.$2),
                      selected: _role == option.$1,
                      onSelected: (_) => setState(() => _role = option.$1),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_tag, _role, _start, _end)),
          child: const Text('Tag'),
        ),
      ],
    );
  }
}

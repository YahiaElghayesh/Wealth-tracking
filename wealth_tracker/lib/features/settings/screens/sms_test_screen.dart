import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/sms_rule_display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/db/database.dart';
import '../../../data/sms/sms_ledger_processor.dart';
import '../../../data/sms/sms_rule_engine.dart'
    show decodeSmsRuleSegments, findUnsatisfiedRequirements;
import '../../networth/providers/asset_providers.dart' show databaseProvider;
import '../providers/sms_rule_providers.dart';

const _operationLabels = {
  'creditCardBalance': 'Credit card balance',
  'bankAccountBalance': 'Bank account balance',
  'ledgerPayment': 'Ledger payment',
};

/// Lets the user paste a real (or made-up) SMS and run it through their
/// actual saved SMS Rules on demand -- the same [commitSmsAutoDetect] path
/// SmsReceiver.kt's background task calls for a genuine incoming SMS, not
/// a separate/simplified copy of it, so a rule that passes here behaves
/// identically once a real bank text arrives. This genuinely applies
/// whatever matches -- updates a balance, adds a ledger entry, posts a
/// notification -- exactly as if the message had just been received;
/// running the same text again is a second, independent "arrival" (a
/// fresh timestamp each time, so nothing here is deduplicated against an
/// earlier test run), which can double-apply an add/subtract role.
class SmsTestScreen extends ConsumerStatefulWidget {
  const SmsTestScreen({super.key, this.initialBody});

  /// Pre-fills the paste box -- set when reached from a specific rule's own
  /// edit screen (its "Test" button) with that rule's saved sample text, so
  /// checking whether a just-edited rule still matches doesn't also require
  /// re-copying its sample over by hand.
  final String? initialBody;

  @override
  ConsumerState<SmsTestScreen> createState() => _SmsTestScreenState();
}

class _SmsTestScreenState extends ConsumerState<SmsTestScreen> {
  final _controller = TextEditingController();
  bool _running = false;
  List<MatchedSmsRule>? _lastMatches;
  String _lastTestedBody = '';

  @override
  void initState() {
    super.initState();
    final initialBody = widget.initialBody;
    if (initialBody != null) _controller.text = initialBody;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Explicit buttons alongside the system long-press menu -- some
  /// devices/keyboards don't reliably show a "Paste" option over this
  /// field, so these are a guaranteed-to-work fallback for it.
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    final oldText = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid
        ? selection.start.clamp(0, oldText.length)
        : oldText.length;
    final end = selection.isValid
        ? selection.end.clamp(0, oldText.length)
        : oldText.length;
    _controller.value = TextEditingValue(
      text: oldText.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  Future<void> _copy() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    final selection = _controller.selection;
    final toCopy = selection.isValid && !selection.isCollapsed
        ? text.substring(selection.start, selection.end)
        : text;
    await Clipboard.setData(ClipboardData(text: toCopy));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied')));
  }

  Future<void> _runTest() async {
    // Not `_controller.text.trim()` -- trimming here would run a
    // different string through matching than a real SMS ever does.
    // [commitSmsAutoDetect] and friends only ever use `.trim().isEmpty`
    // as an emptiness check, never actually stripping the body they go
    // on to match with, since a rule's own pattern can itself require
    // leading/trailing whitespace (a literal segment ending in a space
    // before the message's final period, say) that a genuine SMS still
    // has. Trimming here meant a message that would have matched fine on
    // arrival could silently fail only in this screen, for no reason
    // visible in the pasted text itself.
    final body = _controller.text;
    if (body.trim().isEmpty) return;
    setState(() {
      _running = true;
      _lastMatches = null;
    });

    final db = ref.read(databaseProvider);
    // Read first, purely for what this screen shows -- the real
    // side effects (and the actual notification, if any) come from
    // commitSmsAutoDetect below, run against the same raw text a real SMS
    // would arrive as.
    final matches = await previewSmsRuleMatches(db, body);
    await commitSmsAutoDetect(
      db,
      body: body,
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
    );

    if (!mounted) return;
    setState(() {
      _running = false;
      _lastMatches = matches;
      _lastTestedBody = body;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final matches = _lastMatches;
    final rules = ref.watch(smsRulesStreamProvider).valueOrNull ?? const [];
    final banks = ref.watch(banksStreamProvider).valueOrNull ?? const [];
    final bankNames = {for (final b in banks) b.id: b.name};

    return Scaffold(
      appBar: AppBar(title: const Text('Test an SMS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a real or sample SMS below and run it through your '
              'saved SMS Rules exactly as if it had just arrived. This '
              'actually applies whatever matches -- updates a balance, adds '
              'a ledger entry, or posts a notification for review -- the '
              'same as a real SMS would.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textDim),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 6,
              minLines: 3,
              // Same directional rendering the rule cards below use ([_RuleRequirementCard],
              // detectSampleDirection) -- without this, this box and those
              // cards can word-wrap the very same underlying text
              // differently, making a byte-identical message look
              // different at a glance for no real reason.
              textDirection: detectSampleDirection(_controller.text),
              decoration: const InputDecoration(
                hintText: 'Paste the SMS text here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('Paste'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _controller.text.isEmpty ? null : _copy,
                  icon: const Icon(Icons.content_copy, size: 18),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: _running
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Run test'),
              onPressed: (_running || _controller.text.trim().isEmpty)
                  ? null
                  : _runTest,
            ),
            if (matches != null) ...[
              const SizedBox(height: 20),
              if (matches.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: const Text(
                    'No SMS Rule matched this message -- nothing was '
                    'applied.',
                  ),
                ),
                if (rules.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'What each rule requires',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compare this against the message above, piece by '
                    'piece -- highlighted portions are what a rule '
                    "extracts; everything else has to appear exactly "
                    "as shown (word-for-word in Strict mode, or just the "
                    'couple of words next to each highlight in Flexible).',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textDim),
                  ),
                  const SizedBox(height: 8),
                  for (final rule in rules) ...[
                    _RuleRequirementCard(
                      rule: rule,
                      bankName: bankNames[rule.bankId],
                      testedBody: _lastTestedBody,
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ] else ...[
                Text(
                  '${matches.length} rule${matches.length == 1 ? '' : 's'} '
                  'matched and ${matches.length == 1 ? 'was' : 'were'} '
                  'applied:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                for (final matched in matches) ...[
                  _MatchCard(matched: matched),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows exactly what one rule requires, tag by tag -- the same
/// highlighted rendering the rule editor itself uses (see
/// `sms_rule_display.dart`), so a rule that quietly can't match anymore
/// (a stale/off tag boundary, a mismatched literal) can be spotted by eye
/// directly against the real message above, without anyone needing to
/// describe or screenshot it -- rendering loses nothing here, since this
/// reads the rule's own saved segments straight from the database.
class _RuleRequirementCard extends StatelessWidget {
  const _RuleRequirementCard({
    required this.rule,
    required this.bankName,
    required this.testedBody,
  });

  final SmsRule rule;
  final String? bankName;
  final String testedBody;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final segments = decodeSmsRuleSegments(rule.segmentsJson);
    final unsatisfied = findUnsatisfiedRequirements(rule, testedBody);
    final title = (rule.name?.trim().isNotEmpty ?? false)
        ? rule.name!
        : _operationLabels[rule.operation] ?? rule.operation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (!rule.enabled)
                Text(
                  'Disabled',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.bad),
                ),
            ],
          ),
          Text(
            '${bankName ?? 'Unknown bank'} · '
            '${_operationLabels[rule.operation] ?? rule.operation} · '
            '${rule.matchMode == 'flexible' ? 'Flexible' : 'Strict'}',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.textDim),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                for (final segment in segments)
                  segment.isPlaceholder
                      ? TextSpan(
                          text: segment.text,
                          style: TextStyle(
                            backgroundColor: smsTagColors[segment.tag],
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : TextSpan(text: segment.text),
              ],
            ),
            textDirection: detectSampleDirection(rule.sampleText),
          ),
          if (unsatisfied.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bad.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.bad.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "This text doesn't appear anywhere in your message:",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.bad,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final requirement in unsatisfied)
                    Text(
                      requirement.description,
                      textDirection: detectSampleDirection(
                        requirement.description,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.matched});

  final MatchedSmsRule matched;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rule = matched.rule;
    final match = matched.match;
    final fields = <String>[
      if (match.cardNumber != null) 'Card/account: "${match.cardNumber}"',
      if (match.value != null)
        'Value: ${match.value}${match.valueRole == null ? '' : ' (${match.valueRole})'}',
      if (match.transactionValue != null)
        'Transaction amount: ${match.transactionValue}'
            '${match.transactionValueRole == null ? '' : ' (${match.transactionValueRole})'}',
      if (match.currency != null) 'Currency: ${match.currency}',
      if (match.transactionCurrency != null)
        'Transaction currency: ${match.transactionCurrency}',
      if (match.vendor != null) 'Vendor: "${match.vendor}"',
      if (match.sender != null) 'Sender: "${match.sender}"',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (rule.name?.trim().isNotEmpty ?? false)
                ? rule.name!
                : _operationLabels[rule.operation] ?? rule.operation,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (rule.name?.trim().isNotEmpty ?? false)
            Text(
              _operationLabels[rule.operation] ?? rule.operation,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.textDim),
            ),
          const SizedBox(height: 8),
          for (final field in fields)
            Text(field, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/calculator_custom_item.dart';
import '../../../core/models/card_snapshot_entry.dart';
import '../../../core/models/currency.dart';
import '../../../core/models/manual_input_snapshot_entry.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/calculator/current_money_calculator.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../../data/repositories/calculator_repository.dart';
import '../../networth/providers/asset_providers.dart' show pricesUsdPerUnitProvider;
import '../../settings/screens/credit_cards_settings_screen.dart';
import '../../settings/screens/manual_inputs_settings_screen.dart';
import '../providers/calculator_providers.dart';
import 'calculator_history_screen.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _cardControllers = <String, TextEditingController>{};
  final _manualInputControllers = <String, TextEditingController>{};
  final _customItems = <CustomCalculatorItem>[];
  final _scrollController = ScrollController();

  // Cards default-prefill exactly once, the first time their data arrives —
  // to their last known available balance (SMS-tracked, if bank SMS
  // detection is on; otherwise the card's own limit, "as if nothing's been
  // spent yet"). Manual inputs default-prefill from the latest saved
  // snapshot's matching-by-name entry, if any. A user edit (including
  // clearing the field back to save a snapshot) must not be overwritten on
  // the next rebuild, hence the one-shot flags — per-id, so an item added
  // later still gets its own default without re-seeding ones already
  // touched.
  final _seededCardIds = <String>{};
  final _seededManualInputIds = <String>{};
  bool _saving = false;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.hasClients && _scrollController.offset > 4;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in _cardControllers.values) {
      c.dispose();
    }
    for (final c in _manualInputControllers.values) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController controller) => double.tryParse(controller.text.trim()) ?? 0;

  static String _formatSeed(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  /// Lazily creates (and wires up) a controller for [card], so newly added
  /// cards get one without disturbing controllers for cards already on
  /// screen.
  TextEditingController _cardControllerFor(CreditCard card) {
    return _cardControllers.putIfAbsent(card.id, () {
      final controller = TextEditingController();
      controller.addListener(_onFieldChanged);
      return controller;
    });
  }

  TextEditingController _manualInputControllerFor(ManualInput input) {
    return _manualInputControllers.putIfAbsent(input.id, () {
      final controller = TextEditingController();
      controller.addListener(_onFieldChanged);
      return controller;
    });
  }

  /// Owed amount per card, in the card's own currency (not yet converted).
  double _owedFor(CreditCard card) {
    return cardOwedAmount(limit: card.limitAmount, availableBalance: _parse(_cardControllerFor(card)));
  }

  /// [_owedFor] converted to the app's settlement currency — falls back to
  /// the raw, unconverted figure if no FX rate is available yet, rather
  /// than silently dropping the card from the total.
  double _owedInDefaultCurrency(CreditCard card, Map<String, double> prices) {
    final owed = _owedFor(card);
    if (card.currency == defaultCurrency) return owed;
    return convertToSettlement(owed, card.currency, prices) ?? owed;
  }

  double _manualInputSignedAmount(ManualInput input, Map<String, double> prices) {
    final raw = _parse(_manualInputControllerFor(input));
    final converted = input.currency == defaultCurrency ? raw : (convertToSettlement(raw, input.currency, prices) ?? raw);
    return input.isAddition ? converted : -converted;
  }

  Future<void> _addCustomItem() async {
    final labelController = TextEditingController();
    final amountController = TextEditingController();
    var isAddition = true;

    final item = await showDialog<CustomCalculatorItem>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'What is it?'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount', hintText: '0.00'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Add (+)')),
                  ButtonSegment(value: false, label: Text('Subtract (−)')),
                ],
                selected: {isAddition},
                onSelectionChanged: (s) => setDialogState(() => isAddition = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                final label = labelController.text.trim();
                if (amount == null || amount <= 0 || label.isEmpty) return;
                Navigator.pop(
                  context,
                  CustomCalculatorItem(label: label, amount: amount, isAddition: isAddition),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (item != null) setState(() => _customItems.add(item));
  }

  Future<void> _save(
    double ledgersTotal,
    List<CreditCard> cards,
    List<ManualInput> manualInputs,
    Map<String, double> prices,
  ) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final cardOwedAmounts = [for (final card in cards) _owedInDefaultCurrency(card, prices)];
      final manualInputAmounts = [for (final input in manualInputs) _manualInputSignedAmount(input, prices)];
      final result = calculateCurrentMoney(
        ledgersTotal: ledgersTotal,
        cardOwedAmounts: cardOwedAmounts,
        manualInputAmounts: manualInputAmounts,
        customItems: _customItems,
      );

      final cardEntries = [
        for (final card in cards)
          CardSnapshotEntry(
            name: card.name,
            bank: card.bank,
            currency: card.currency,
            limit: card.limitAmount,
            availableBalance: _parse(_cardControllerFor(card)),
            owed: _owedFor(card),
          ),
      ];
      final manualInputEntries = [
        for (final input in manualInputs)
          ManualInputSnapshotEntry(
            name: input.name,
            amount: _parse(_manualInputControllerFor(input)),
            isAddition: input.isAddition,
            currency: input.currency,
          ),
      ];

      await ref.read(calculatorRepositoryProvider).saveSnapshot(
            resultAmount: result,
            ledgersTotal: ledgersTotal,
            cardEntries: cardEntries,
            manualInputEntries: manualInputEntries,
            customItems: _customItems,
          );

      if (!mounted) return;
      setState(() {
        _customItems.clear();
        _saving = false;
        // Re-seed on the next build: cards back to their limits, manual
        // inputs to what was just saved (now the latest snapshot).
        _seededCardIds.clear();
        _seededManualInputIds.clear();
      });

      final savedAt = TimeOfDay.now();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Saved · Recorded to history at ${savedAt.format(context)}'),
            ],
          ),
          backgroundColor: context.appColors.good,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: context.appColors.bad),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(creditCardsStreamProvider);
    final manualInputsAsync = ref.watch(manualInputsStreamProvider);
    final ledgersTotal = ref.watch(ledgersTotalProvider);
    final historyAsync = ref.watch(calculatorHistoryStreamProvider);
    final prices = ref.watch(pricesUsdPerUnitProvider);

    final latestHistory = historyAsync.valueOrNull;
    final currentCards = cardsAsync.valueOrNull;
    final currentManualInputs = manualInputsAsync.valueOrNull;
    final unseededCards = currentCards?.where((c) => !_seededCardIds.contains(c.id)).toList();
    final unseededManualInputs =
        currentManualInputs?.where((m) => !_seededManualInputIds.contains(m.id)).toList();
    final needsSeeding = (unseededCards != null && unseededCards.isNotEmpty) ||
        (unseededManualInputs != null && unseededManualInputs.isNotEmpty);
    if (needsSeeding) {
      // Setting controller.text synchronously here would fire the field
      // listener (which calls setState) mid-build, which Flutter forbids —
      // defer the actual seeding to right after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (unseededCards != null) {
            for (final card in unseededCards) {
              _cardControllerFor(card).text = _formatSeed(card.currentAvailableBalance ?? card.limitAmount);
              _seededCardIds.add(card.id);
            }
          }
          if (unseededManualInputs != null) {
            for (final input in unseededManualInputs) {
              final lastEntry = latestHistory != null && latestHistory.isNotEmpty
                  ? latestHistory.first.manualInputEntries
                      .where((e) => e.name == input.name)
                      .firstOrNull
                  : null;
              if (lastEntry != null) {
                _manualInputControllerFor(input).text = _formatSeed(lastEntry.amount);
              }
              _seededManualInputIds.add(input.id);
            }
          }
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          const HideValuesAction(),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculatorHistoryScreen()),
            ),
          ),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (cards) {
          final manualInputs = currentManualInputs ?? const <ManualInput>[];
          final cardOwedAmounts = [for (final card in cards) _owedInDefaultCurrency(card, prices)];
          final manualInputAmounts = [for (final input in manualInputs) _manualInputSignedAmount(input, prices)];
          final result = calculateCurrentMoney(
            ledgersTotal: ledgersTotal,
            cardOwedAmounts: cardOwedAmounts,
            manualInputAmounts: manualInputAmounts,
            customItems: _customItems,
          );

          return Column(
            children: [
              _StickyTotalCard(result: result, scrolled: _scrolled),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _Section(
                      title: 'Ledgers',
                      children: [
                        _SignedRow(
                          isAddition: true,
                          label: 'All ledgers combined',
                          trailing: MoneyText(
                            formatMoney(ledgersTotal, defaultCurrency),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Manual inputs',
                      subtitle: manualInputs.isEmpty ? 'No manual inputs yet — add one in Settings.' : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Manage manual inputs',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ManualInputsSettingsScreen()),
                        ),
                      ),
                      children: [
                        for (final input in manualInputs) ...[
                          _SignedAmountField(
                            key: ValueKey('manual-${input.id}-${_seededManualInputIds.contains(input.id)}'),
                            isAddition: input.isAddition,
                            label: input.name,
                            controller: _manualInputControllerFor(input),
                            currency: input.currency,
                          ),
                          if (input != manualInputs.last) const SizedBox(height: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Credit cards',
                      subtitle: cards.isEmpty
                          ? 'No cards yet — add one in Settings.'
                          : 'Enter the balance still available to spend, as shown in your banking '
                              'app — not what you owe.',
                      trailing: IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Manage cards',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreditCardsSettingsScreen()),
                        ),
                      ),
                      children: [
                        for (final card in cards) ...[
                          _CardField(
                            card: card,
                            controller: _cardControllerFor(card),
                            owed: _owedFor(card),
                            rateMissing: card.currency != defaultCurrency &&
                                convertToSettlement(0, card.currency, prices) == null,
                          ),
                          if (card != cards.last) const SizedBox(height: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Other',
                      subtitle: 'Anything else — plus or minus.',
                      children: [
                        for (var i = 0; i < _customItems.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SignedRow(
                              isAddition: _customItems[i].isAddition,
                              label: _customItems[i].label,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MoneyText(
                                    formatMoney(_customItems[i].amount, defaultCurrency),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () => setState(() => _customItems.removeAt(i)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add item'),
                          onPressed: _addCustomItem,
                        ),
                      ],
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: cardsAsync.hasValue
          ? _SaveBar(
              saving: _saving,
              onPressed: () => _save(ledgersTotal, cardsAsync.value!, currentManualInputs ?? const [], prices),
            )
          : null,
    );
  }
}

/// The mockup's "sticky-total" card — pinned above the scrollable form
/// instead of scrolling away with it, since that's the one number this
/// whole screen exists to answer. Picks up a shadow once the form beneath
/// it has scrolled, matching the mockup's `.scrolled` state.
class _StickyTotalCard extends StatelessWidget {
  const _StickyTotalCard({required this.result, required this.scrolled});

  final double result;
  final bool scrolled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.28)),
        boxShadow: scrolled
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 10))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'CURRENT LIQUID CASH',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          MoneyText(
            formatMoney(result, defaultCurrency),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            maskLength: 9,
          ),
        ],
      ),
    );
  }
}

/// Sticky, accent-filled bar pinned to the bottom of the screen (outside
/// the scrollable form) so it's always reachable, matching the mockup's
/// `.save-bar`.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: saving ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (saving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    saving ? 'Saving…' : 'Save calculation',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled, bordered group — makes it visually obvious where one set of
/// inputs ends and the next begins.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                ?trailing,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Small colored +/- badge so it's unambiguous whether a line adds to or
/// subtracts from the total.
class _SignBadge extends StatelessWidget {
  const _SignBadge({required this.isAddition});

  final bool isAddition;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isAddition ? colors.good : colors.bad;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        isAddition ? '+' : '−',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}

class _SignedRow extends StatelessWidget {
  const _SignedRow({required this.isAddition, required this.label, required this.trailing});

  final bool isAddition;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SignBadge(isAddition: isAddition),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        trailing,
      ],
    );
  }
}

class _SignedAmountField extends StatelessWidget {
  const _SignedAmountField({
    super.key,
    required this.isAddition,
    required this.label,
    required this.controller,
    required this.currency,
  });

  final bool isAddition;
  final String label;
  final TextEditingController controller;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SignBadge(isAddition: isAddition),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectAllOnFocusField(
            key: key,
            controller: controller,
            decoration: InputDecoration(labelText: label, hintText: '0.00', suffixText: currency),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }
}

/// A numeric field that selects its entire current value the moment it
/// gains focus, so a default-prefilled value (a card's limit, a manual
/// input's last saved figure...) is replaced by simply typing over it —
/// tapping away without typing leaves the value untouched, since only the
/// selection highlight changes, not the text itself.
class _SelectAllOnFocusField extends StatefulWidget {
  const _SelectAllOnFocusField({super.key, required this.controller, this.decoration, this.keyboardType});

  final TextEditingController controller;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;

  @override
  State<_SelectAllOnFocusField> createState() => _SelectAllOnFocusFieldState();
}

class _SelectAllOnFocusFieldState extends State<_SelectAllOnFocusField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      widget.controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.controller.text.length);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
    );
  }
}

/// A short, human "how long ago" label for a card's SMS-tracked balance —
/// e.g. "just now" / "12m ago" / "3h ago" / "2d ago".
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// The mockup's "cc-card" pattern: name·bank + limit header, an available-
/// balance input, and a read-only/dashed "Owed" field the app computes.
class _CardField extends ConsumerWidget {
  const _CardField({
    required this.card,
    required this.controller,
    required this.owed,
    required this.rateMissing,
  });

  final CreditCard card;
  final TextEditingController controller;
  final double owed;
  final bool rateMissing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final hideValues = ref.watch(hideValuesProvider);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hideValues ? '••••••' : '${card.name} · ${card.bank}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              MoneyText(
                'Limit ${formatMoney(card.limitAmount, card.currency)}',
                style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim),
                maskLength: 12,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SelectAllOnFocusField(
            controller: controller,
            decoration: InputDecoration(labelText: 'Available balance (${card.currency})', hintText: '0.00'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (card.balanceUpdatedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Updated from SMS ${_relativeTime(card.balanceUpdatedAt!)}',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border, style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                Text(
                  rateMissing ? 'Owed (no exchange rate yet, unconverted)' : 'Owed',
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                MoneyText(
                  formatMoney(owed, card.currency),
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.bad, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

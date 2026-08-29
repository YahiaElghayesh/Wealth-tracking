import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/calculator_custom_item.dart';
import '../../../core/models/card_snapshot_entry.dart';
import '../../../core/models/currency.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/calculator/current_money_calculator.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../networth/providers/asset_providers.dart' show pricesUsdPerUnitProvider;
import '../../settings/screens/credit_cards_settings_screen.dart';
import '../providers/calculator_providers.dart';
import 'calculator_history_screen.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _apartmentController = TextEditingController();
  final _cibController = TextEditingController();
  final _cardControllers = <String, TextEditingController>{};
  final _customItems = <CustomCalculatorItem>[];

  // Both default-prefill exactly once, the first time their data arrives —
  // cards to "as if nothing's been spent yet" (available == limit), and
  // apartment savings to the last saved snapshot's value, so the user only
  // has to adjust rather than re-type every time. A user edit (including
  // clearing the field back to save a snapshot) must not be overwritten on
  // the next rebuild, hence the one-shot flags. Cards seed per-card-id, so
  // a card added later still gets its own default without re-seeding ones
  // already touched.
  final _seededCardIds = <String>{};
  bool _apartmentSeeded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [_apartmentController, _cibController]) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _apartmentController.dispose();
    _cibController.dispose();
    for (final c in _cardControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController controller) => double.tryParse(controller.text.trim()) ?? 0;

  static String _formatSeed(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  /// Lazily creates (and wires up) a controller for [card], so newly added
  /// cards get one without disturbing controllers for cards already on
  /// screen.
  TextEditingController _controllerFor(CreditCard card) {
    return _cardControllers.putIfAbsent(card.id, () {
      final controller = TextEditingController();
      controller.addListener(_onFieldChanged);
      return controller;
    });
  }

  /// Owed amount per card, in the card's own currency (not yet converted).
  double _owedFor(CreditCard card) {
    return cardOwedAmount(limit: card.limitAmount, availableBalance: _parse(_controllerFor(card)));
  }

  /// [_owedFor] converted to the app's settlement currency — falls back to
  /// the raw, unconverted figure if no FX rate is available yet, rather
  /// than silently dropping the card from the total.
  double _owedInDefaultCurrency(CreditCard card, Map<String, double> prices) {
    final owed = _owedFor(card);
    if (card.currency == defaultCurrency) return owed;
    return convertToSettlement(owed, card.currency, prices) ?? owed;
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

  Future<void> _save(double ledgersTotal, List<CreditCard> cards, Map<String, double> prices) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final apartment = _parse(_apartmentController);
      final cib = _parse(_cibController);
      final cardOwedAmounts = [for (final card in cards) _owedInDefaultCurrency(card, prices)];
      final result = calculateCurrentMoney(
        ledgersTotal: ledgersTotal,
        apartmentSavings: apartment,
        cibAccountBalance: cib,
        cardOwedAmounts: cardOwedAmounts,
        customItems: _customItems,
      );

      final cardEntries = [
        for (final card in cards)
          CardSnapshotEntry(
            name: card.name,
            bank: card.bank,
            currency: card.currency,
            limit: card.limitAmount,
            availableBalance: _parse(_controllerFor(card)),
            owed: _owedFor(card),
          ),
      ];

      await ref.read(calculatorRepositoryProvider).saveSnapshot(
            resultAmount: result,
            ledgersTotal: ledgersTotal,
            apartmentSavings: apartment,
            cibAccountBalance: cib,
            cardEntries: cardEntries,
            customItems: _customItems,
          );

      _cibController.clear();
      if (!mounted) return;
      setState(() {
        _customItems.clear();
        _saving = false;
        // Re-seed on the next build: cards back to their limits, apartment
        // to what was just saved (now the latest snapshot).
        _seededCardIds.clear();
        _apartmentSeeded = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Saved to history'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(creditCardsStreamProvider);
    final ledgersTotal = ref.watch(ledgersTotalProvider);
    final historyAsync = ref.watch(calculatorHistoryStreamProvider);
    final prices = ref.watch(pricesUsdPerUnitProvider);

    final latestHistory = historyAsync.valueOrNull;
    final currentCards = cardsAsync.valueOrNull;
    final unseededCards = currentCards?.where((c) => !_seededCardIds.contains(c.id)).toList();
    if ((!_apartmentSeeded && latestHistory != null) || (unseededCards != null && unseededCards.isNotEmpty)) {
      // Setting controller.text synchronously here would fire the field
      // listener (which calls setState) mid-build, which Flutter forbids —
      // defer the actual seeding to right after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (!_apartmentSeeded && latestHistory != null) {
            if (latestHistory.isNotEmpty) {
              _apartmentController.text = _formatSeed(latestHistory.first.apartmentSavings);
            }
            _apartmentSeeded = true;
          }
          if (unseededCards != null) {
            for (final card in unseededCards) {
              _controllerFor(card).text = _formatSeed(card.limitAmount);
              _seededCardIds.add(card.id);
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
          final apartment = _parse(_apartmentController);
          final cib = _parse(_cibController);
          final cardOwedAmounts = [for (final card in cards) _owedInDefaultCurrency(card, prices)];
          final result = calculateCurrentMoney(
            ledgersTotal: ledgersTotal,
            apartmentSavings: apartment,
            cibAccountBalance: cib,
            cardOwedAmounts: cardOwedAmounts,
            customItems: _customItems,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ResultCard(result: result),
              const SizedBox(height: 20),
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
                title: 'Apartment savings',
                children: [
                  _SignedAmountField(
                    // Rebuilds this field's element fresh the instant it's
                    // seeded with the last saved value — reusing the same
                    // element across "goes from empty to programmatically
                    // filled" left the floating label stuck overlapping the
                    // value instead of settling above the box the way it
                    // does for a field the user types into normally.
                    key: ValueKey('apartment-$_apartmentSeeded'),
                    isAddition: false,
                    label: 'Amount',
                    controller: _apartmentController,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'CIB Accounts Balance',
                children: [
                  _SignedAmountField(isAddition: true, label: 'Amount', controller: _cibController),
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
                      controller: _controllerFor(card),
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
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save calculation'),
                onPressed: _saving ? null : () => _save(ledgersTotal, cards, prices),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final double result;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current liquid cash', style: Theme.of(context).textTheme.bodyMedium),
            MoneyText(
              formatMoney(result, defaultCurrency),
              style: Theme.of(context).textTheme.headlineMedium,
              maskLength: 9,
            ),
          ],
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
    final color = isAddition ? Colors.green : Colors.red;
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
  const _SignedAmountField({super.key, required this.isAddition, required this.label, required this.controller});

  final bool isAddition;
  final String label;
  final TextEditingController controller;

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
            decoration: InputDecoration(labelText: label, hintText: '0.00', suffixText: defaultCurrency),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }
}

/// A numeric field that selects its entire current value the moment it
/// gains focus, so a default-prefilled value (a card's limit, the last
/// apartment savings figure...) is replaced by simply typing over it —
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

class _CardField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${card.name} · ${card.bank}', style: Theme.of(context).textTheme.titleSmall),
              ),
              MoneyText(
                'Limit ${formatMoney(card.limitAmount, card.currency)}',
                style: Theme.of(context).textTheme.bodySmall,
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
          const SizedBox(height: 6),
          _SignedRow(
            isAddition: false,
            label: rateMissing ? 'Owed (no exchange rate yet, unconverted)' : 'Owed',
            trailing: MoneyText(formatMoney(owed, card.currency), style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

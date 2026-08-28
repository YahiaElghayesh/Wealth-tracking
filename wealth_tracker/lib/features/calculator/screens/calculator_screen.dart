import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/calculator_card.dart';
import '../../../core/models/calculator_custom_item.dart';
import '../../../core/models/currency.dart';
import '../../../data/calculator/current_money_calculator.dart';
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
  final _cardControllers = {for (final card in CalculatorCard.values) card: TextEditingController()};
  final _customItems = <CustomCalculatorItem>[];

  // Both default-prefill exactly once, the first time their data arrives —
  // cards to "as if nothing's been spent yet" (available == limit), and
  // apartment savings to the last saved snapshot's value, so the user only
  // has to adjust rather than re-type every time. A user edit (including
  // clearing the field back to save a snapshot) must not be overwritten on
  // the next rebuild, hence the one-shot flags.
  bool _cardsSeeded = false;
  bool _apartmentSeeded = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [_apartmentController, _cibController, ..._cardControllers.values]) {
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

  Map<CalculatorCard, double> _owedFor(Map<CalculatorCard, double> limits) {
    return {
      for (final card in CalculatorCard.values)
        card: cardOwedAmount(limit: limits[card] ?? card.defaultLimit, availableBalance: _parse(_cardControllers[card]!)),
    };
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

  Future<void> _save(double ledgersTotal, Map<CalculatorCard, double> limits) async {
    final owed = _owedFor(limits);
    final apartment = _parse(_apartmentController);
    final cib = _parse(_cibController);
    final result = calculateCurrentMoney(
      ledgersTotal: ledgersTotal,
      apartmentSavings: apartment,
      cibAccountBalance: cib,
      cardOwed: owed,
      customItems: _customItems,
    );

    await ref.read(calculatorRepositoryProvider).saveSnapshot(
          resultAmount: result,
          ledgersTotal: ledgersTotal,
          apartmentSavings: apartment,
          cibAccountBalance: cib,
          nbeAvailable: _parse(_cardControllers[CalculatorCard.nbe]!),
          nbeOwed: owed[CalculatorCard.nbe]!,
          cibExplorerWalletAvailable: _parse(_cardControllers[CalculatorCard.cibExplorerWallet]!),
          cibExplorerWalletOwed: owed[CalculatorCard.cibExplorerWallet]!,
          cibPlatinumAvailable: _parse(_cardControllers[CalculatorCard.cibPlatinum]!),
          cibPlatinumOwed: owed[CalculatorCard.cibPlatinum]!,
          customItems: _customItems,
        );

    _cibController.clear();
    setState(() {
      _customItems.clear();
      // Re-seed on the next build: cards back to their limits, apartment
      // to what was just saved (now the latest snapshot).
      _cardsSeeded = false;
      _apartmentSeeded = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to history')));
  }

  @override
  Widget build(BuildContext context) {
    final limitsAsync = ref.watch(cardLimitsStreamProvider);
    final ledgersTotal = ref.watch(ledgersTotalProvider);
    final historyAsync = ref.watch(calculatorHistoryStreamProvider);

    final latestHistory = historyAsync.valueOrNull;
    final currentLimits = limitsAsync.valueOrNull;
    if ((!_apartmentSeeded && latestHistory != null) || (!_cardsSeeded && currentLimits != null)) {
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
          if (!_cardsSeeded && currentLimits != null) {
            for (final card in CalculatorCard.values) {
              _cardControllers[card]!.text = _formatSeed(currentLimits[card] ?? card.defaultLimit);
            }
            _cardsSeeded = true;
          }
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculatorHistoryScreen()),
            ),
          ),
        ],
      ),
      body: limitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (limits) {
          final owed = _owedFor(limits);
          final apartment = _parse(_apartmentController);
          final cib = _parse(_cibController);
          final result = calculateCurrentMoney(
            ledgersTotal: ledgersTotal,
            apartmentSavings: apartment,
            cibAccountBalance: cib,
            cardOwed: owed,
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
                    trailing: Text(
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
                  _SignedAmountField(isAddition: false, label: 'Apartment savings', controller: _apartmentController),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'CIB Accounts Balance',
                children: [
                  _SignedAmountField(isAddition: true, label: 'CIB Accounts Balance', controller: _cibController),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Credit cards',
                subtitle: 'Enter the balance still available to spend, as shown in your banking '
                    'app — not what you owe.',
                children: [
                  for (final card in CalculatorCard.values) ...[
                    _CardField(
                      card: card,
                      limit: limits[card] ?? card.defaultLimit,
                      controller: _cardControllers[card]!,
                      owed: owed[card]!,
                    ),
                    if (card != CalculatorCard.values.last) const Divider(height: 28),
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
                            Text(
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
                icon: const Icon(Icons.save),
                label: const Text('Save calculation'),
                onPressed: () => _save(ledgersTotal, limits),
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
            Text(
              formatMoney(result, defaultCurrency),
              style: Theme.of(context).textTheme.headlineMedium,
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
  const _Section({required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
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
  const _SignedAmountField({required this.isAddition, required this.label, required this.controller});

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
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: label, hintText: '0.00'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({required this.card, required this.limit, required this.controller, required this.owed});

  final CalculatorCard card;
  final double limit;
  final TextEditingController controller;
  final double owed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(card.label, style: Theme.of(context).textTheme.titleSmall),
            ),
            Text(
              'Limit ${formatMoney(limit, defaultCurrency)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Available balance', hintText: '0.00'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 6),
        _SignedRow(
          isAddition: false,
          label: 'Owed',
          trailing: Text(formatMoney(owed, defaultCurrency), style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

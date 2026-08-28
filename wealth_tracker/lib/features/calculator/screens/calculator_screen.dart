import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/calculator_input.dart';
import '../../../core/models/currency.dart';
import '../providers/calculator_providers.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _controllers = {for (final key in CalculatorInputKey.values) key: TextEditingController()};
  bool _seeded = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedIfNeeded(Map<CalculatorInputKey, double> inputs) {
    if (_seeded) return;
    for (final entry in inputs.entries) {
      _controllers[entry.key]!.text = _formatInputValue(entry.value);
    }
    _seeded = true;
  }

  static String _formatInputValue(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  Future<void> _save() async {
    final repo = ref.read(calculatorRepositoryProvider);
    for (final entry in _controllers.entries) {
      final value = double.tryParse(entry.value.text.trim());
      if (value != null) {
        await repo.setValue(entry.key, value);
      }
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    final inputsAsync = ref.watch(calculatorInputsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: inputsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (inputs) {
          _seedIfNeeded(inputs);
          final ledgersTotal = ref.watch(ledgersTotalProvider);
          final currentMoney = ref.watch(currentMoneyProvider);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(ledgersTotal: ledgersTotal, currentMoney: currentMoney),
              const SizedBox(height: 24),
              Text('Apartment & CIB', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _AmountField(
                label: CalculatorInputKey.apartmentSavings.label,
                controller: _controllers[CalculatorInputKey.apartmentSavings]!,
              ),
              const SizedBox(height: 12),
              _AmountField(
                label: CalculatorInputKey.cibAccountBalance.label,
                controller: _controllers[CalculatorInputKey.cibAccountBalance]!,
              ),
              const SizedBox(height: 24),
              Text('Credit cards — current balance owed', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final card in CalculatorInputKey.cards) ...[
                _AmountField(
                  label: card.label,
                  helperText: 'Limit ${formatMoney(card.creditLimit!, defaultCurrency)}',
                  controller: _controllers[card]!,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.ledgersTotal, required this.currentMoney});

  final double ledgersTotal;
  final double currentMoney;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ledgers total', style: Theme.of(context).textTheme.bodyMedium),
            Text(formatMoney(ledgersTotal, defaultCurrency), style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 24),
            Text('Current liquid cash', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              formatMoney(currentMoney, defaultCurrency),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.label, required this.controller, this.helperText});

  final String label;
  final TextEditingController controller;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, helperText: helperText, hintText: '0.00'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}

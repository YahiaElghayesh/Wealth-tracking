import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/calculator_card.dart';
import '../../calculator/providers/calculator_providers.dart';

class CardLimitsSettingsScreen extends StatelessWidget {
  const CardLimitsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credit card limits')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: _CardLimitsSection(),
      ),
    );
  }
}

/// Editable here so changing a limit doesn't require an app update — the
/// Calculator tab reads these to work out what's owed on each card from
/// the available-balance figure the user types in there.
class _CardLimitsSection extends ConsumerStatefulWidget {
  const _CardLimitsSection();

  @override
  ConsumerState<_CardLimitsSection> createState() => _CardLimitsSectionState();
}

class _CardLimitsSectionState extends ConsumerState<_CardLimitsSection> {
  final _controllers = {for (final card in CalculatorCard.values) card: TextEditingController()};
  bool _seeded = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _formatValue(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  Future<void> _save(CalculatorCard card) async {
    final value = double.tryParse(_controllers[card]!.text.trim());
    if (value == null) return;
    await ref.read(calculatorRepositoryProvider).setCardLimit(card, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final limitsAsync = ref.watch(cardLimitsStreamProvider);

    return limitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error: $e'),
      data: (limits) {
        if (!_seeded) {
          for (final card in CalculatorCard.values) {
            _controllers[card]!.text = _formatValue(limits[card] ?? card.defaultLimit);
          }
          _seeded = true;
        }
        return ListView(
          children: [
            const Text('Used by the Calculator tab to work out what you owe on each card.'),
            const SizedBox(height: 16),
            for (final card in CalculatorCard.values) ...[
              TextField(
                controller: _controllers[card]!,
                decoration: InputDecoration(
                  labelText: card.label,
                  suffixIcon: IconButton(icon: const Icon(Icons.save), onPressed: () => _save(card)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

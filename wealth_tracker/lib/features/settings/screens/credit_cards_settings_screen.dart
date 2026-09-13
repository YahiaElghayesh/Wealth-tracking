import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/models/supplementary_card_numbers.dart';
import '../../../core/widgets/currency_picker_field.dart';
import '../../../data/db/database.dart';
import '../../calculator/providers/calculator_providers.dart';
import '../providers/sms_rule_providers.dart';
import 'banks_settings_screen.dart';

/// Fully user-managed credit cards for the Calculator tab — add, edit, or
/// remove any number of cards, each with its own name, bank, limit, and
/// currency. Replaces the old fixed three-card setup.
class CreditCardsSettingsScreen extends ConsumerWidget {
  const CreditCardsSettingsScreen({super.key});

  Future<void> _openCardForm(BuildContext context, WidgetRef ref, {CreditCard? existing}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CardFormDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(creditCardsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Credit cards')),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No cards yet. Tap + to add one — used by the Calculator tab.'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, i) {
              final card = cards[i];
              return Dismissible(
                key: ValueKey(card.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete),
                ),
                onDismissed: (_) => ref.read(calculatorRepositoryProvider).deleteCard(card.id),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(card.name),
                    subtitle: Text(
                      '${card.bank}'
                      '${card.lastFourDigits == null ? '' : ' ••${card.lastFourDigits}'}'
                      '${decodeSupplementaryLastFour(card.supplementaryLastFourDigits).map((d) => ' / ••$d').join()}'
                      ' · Limit ${formatMoney(card.limitAmount, card.currency)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openCardForm(context, ref, existing: card),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCardForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CardFormDialog extends ConsumerStatefulWidget {
  const _CardFormDialog({this.existing});

  final CreditCard? existing;

  @override
  ConsumerState<_CardFormDialog> createState() => _CardFormDialogState();
}

class _CardFormDialogState extends ConsumerState<_CardFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  late final TextEditingController _lastFourController;
  late final List<TextEditingController> _supplementaryControllers;
  String? _bank;
  late String _currency;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _bank = existing?.bank;
    _limitController = TextEditingController(text: existing == null ? '' : _formatValue(existing.limitAmount));
    _lastFourController = TextEditingController(text: existing?.lastFourDigits ?? '');
    _supplementaryControllers = decodeSupplementaryLastFour(existing?.supplementaryLastFourDigits)
        .map((d) => TextEditingController(text: d))
        .toList();
    _currency = existing?.currency ?? defaultCurrency;
  }

  static String _formatValue(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _lastFourController.dispose();
    for (final c in _supplementaryControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final bank = _bank;
    if (bank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a bank first')));
      return;
    }
    final name = _nameController.text.trim();
    final limit = double.parse(_limitController.text.trim());
    final lastFour = _lastFourController.text.trim();
    final supplementaryLastFour = encodeSupplementaryLastFour(
      _supplementaryControllers.map((c) => c.text).toList(),
    );

    final repo = ref.read(calculatorRepositoryProvider);
    if (_isEditing) {
      await repo.updateCard(
        widget.existing!.copyWith(
          name: name,
          bank: bank,
          limitAmount: limit,
          currency: _currency,
          lastFourDigits: Value(lastFour.isEmpty ? null : lastFour),
          supplementaryLastFourDigits: Value(supplementaryLastFour),
        ),
      );
    } else {
      await repo.addCard(
        name: name,
        bank: bank,
        limit: limit,
        currency: _currency,
        lastFourDigits: lastFour.isEmpty ? null : lastFour,
        supplementaryLastFourDigits: supplementaryLastFour,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(calculatorRepositoryProvider).deleteCard(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final banks = ref.watch(banksStreamProvider).valueOrNull ?? const [];
    final bankNames = {
      for (final b in banks) b.name,
      // A card's already-saved bank name always stays selectable, even if
      // it's since been renamed/removed from the shared Banks list.
      ?_bank,
    }.toList();

    return AlertDialog(
      title: Text(_isEditing ? 'Edit card' : 'Add card'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Explore World'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if (bankNames.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add a bank first'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BanksSettingsScreen()),
                    ),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: bankNames.contains(_bank) ? _bank : null,
                  decoration: const InputDecoration(labelText: 'Bank'),
                  items: bankNames.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (b) => setState(() => _bank = b),
                  validator: (v) => v == null ? 'Pick a bank' : null,
                ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _limitController,
                      decoration: const InputDecoration(labelText: 'Credit limit'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Enter a number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CurrencyPickerField(
                      value: _currency,
                      labelText: 'Currency',
                      onChanged: (c) => setState(() => _currency = c),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastFourController,
                decoration: const InputDecoration(
                  labelText: 'Last 4 digits (optional)',
                  hintText: 'e.g. 4912',
                  helperText: 'As shown in your bank\'s SMS alerts — "...ending in 4912".',
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!RegExp(r'^\d{4}$').hasMatch(v.trim())) return 'Enter exactly 4 digits';
                  return null;
                },
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Supplementary cards (optional)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Text(
                'Same limit, same balance — an SMS for any of these numbers updates this one card.',
                style: TextStyle(fontSize: 12),
              ),
              for (final (i, controller) in _supplementaryControllers.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: const InputDecoration(labelText: 'Last 4 digits', hintText: 'e.g. 7788'),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            if (!RegExp(r'^\d{4}$').hasMatch(v.trim())) return 'Enter exactly 4 digits';
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Remove',
                        onPressed: () => setState(() {
                          _supplementaryControllers.removeAt(i).dispose();
                        }),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add supplementary card'),
                  onPressed: () => setState(() {
                    _supplementaryControllers.add(TextEditingController());
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

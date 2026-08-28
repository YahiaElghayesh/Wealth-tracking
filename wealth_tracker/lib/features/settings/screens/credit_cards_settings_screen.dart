import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../data/db/database.dart';
import '../../calculator/providers/calculator_providers.dart';

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
                    subtitle: Text('${card.bank} · Limit ${formatMoney(card.limitAmount, card.currency)}'),
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
  late final TextEditingController _bankController;
  late final TextEditingController _limitController;
  late String _currency;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _bankController = TextEditingController(text: existing?.bank ?? '');
    _limitController = TextEditingController(text: existing == null ? '' : _formatValue(existing.limitAmount));
    _currency = existing?.currency ?? defaultCurrency;
  }

  static String _formatValue(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final bank = _bankController.text.trim();
    final limit = double.parse(_limitController.text.trim());

    final repo = ref.read(calculatorRepositoryProvider);
    if (_isEditing) {
      await repo.updateCard(
        widget.existing!.copyWith(name: name, bank: bank, limitAmount: limit, currency: _currency),
      );
    } else {
      await repo.addCard(name: name, bank: bank, limit: limit, currency: _currency);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(calculatorRepositoryProvider).deleteCard(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Explore World'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankController,
                decoration: const InputDecoration(labelText: 'Bank', hintText: 'e.g. CIB'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: supportedCurrencies
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (c) => setState(() => _currency = c!),
                    ),
                  ),
                ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/currency_picker_field.dart';
import '../../../data/db/database.dart';
import '../../calculator/providers/calculator_providers.dart';

/// Fully user-managed one-off +/- amounts for the Calculator tab — each
/// with its own name, sign, fixed amount, and currency, set once here.
/// The Calculator tab itself only ever flips the on/off switch (see
/// ExpectedTransactions' own doc comment in tables.dart); editing the
/// amount always comes back through this screen.
class ExpectedTransactionsSettingsScreen extends ConsumerWidget {
  const ExpectedTransactionsSettingsScreen({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    ExpectedTransaction? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ExpectedTransactionFormDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(expectedTransactionsStreamProvider);
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Expected transactions')),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No expected transactions yet. Tap + to add one — turn '
                  'it on or off from the Calculator tab.',
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, i) {
              final transaction = transactions[i];
              return Dismissible(
                key: ValueKey(transaction.id),
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
                onDismissed: (_) => ref
                    .read(calculatorRepositoryProvider)
                    .deleteExpectedTransaction(transaction.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color:
                            (transaction.isAddition ? colors.good : colors.bad)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        transaction.isAddition ? '+' : '−',
                        style: TextStyle(
                          color: transaction.isAddition
                              ? colors.good
                              : colors.bad,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    title: Text(transaction.name),
                    subtitle: Text(
                      formatMoney(transaction.amount, transaction.currency),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openForm(context, ref, existing: transaction),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExpectedTransactionFormDialog extends ConsumerStatefulWidget {
  const _ExpectedTransactionFormDialog({this.existing});

  final ExpectedTransaction? existing;

  @override
  ConsumerState<_ExpectedTransactionFormDialog> createState() =>
      _ExpectedTransactionFormDialogState();
}

class _ExpectedTransactionFormDialogState
    extends ConsumerState<_ExpectedTransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late bool _isAddition;
  late String _currency;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _amountController = TextEditingController(
      text: existing == null ? '' : _formatValue(existing.amount),
    );
    _isAddition = existing?.isAddition ?? true;
    _currency = existing?.currency ?? defaultCurrency;
  }

  static String _formatValue(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    final repo = ref.read(calculatorRepositoryProvider);
    if (_isEditing) {
      await repo.updateExpectedTransaction(
        widget.existing!.copyWith(
          name: name,
          isAddition: _isAddition,
          amount: amount,
          currency: _currency,
        ),
      );
    } else {
      await repo.addExpectedTransaction(
        name: name,
        isAddition: _isAddition,
        amount: amount,
        currency: _currency,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref
        .read(calculatorRepositoryProvider)
        .deleteExpectedTransaction(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit expected transaction' : 'Add expected transaction',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Freelance payment due',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('− Subtract')),
                  ButtonSegment(value: true, label: Text('+ Add')),
                ],
                selected: {_isAddition},
                onSelectionChanged: (s) =>
                    setState(() => _isAddition = s.first),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) {
                          return 'Enter a number';
                        }
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
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

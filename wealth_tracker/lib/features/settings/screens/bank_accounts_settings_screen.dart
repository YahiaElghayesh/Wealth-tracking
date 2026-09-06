import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../data/db/database.dart';
import '../../calculator/providers/calculator_providers.dart';

/// Fully user-managed bank accounts for the Calculator tab — add, edit, or
/// remove any number of accounts, each with its own name, bank, currency
/// and (optional) account number. Unlike credit cards, a bank account has
/// no limit -- its available balance is straight liquid cash.
class BankAccountsSettingsScreen extends ConsumerWidget {
  const BankAccountsSettingsScreen({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    BankAccount? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _BankAccountFormDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(bankAccountsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bank accounts')),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No bank accounts yet. Tap + to add one — used by the Calculator tab.',
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, i) {
              final account = accounts[i];
              return Dismissible(
                key: ValueKey(account.id),
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
                    .deleteBankAccount(account.id),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(account.name),
                    subtitle: Text(
                      '${account.bank}'
                      '${account.accountNumber == null ? '' : ' •• ${account.accountNumber}'}'
                      ' · ${account.currency}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openForm(context, ref, existing: account),
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

class _BankAccountFormDialog extends ConsumerStatefulWidget {
  const _BankAccountFormDialog({this.existing});

  final BankAccount? existing;

  @override
  ConsumerState<_BankAccountFormDialog> createState() =>
      _BankAccountFormDialogState();
}

class _BankAccountFormDialogState
    extends ConsumerState<_BankAccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bankController;
  late final TextEditingController _accountNumberController;
  late String _currency;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _bankController = TextEditingController(text: existing?.bank ?? '');
    _accountNumberController = TextEditingController(
      text: existing?.accountNumber ?? '',
    );
    _currency = existing?.currency ?? defaultCurrency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final bank = _bankController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    final repo = ref.read(calculatorRepositoryProvider);
    if (_isEditing) {
      await repo.updateBankAccount(
        widget.existing!.copyWith(
          name: name,
          bank: bank,
          currency: _currency,
          accountNumber: Value(accountNumber.isEmpty ? null : accountNumber),
        ),
      );
    } else {
      await repo.addBankAccount(
        name: name,
        bank: bank,
        currency: _currency,
        accountNumber: accountNumber.isEmpty ? null : accountNumber,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref
        .read(calculatorRepositoryProvider)
        .deleteBankAccount(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit bank account' : 'Add bank account'),
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
                  hintText: 'e.g. Main account',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _bankController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Bank',
                        hintText: 'e.g. CIB',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: supportedCurrencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (c) => setState(() => _currency = c!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Account number (optional)',
                ),
                keyboardType: TextInputType.number,
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

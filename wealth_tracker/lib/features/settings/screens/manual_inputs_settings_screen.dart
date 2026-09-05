import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/db/database.dart';
import '../../calculator/providers/calculator_providers.dart';

/// Fully user-managed +/- line items for the Calculator tab — add, edit, or
/// remove any number of them, each with its own name, sign, and currency.
/// Replaces the old fixed "Apartment savings"/"CIB Accounts Balance" pair.
class ManualInputsSettingsScreen extends ConsumerWidget {
  const ManualInputsSettingsScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {ManualInput? existing}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ManualInputFormDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputsAsync = ref.watch(manualInputsStreamProvider);
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Manual inputs')),
      body: inputsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (inputs) {
          if (inputs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No manual inputs yet. Tap + to add one — used by the Calculator tab.'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inputs.length,
            itemBuilder: (context, i) {
              final input = inputs[i];
              return Dismissible(
                key: ValueKey(input.id),
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
                onDismissed: (_) => ref.read(calculatorRepositoryProvider).deleteManualInput(input.id),
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
                        color: (input.isAddition ? colors.good : colors.bad).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        input.isAddition ? '+' : '−',
                        style: TextStyle(
                          color: input.isAddition ? colors.good : colors.bad,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    title: Text(input.name),
                    subtitle: Text(input.currency),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openForm(context, ref, existing: input),
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

class _ManualInputFormDialog extends ConsumerStatefulWidget {
  const _ManualInputFormDialog({this.existing});

  final ManualInput? existing;

  @override
  ConsumerState<_ManualInputFormDialog> createState() => _ManualInputFormDialogState();
}

class _ManualInputFormDialogState extends ConsumerState<_ManualInputFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late bool _isAddition;
  late String _currency;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _isAddition = existing?.isAddition ?? true;
    _currency = existing?.currency ?? defaultCurrency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();

    final repo = ref.read(calculatorRepositoryProvider);
    if (_isEditing) {
      await repo.updateManualInput(
        widget.existing!.copyWith(name: name, isAddition: _isAddition, currency: _currency),
      );
    } else {
      await repo.addManualInput(name: name, isAddition: _isAddition, currency: _currency);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(calculatorRepositoryProvider).deleteManualInput(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit manual input' : 'Add manual input'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Emergency fund'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('− Subtract')),
                  ButtonSegment(value: true, label: Text('+ Add')),
                ],
                selected: {_isAddition},
                onSelectionChanged: (s) => setState(() => _isAddition = s.first),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: supportedCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (c) => setState(() => _currency = c!),
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

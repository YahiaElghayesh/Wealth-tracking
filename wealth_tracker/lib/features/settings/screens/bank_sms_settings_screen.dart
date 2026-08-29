import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/db/database.dart';
import '../../ledger/providers/ledger_providers.dart';
import '../providers/vendor_rule_providers.dart';

/// Enable/disable bank SMS detection and manage the vendor rules that
/// auto-fill a detected charge's ledger and category. See SmsReceiver.kt
/// for why this doesn't depend on a third-party SMS-reading plugin.
class BankSmsSettingsScreen extends ConsumerStatefulWidget {
  const BankSmsSettingsScreen({super.key});

  @override
  ConsumerState<BankSmsSettingsScreen> createState() => _BankSmsSettingsScreenState();
}

class _BankSmsSettingsScreenState extends ConsumerState<BankSmsSettingsScreen> {
  bool _enabled = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _enabled = ref.read(settingsRepositoryProvider).smsCaptureEnabled;
  }

  Future<void> _toggle(bool wantEnabled) async {
    final settings = ref.read(settingsRepositoryProvider);
    if (!wantEnabled) {
      await settings.setSmsCaptureEnabled(false);
      setState(() => _enabled = false);
      return;
    }

    setState(() => _requesting = true);
    final status = await Permission.sms.request();
    await settings.setSmsCaptureEnabled(status.isGranted);
    if (!mounted) return;
    setState(() {
      _enabled = status.isGranted;
      _requesting = false;
    });

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.isPermanentlyDenied
                ? 'SMS permission was denied. Enable it for Money Hub in your phone\'s app settings to turn this on.'
                : 'SMS permission is needed for this to work.',
          ),
        ),
      );
    }
  }

  Future<void> _openRuleForm(BuildContext context, {VendorRule? existing}) {
    return showDialog<void>(
      context: context,
      builder: (context) => _VendorRuleFormDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(vendorRulesStreamProvider);
    final counterparties = ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];
    final counterpartyNames = {for (final c in counterparties) c.id: c.name};

    return Scaffold(
      appBar: AppBar(title: const Text('Bank SMS detection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Detect bank SMS'),
              subtitle: const Text(
                'When your bank texts you about a card charge or payment, this opens a '
                'quick review screen so you can add it to a ledger — nothing is added '
                'without you confirming. Also keeps a matching credit card\'s balance in '
                'Settings > Credit cards up to date automatically, with no confirmation '
                'needed for that part. Needs the sensitive "read SMS" permission to work.',
              ),
              value: _enabled,
              onChanged: _requesting ? null : _toggle,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Vendor rules', style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add rule',
                onPressed: () => _openRuleForm(context),
              ),
            ],
          ),
          Text(
            'When a detected charge\'s merchant matches one of these, the review screen '
            'pre-fills the ledger and category below instead of asking you to pick.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          rulesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => Text('Error: $e'),
            data: (rules) {
              if (rules.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No rules yet — tap + to add one.'),
                );
              }
              return Column(
                children: [
                  for (final rule in rules)
                    Dismissible(
                      key: ValueKey(rule.id),
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
                      onDismissed: (_) => ref.read(vendorRuleRepositoryProvider).deleteRule(rule.id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(rule.vendorPattern),
                          subtitle: Text(
                            '${counterpartyNames[rule.counterpartyId] ?? 'Unknown ledger'} · ${rule.category}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openRuleForm(context, existing: rule),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VendorRuleFormDialog extends ConsumerStatefulWidget {
  const _VendorRuleFormDialog({this.existing});

  final VendorRule? existing;

  @override
  ConsumerState<_VendorRuleFormDialog> createState() => _VendorRuleFormDialogState();
}

class _VendorRuleFormDialogState extends ConsumerState<_VendorRuleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _vendorController;
  String? _counterpartyId;
  String? _category;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _vendorController = TextEditingController(text: existing?.vendorPattern ?? '');
    _counterpartyId = existing?.counterpartyId;
    _category = existing?.category;
  }

  @override
  void dispose() {
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final counterpartyId = _counterpartyId;
    final category = _category;
    if (counterpartyId == null || category == null) return;

    final vendorPattern = _vendorController.text.trim();
    if (_isEditing) {
      await ref.read(vendorRuleRepositoryProvider).updateRule(
            widget.existing!.copyWith(
              vendorPattern: vendorPattern,
              counterpartyId: counterpartyId,
              category: category,
            ),
          );
    } else {
      await ref.read(vendorRuleRepositoryProvider).addRule(
            vendorPattern: vendorPattern,
            counterpartyId: counterpartyId,
            category: category,
          );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(vendorRuleRepositoryProvider).deleteRule(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final counterparties = ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];
    final categories = ref.watch(ledgerCategoriesStreamProvider).valueOrNull ?? const [];

    return AlertDialog(
      title: Text(_isEditing ? 'Edit vendor rule' : 'Add vendor rule'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(
                  labelText: 'Merchant contains',
                  hintText: 'e.g. Breadfast',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: counterparties.any((c) => c.id == _counterpartyId) ? _counterpartyId : null,
                decoration: const InputDecoration(labelText: 'Ledger'),
                items: counterparties.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _counterpartyId = v),
                validator: (v) => v == null ? 'Pick a ledger' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: categories.any((c) => c.name == _category) ? _category : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Pick a category' : null,
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

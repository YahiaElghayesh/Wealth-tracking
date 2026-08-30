import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/settings_action.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../networth/providers/asset_providers.dart' show pricesUsdPerUnitProvider;
import '../providers/ledger_providers.dart';
import '../providers/ledger_shortcut_channel.dart';
import 'counterparty_detail_screen.dart';

class LedgerHomeScreen extends ConsumerWidget {
  const LedgerHomeScreen({super.key});

  Future<void> _addCounterparty(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var includeInStatistics = true;
    var includeInCalculator = true;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add ledger'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Dad'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include in Statistics'),
                value: includeInStatistics,
                onChanged: (v) => setDialogState(() => includeInStatistics = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include in Calculator'),
                value: includeInCalculator,
                onChanged: (v) => setDialogState(() => includeInCalculator = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(ledgerRepositoryProvider).addCounterparty(
            name,
            includeInStatistics: includeInStatistics,
            includeInCalculator: includeInCalculator,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterpartiesAsync = ref.watch(counterpartiesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_home_screen_outlined),
            tooltip: 'Add home screen icon',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _LedgerShortcutPickerDialog(),
            ),
          ),
          const HideValuesAction(),
          const SettingsAction(),
        ],
      ),
      body: counterpartiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (counterparties) {
          if (counterparties.isEmpty) {
            return const Center(child: Text('Add a ledger to start tracking payments.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: counterparties.map((c) => _CounterpartyTile(counterparty: c)).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCounterparty(context, ref),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

/// The explicit "which ledger is this icon for?" prompt -- a per-row pin
/// button (see `_CounterpartyTile`) already implies its own ledger by
/// which row it's on, but this is the dedicated flow for someone who just
/// wants to build up several pinned icons in one sitting without hunting
/// through the list row by row. Stays open after each pin (showing a brief
/// "pinned" state on that row) so tapping several ledgers in a row creates
/// several icons without reopening the dialog each time.
class _LedgerShortcutPickerDialog extends ConsumerStatefulWidget {
  const _LedgerShortcutPickerDialog();

  @override
  ConsumerState<_LedgerShortcutPickerDialog> createState() => _LedgerShortcutPickerDialogState();
}

class _LedgerShortcutPickerDialogState extends ConsumerState<_LedgerShortcutPickerDialog> {
  final _pinning = <String>{};
  final _pinned = <String>{};

  Future<void> _pin(Counterparty counterparty) async {
    setState(() => _pinning.add(counterparty.id));
    final requested = await pinLedgerShortcut(counterpartyId: counterparty.id, name: counterparty.name);
    if (!mounted) return;
    setState(() {
      _pinning.remove(counterparty.id);
      if (requested) _pinned.add(counterparty.id);
    });
    if (!requested) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't request a home-screen icon on this device.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final counterparties = ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];

    return AlertDialog(
      title: const Text('Add home screen icon'),
      content: SizedBox(
        width: double.maxFinite,
        child: counterparties.isEmpty
            ? const Text('Add a ledger first.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Which ledger should this icon open straight to?'),
                    ),
                  ),
                  for (final counterparty in counterparties)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text(counterparty.name.isEmpty ? '?' : counterparty.name[0].toUpperCase())),
                      title: Text(counterparty.name),
                      trailing: _pinning.contains(counterparty.id)
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : _pinned.contains(counterparty.id)
                              ? const Icon(Icons.check_circle)
                              : const Icon(Icons.add_to_home_screen_outlined),
                      onTap: _pinning.contains(counterparty.id) ? null : () => _pin(counterparty),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ],
    );
  }
}

class _CounterpartyTile extends ConsumerWidget {
  const _CounterpartyTile({required this.counterparty});

  final Counterparty counterparty;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: counterparty.name);
    var includeInStatistics = counterparty.includeInStatistics;
    var includeInCalculator = counterparty.includeInCalculator;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit ledger'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include in Statistics'),
                value: includeInStatistics,
                onChanged: (v) => setDialogState(() => includeInStatistics = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include in Calculator'),
                value: includeInCalculator,
                onChanged: (v) => setDialogState(() => includeInCalculator = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    final name = controller.text.trim();
    if (save == true && name.isNotEmpty) {
      await ref.read(ledgerRepositoryProvider).updateCounterparty(
            counterparty.copyWith(
              name: name,
              includeInStatistics: includeInStatistics,
              includeInCalculator: includeInCalculator,
            ),
          );
    }
  }

  /// Requests a pinned home-screen shortcut for this specific ledger --
  /// see ledger_shortcut_channel.dart / LedgerShortcuts.kt. A user can tap
  /// this on as many ledger rows as they want, building up one icon per
  /// ledger, each opening straight to that ledger's add-payment form
  /// instead of the "which ledger?" picker a single generic shortcut can't
  /// avoid.
  Future<void> _pinShortcut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final requested = await pinLedgerShortcut(counterpartyId: counterparty.id, name: counterparty.name);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          requested
              ? 'Check your home screen to confirm adding "${counterparty.name}".'
              : "Couldn't request a home-screen icon on this device.",
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete ledger?'),
            content: Text(
              'This removes "${counterparty.name}" and every payment recorded against it. This can\'t be undone.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await ref.read(ledgerRepositoryProvider).deleteCounterparty(counterparty.id);
    }
    return confirmed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider(counterparty.id));
    final prices = ref.watch(pricesUsdPerUnitProvider);
    final hideValues = ref.watch(hideValuesProvider);
    final transactions = transactionsAsync.valueOrNull;
    final balance = transactions == null ? null : runningBalance(transactions, prices).amount;

    return Dismissible(
      key: ValueKey(counterparty.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, ref),
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.account_balance_wallet_outlined)),
          title: Text(hideValues ? '••••••' : counterparty.name),
          subtitle: hideValues
              ? null
              : balance == null
                  ? const Text('Loading…')
                  : balance == 0
                      ? const Text('Settled up')
                      : Row(
                          children: [
                            Text(balance > 0 ? 'Owes you ' : 'You owe '),
                            Flexible(
                              child: MoneyText(
                                formatMoney(balance.abs(), defaultCurrency),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add_to_home_screen_outlined, size: 20),
                tooltip: 'Pin to home screen',
                onPressed: () => _pinShortcut(context),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
                onPressed: () => _edit(context, ref),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CounterpartyDetailScreen(counterparty: counterparty)),
          ),
        ),
      ),
    );
  }
}

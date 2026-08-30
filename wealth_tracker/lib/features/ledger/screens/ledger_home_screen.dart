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
        actions: const [HideValuesAction(), SettingsAction()],
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

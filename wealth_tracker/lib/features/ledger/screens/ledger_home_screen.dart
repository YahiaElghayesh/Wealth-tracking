import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../networth/providers/asset_providers.dart' show pricesUsdPerUnitProvider;
import '../providers/ledger_providers.dart';
import 'counterparty_detail_screen.dart';

class LedgerHomeScreen extends ConsumerWidget {
  const LedgerHomeScreen({super.key});

  Future<void> _addCounterparty(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add ledger'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Dad'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(ledgerRepositoryProvider).addCounterparty(name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterpartiesAsync = ref.watch(counterpartiesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Debt Ledger'), actions: const [HideValuesAction()]),
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

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: counterparty.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename ledger'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && name != counterparty.name) {
      await ref.read(ledgerRepositoryProvider).renameCounterparty(counterparty.id, name);
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(balance > 0 ? 'Owes you ' : 'You owe '),
                            MoneyText(formatMoney(balance.abs(), defaultCurrency)),
                          ],
                        ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Rename',
                onPressed: () => _rename(context, ref),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
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
        title: const Text('Add person'),
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
      appBar: AppBar(title: const Text('Debt Ledger')),
      body: counterpartiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (counterparties) {
          if (counterparties.isEmpty) {
            return const Center(child: Text('Add a person to start tracking payments.'));
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider(counterparty.id));
    final prices = ref.watch(pricesUsdPerUnitProvider);
    final transactions = transactionsAsync.valueOrNull;
    final balance = transactions == null ? null : runningBalance(transactions, prices).amount;

    return Card(
      child: ListTile(
        title: Text(counterparty.name),
        subtitle: balance == null
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
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CounterpartyDetailScreen(counterparty: counterparty)),
        ),
      ),
    );
  }
}

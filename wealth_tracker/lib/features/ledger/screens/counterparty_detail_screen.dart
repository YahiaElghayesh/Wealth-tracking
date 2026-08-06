import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../providers/ledger_providers.dart';
import 'add_transaction_screen.dart';
import 'monthly_summary_screen.dart';

class CounterpartyDetailScreen extends ConsumerWidget {
  const CounterpartyDetailScreen({super.key, required this.counterparty});

  final Counterparty counterparty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider(counterparty.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(counterparty.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: 'Monthly summary',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MonthlySummaryScreen(counterparty: counterparty)),
            ),
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          final balance = runningBalance(transactions);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Balance'),
                        Text(
                          balance == 0
                              ? 'Settled up'
                              : balance > 0
                                  ? 'Owes you ${formatUsd(balance)}'
                                  : 'You owe ${formatUsd(-balance)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('No entries yet. Tap + to add one.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transactions.length,
                        itemBuilder: (context, i) {
                          final t = transactions[i];
                          return Dismissible(
                            key: ValueKey(t.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Theme.of(context).colorScheme.errorContainer,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete),
                            ),
                            onDismissed: (_) =>
                                ref.read(ledgerRepositoryProvider).deleteTransaction(t.id),
                            child: ListTile(
                              title: Text(t.category),
                              subtitle: Text(
                                '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}'
                                '${t.description == null ? '' : ' · ${t.description}'}',
                              ),
                              trailing: Text(
                                '${t.amount >= 0 ? '+' : '-'}${formatUsd(t.amount.abs())}',
                                style: TextStyle(
                                  color: t.amount >= 0 ? Colors.orange : Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddTransactionScreen(counterpartyId: counterparty.id)),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

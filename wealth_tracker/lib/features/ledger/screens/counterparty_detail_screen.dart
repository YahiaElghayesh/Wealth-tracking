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
import 'add_transaction_screen.dart';
import 'monthly_summary_screen.dart';

class CounterpartyDetailScreen extends ConsumerWidget {
  const CounterpartyDetailScreen({super.key, required this.counterparty});

  final Counterparty counterparty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider(counterparty.id));
    final prices = ref.watch(pricesUsdPerUnitProvider);
    final hideValues = ref.watch(hideValuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hideValues ? '••••••' : counterparty.name),
        actions: [
          const HideValuesAction(),
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
          final balance = runningBalance(transactions, prices).amount;
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
                        balance == 0
                            ? Text('Settled up', style: Theme.of(context).textTheme.titleMedium)
                            : Row(
                                children: [
                                  Text(
                                    balance > 0 ? 'Owes you ' : 'You owe ',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  MoneyText(
                                    formatMoney(balance.abs(), defaultCurrency),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: transactions.length,
                        itemBuilder: (context, i) {
                          final t = transactions[i];
                          final isAddition = t.amount >= 0;
                          final signColor = isAddition ? Colors.green : Colors.red;
                          return Dismissible(
                            key: ValueKey(t.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete),
                            ),
                            onDismissed: (_) =>
                                ref.read(ledgerRepositoryProvider).deleteTransaction(t.id),
                            child: Card(
                              margin: const EdgeInsets.only(top: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: signColor.withValues(alpha: 0.15),
                                  foregroundColor: signColor,
                                  child: Text(
                                    isAddition ? '+' : '−',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(t.category),
                                subtitle: Text(
                                  '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}'
                                  '${t.description == null ? '' : ' · ${t.description}'}',
                                ),
                                trailing: MoneyText(
                                  '${isAddition ? '+' : '−'}${formatMoney(t.amount.abs(), t.currency)}',
                                  style: TextStyle(color: signColor, fontWeight: FontWeight.bold),
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

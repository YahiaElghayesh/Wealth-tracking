import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../data/db/database.dart';
import '../../../data/repositories/calculator_repository.dart';
import '../providers/calculator_providers.dart';

class CalculatorHistoryScreen extends ConsumerWidget {
  const CalculatorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(calculatorHistoryStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calculation history')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (snapshots) {
          if (snapshots.isEmpty) {
            return const Center(child: Text('No saved calculations yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshots.length,
            itemBuilder: (context, i) => _SnapshotCard(snapshot: snapshots[i]),
          );
        },
      ),
    );
  }
}

class _SnapshotCard extends ConsumerWidget {
  const _SnapshotCard({required this.snapshot});

  final CalculatorSnapshot snapshot;

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customItems = snapshot.customItems;

    return Dismissible(
      key: ValueKey(snapshot.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete),
      ),
      onDismissed: (_) => ref.read(calculatorRepositoryProvider).deleteSnapshot(snapshot.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ExpansionTile(
          title: Text(
            formatMoney(snapshot.resultAmount, defaultCurrency),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(_formatDate(snapshot.computedAt)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _BreakdownRow(isAddition: true, label: 'Ledgers', amount: snapshot.ledgersTotal),
            _BreakdownRow(isAddition: false, label: 'Apartment savings', amount: snapshot.apartmentSavings),
            _BreakdownRow(isAddition: true, label: 'CIB account balance', amount: snapshot.cibAccountBalance),
            _BreakdownRow(isAddition: false, label: 'NBE Wallet owed', amount: snapshot.nbeOwed),
            _BreakdownRow(
              isAddition: false,
              label: 'CIB Explorer Wallet owed',
              amount: snapshot.cibExplorerWalletOwed,
            ),
            _BreakdownRow(isAddition: false, label: 'CIB Platinum owed', amount: snapshot.cibPlatinumOwed),
            for (final item in customItems)
              _BreakdownRow(isAddition: item.isAddition, label: item.label, amount: item.amount),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.isAddition, required this.label, required this.amount});

  final bool isAddition;
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final color = isAddition ? Colors.green : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(isAddition ? '+' : '−', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(formatMoney(amount, defaultCurrency)),
        ],
      ),
    );
  }
}

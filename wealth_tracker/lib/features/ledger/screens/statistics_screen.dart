import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../networth/providers/asset_providers.dart' show pricesUsdPerUnitProvider;
import '../providers/ledger_providers.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String? _selectedCounterpartyId;

  @override
  Widget build(BuildContext context) {
    final counterpartiesAsync = ref.watch(counterpartiesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: counterpartiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (counterparties) {
          if (counterparties.isEmpty) {
            return const Center(child: Text('Add a person in the Ledger tab to see statistics.'));
          }

          final selected = counterparties.any((c) => c.id == _selectedCounterpartyId)
              ? _selectedCounterpartyId!
              : counterparties.first.id;

          return Column(
            children: [
              if (counterparties.length > 1)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    initialValue: selected,
                    decoration: const InputDecoration(labelText: 'Person'),
                    items: counterparties
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (id) => setState(() => _selectedCounterpartyId = id),
                  ),
                ),
              Expanded(child: _StatisticsBody(counterpartyId: selected)),
            ],
          );
        },
      ),
    );
  }
}

class _StatisticsBody extends ConsumerWidget {
  const _StatisticsBody({required this.counterpartyId});

  final String counterpartyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider(counterpartyId));
    final prices = ref.watch(pricesUsdPerUnitProvider);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(child: Text('No entries yet.'));
        }

        final trend = monthlySpendTrend(transactions, prices, months: 6);
        final categoryTotals = categoryTotalsAllTime(transactions, prices);
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final maxCategoryAmount =
            sortedCategories.isEmpty ? 0.0 : sortedCategories.first.value;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Spend by month', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(height: 220, child: _MonthlyTrendChart(trend: trend)),
            const SizedBox(height: 32),
            Text('By category (all time)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (sortedCategories.isEmpty)
              const Text('No expenses recorded yet.')
            else
              ...sortedCategories.map(
                (entry) => _CategoryBar(
                  category: entry.key,
                  amount: entry.value,
                  maxAmount: maxCategoryAmount,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.trend});

  final List<MonthlySpend> trend;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final maxY = trend.map((m) => m.amount).fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.MMM().format(trend[index].month),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                formatMoney(rod.toY, defaultCurrency),
                TextStyle(color: color, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < trend.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: trend[i].amount,
                  color: color,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.category, required this.amount, required this.maxAmount});

  final String category;
  final double amount;
  final double maxAmount;

  @override
  Widget build(BuildContext context) {
    final fraction = maxAmount == 0 ? 0.0 : (amount / maxAmount).clamp(0.0, 1.0);
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: Theme.of(context).textTheme.bodyMedium),
              Text(formatMoney(amount, defaultCurrency), style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

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
                    isExpanded: true,
                    initialValue: selected,
                    decoration: const InputDecoration(labelText: 'Ledger'),
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

class _StatisticsBody extends ConsumerStatefulWidget {
  const _StatisticsBody({required this.counterpartyId});

  final String counterpartyId;

  @override
  ConsumerState<_StatisticsBody> createState() => _StatisticsBodyState();
}

class _StatisticsBodyState extends ConsumerState<_StatisticsBody> {
  /// Last 12 months (this month first), newest first — what the chip row offers.
  static List<DateTime> _recentMonths() {
    final now = DateTime.now();
    return [for (var i = 0; i < 12; i++) DateTime(now.year, now.month - i)];
  }

  late Set<DateTime> _selectedMonths = {DateTime(DateTime.now().year, DateTime.now().month)};

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider(widget.counterpartyId));
    final prices = ref.watch(pricesUsdPerUnitProvider);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(child: Text('No entries yet.'));
        }

        final trend = monthlySpendTrend(transactions, prices, months: 6);
        final categoryTotals = categoryTotalsForMonths(transactions, _selectedMonths, prices);
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Spend by month', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(height: 220, child: _MonthlyTrendChart(trend: trend)),
            const SizedBox(height: 32),
            Text('By category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentMonths().map((month) {
                final selected = _selectedMonths.any(
                  (m) => m.year == month.year && m.month == month.month,
                );
                return FilterChip(
                  label: Text(DateFormat.MMM().format(month)),
                  selected: selected,
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        _selectedMonths = {..._selectedMonths, month};
                      } else {
                        _selectedMonths = _selectedMonths
                            .where((m) => !(m.year == month.year && m.month == month.month))
                            .toSet();
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (sortedCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No expenses in the selected month(s).'),
              )
            else
              _CategoryPieChart(categories: sortedCategories),
          ],
        );
      },
    );
  }
}

/// Compact money label used above bars — a shortened form (e.g. "1.2K")
/// keeps labels legible when several bars sit close together.
String _shortMoney(double value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 1000000) return '$sign${(abs / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(1)}K';
  return formatMoney(value, defaultCurrency);
}

/// A permanently-visible label above a bar, using the same tooltip
/// machinery fl_chart uses for touch — [BarChartGroupData.showingTooltipIndicators]
/// keeps it displayed without requiring a tap.
BarTouchTooltipData _permanentLabelTooltip(Color textColor) {
  return BarTouchTooltipData(
    getTooltipColor: (_) => Colors.transparent,
    tooltipPadding: EdgeInsets.zero,
    tooltipMargin: 8,
    fitInsideVertically: true,
    getTooltipItem: (group, groupIndex, rod, rodIndex) {
      return BarTooltipItem(
        _shortMoney(rod.toY),
        TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11),
      );
    },
  );
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
        maxY: maxY == 0 ? 1 : maxY * 1.3,
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
        barTouchData: BarTouchData(touchTooltipData: _permanentLabelTooltip(color)),
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
              showingTooltipIndicators: trend[i].amount > 0 ? [0] : [],
            ),
        ],
      ),
    );
  }
}

/// Category breakdown as a pie chart with a colored legend underneath —
/// the legend carries the readable category name + amount since slice
/// labels alone get illegible once there are more than a few categories.
class _CategoryPieChart extends StatefulWidget {
  const _CategoryPieChart({required this.categories});

  final List<MapEntry<String, double>> categories;

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  static const _palette = [
    Color(0xFF2E7D6B),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFFF8F00),
    Color(0xFFC62828),
    Color(0xFF00838F),
    Color(0xFF9E9D24),
    Color(0xFF4527A0),
    Color(0xFFAD1457),
    Color(0xFF37474F),
  ];

  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories;
    final total = categories.fold(0.0, (sum, e) => sum + e.value);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions || response?.touchedSection == null) {
                      _touchedIndex = null;
                    } else {
                      _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
              sections: [
                for (var i = 0; i < categories.length; i++)
                  PieChartSectionData(
                    value: categories[i].value,
                    color: _palette[i % _palette.length],
                    radius: i == _touchedIndex ? 74 : 66,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (var i = 0; i < categories.length; i++)
              _LegendEntry(
                color: _palette[i % _palette.length],
                label: categories[i].key,
                amount: categories[i].value,
                percent: total == 0 ? 0 : categories[i].value / total,
                highlighted: i == _touchedIndex,
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.amount,
    required this.percent,
    required this.highlighted,
  });

  final Color color;
  final String label;
  final double amount;
  final double percent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$label  ', style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '${formatMoney(amount, defaultCurrency)} (${(percent * 100).toStringAsFixed(0)}%)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

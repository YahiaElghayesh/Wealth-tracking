import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/net_worth/net_worth_calculator.dart';

class NetWorthSummaryCard extends StatelessWidget {
  const NetWorthSummaryCard({
    super.key,
    required this.summary,
    required this.usdToEgpRate,
  });

  final NetWorthSummary summary;

  /// Null while the FX rate hasn't been fetched yet — EGP figures are
  /// hidden in that case rather than shown as a misleading zero.
  final double? usdToEgpRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final egpTotal = usdToEgpRate == null ? null : summary.totalUsd * usdToEgpRate!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Net Worth', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            MoneyText(formatUsd(summary.totalUsd), style: theme.textTheme.headlineMedium, maskLength: 9),
            if (egpTotal != null) MoneyText(formatEgp(egpTotal), style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
            if (summary.totalUsd > 0)
              SizedBox(
                height: 120,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          sections: [
                            PieChartSectionData(
                              value: summary.liquidUsd,
                              color: theme.colorScheme.primary,
                              title: '',
                              radius: 20,
                            ),
                            PieChartSectionData(
                              value: summary.nonLiquidUsd,
                              color: theme.colorScheme.tertiary,
                              title: '',
                              radius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendRow(
                            color: theme.colorScheme.primary,
                            label: 'Liquid',
                            valueUsd: summary.liquidUsd,
                          ),
                          const SizedBox(height: 8),
                          _LegendRow(
                            color: theme.colorScheme.tertiary,
                            label: 'Non-liquid',
                            valueUsd: summary.nonLiquidUsd,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text('Add an asset to see your net worth breakdown.'),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.valueUsd});

  final Color color;
  final String label;
  final double valueUsd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              MoneyText(formatUsd(valueUsd), style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

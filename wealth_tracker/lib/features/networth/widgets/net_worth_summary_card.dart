import 'package:flutter/material.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/net_worth/net_worth_calculator.dart';

/// The mockup's "hero-total" card: label, big EGP/USD total on one
/// baseline, a liquid/non-liquid split bar, and a two-sided legend showing
/// both the percent and the actual value on each side -- replacing the
/// previous pie-chart layout, which the approved redesign doesn't use here.
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
    final colors = context.appColors;
    final egpTotal = usdToEgpRate == null ? null : summary.totalUsd * usdToEgpRate!;
    final total = summary.liquidUsd + summary.nonLiquidUsd;
    final liquidFraction = total <= 0 ? 0.0 : summary.liquidUsd / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL NET WORTH',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textDim,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          MoneyText(
            egpTotal == null ? '—' : formatEgp(egpTotal),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            maskLength: 9,
          ),
          const SizedBox(height: 2),
          MoneyText(
            '≈ ${formatUsd(summary.totalUsd)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.textDim),
            maskLength: 5,
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    Expanded(
                      flex: (liquidFraction * 1000).round().clamp(1, 999),
                      child: Container(color: theme.colorScheme.primary),
                    ),
                    Expanded(
                      flex: ((1 - liquidFraction) * 1000).round().clamp(1, 999),
                      child: Container(color: colors.gold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SplitSide(
                    label: 'Liquid',
                    fraction: liquidFraction,
                    valueUsd: summary.liquidUsd,
                    usdToEgpRate: usdToEgpRate,
                    alignEnd: false,
                  ),
                ),
                Expanded(
                  child: _SplitSide(
                    label: 'Non-liquid',
                    fraction: 1 - liquidFraction,
                    valueUsd: summary.nonLiquidUsd,
                    usdToEgpRate: usdToEgpRate,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              'Add an asset to see your net worth breakdown.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.textDim),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplitSide extends StatelessWidget {
  const _SplitSide({
    required this.label,
    required this.fraction,
    required this.valueUsd,
    required this.usdToEgpRate,
    required this.alignEnd,
  });

  final String label;
  final double fraction;
  final double valueUsd;
  final double? usdToEgpRate;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final egpValue = usdToEgpRate == null ? null : valueUsd * usdToEgpRate!;
    final pct = '${(fraction * 100).round()}%';
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignEnd) ...[
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colors.textDim)),
              const SizedBox(width: 4),
            ],
            MoneyText(pct, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700), maskLength: 3),
            if (alignEnd) ...[
              const SizedBox(width: 4),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colors.textDim)),
            ],
          ],
        ),
        const SizedBox(height: 1),
        MoneyText(
          egpValue == null ? '—' : formatEgp(egpValue),
          style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim),
          maskLength: 7,
        ),
        MoneyText(
          '≈ ${formatUsd(valueUsd)}',
          style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontSize: 10.5),
          maskLength: 5,
        ),
      ],
    );
  }
}

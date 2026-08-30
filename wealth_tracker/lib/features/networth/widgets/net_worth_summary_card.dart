import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/net_worth/net_worth_calculator.dart';
import '../../calculator/providers/calculator_providers.dart';

/// The mockup's "hero-total" card: label, big EGP/USD total on one
/// baseline, a liquid/current/non-liquid split bar, and a legend row below
/// it -- replacing the previous pie-chart layout, which the approved
/// redesign doesn't use here. When a Calculator snapshot exists, the
/// Calculator's last saved "current liquid cash" result is folded in as a
/// real third slice of the total (both the headline number and the bar
/// itself), not just a decorative readout beside it -- it's the actual
/// spendable cash a Liquid asset total alone doesn't capture (nets
/// ledgers, card debt, and manual inputs, none of which are tracked as
/// Net Worth assets), so leaving it out of the total would understate net
/// worth by exactly that amount.
class NetWorthSummaryCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final calculatorHistory = ref.watch(calculatorHistoryStreamProvider).valueOrNull;
    final latestSnapshot = (calculatorHistory == null || calculatorHistory.isEmpty) ? null : calculatorHistory.first;

    // The Calculator snapshot is saved in EGP (its native settlement
    // currency); everything else here is USD-denominated, so it needs
    // converting before it can join the same total -- skipped (rather than
    // shown as a misleading zero) whenever the FX rate isn't known yet.
    final currentUsd = (latestSnapshot != null && usdToEgpRate != null && usdToEgpRate! > 0)
        ? latestSnapshot.resultAmount / usdToEgpRate!
        : null;

    final total = summary.liquidUsd + summary.nonLiquidUsd + (currentUsd ?? 0);
    final egpTotal = usdToEgpRate == null ? null : total * usdToEgpRate!;
    final liquidFraction = total <= 0 ? 0.0 : summary.liquidUsd / total;
    final currentFraction = total <= 0 ? 0.0 : (currentUsd ?? 0) / total;
    final nonLiquidFraction = total <= 0 ? 0.0 : summary.nonLiquidUsd / total;

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
            egpTotal == null ? '—' : formatEgpWhole(egpTotal),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            maskLength: 9,
          ),
          const SizedBox(height: 2),
          MoneyText(
            '≈ ${formatUsdWhole(total)}',
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
                    if (currentUsd != null && currentUsd > 0)
                      Expanded(
                        flex: (currentFraction * 1000).round().clamp(1, 999),
                        child: Container(color: colors.good),
                      ),
                    Expanded(
                      flex: (nonLiquidFraction * 1000).round().clamp(1, 999),
                      child: Container(color: colors.gold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SplitSide(
                    label: 'Liquid',
                    fraction: liquidFraction,
                    valueUsd: summary.liquidUsd,
                    usdToEgpRate: usdToEgpRate,
                    alignment: CrossAxisAlignment.start,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (currentUsd != null)
                  Expanded(
                    child: _CurrentSide(
                      resultEgp: latestSnapshot!.resultAmount,
                      fraction: currentFraction,
                      usdToEgpRate: usdToEgpRate,
                      color: colors.good,
                    ),
                  ),
                Expanded(
                  child: _SplitSide(
                    label: 'Non-liquid',
                    fraction: nonLiquidFraction,
                    valueUsd: summary.nonLiquidUsd,
                    usdToEgpRate: usdToEgpRate,
                    alignment: CrossAxisAlignment.end,
                    color: colors.gold,
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

/// The Calculator tab's last saved "current liquid cash" result, in EGP
/// (its native settlement currency) and derived USD -- now a genuine third
/// slice of the total net worth (see [NetWorthSummaryCard]'s own doc
/// comment), so this shows a percentage the same way [_SplitSide] does for
/// Liquid/Non-liquid, just centered between them instead of left/right
/// aligned.
class _CurrentSide extends StatelessWidget {
  const _CurrentSide({
    required this.resultEgp,
    required this.fraction,
    required this.usdToEgpRate,
    required this.color,
  });

  final double resultEgp;
  final double fraction;
  final double? usdToEgpRate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final resultUsd = usdToEgpRate == null || usdToEgpRate == 0 ? null : resultEgp / usdToEgpRate!;
    final pct = '${(fraction * 100).round()}%';
    return _LegendBox(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calculate_outlined, size: 12, color: colors.good),
              const SizedBox(width: 3),
              Text('Current', style: theme.textTheme.bodySmall?.copyWith(color: colors.textDim)),
              const SizedBox(width: 4),
              MoneyText(pct, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700), maskLength: 3),
            ],
          ),
          const SizedBox(height: 1),
          MoneyText(
            formatEgpWhole(resultEgp),
            style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontWeight: FontWeight.w700),
            maskLength: 7,
          ),
          MoneyText(
            resultUsd == null ? '—' : '≈ ${formatUsdWhole(resultUsd)}',
            style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontSize: 10.5),
            maskLength: 5,
          ),
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
    required this.alignment,
    required this.color,
  });

  final String label;
  final double fraction;
  final double valueUsd;
  final double? usdToEgpRate;
  final CrossAxisAlignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final egpValue = usdToEgpRate == null ? null : valueUsd * usdToEgpRate!;
    final pct = '${(fraction * 100).round()}%';
    final alignEnd = alignment == CrossAxisAlignment.end;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        _LegendBox(
          color: color,
          child: Column(
            crossAxisAlignment: alignment,
            mainAxisSize: MainAxisSize.min,
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
                egpValue == null ? '—' : formatEgpWhole(egpValue),
                style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim),
                maskLength: 7,
              ),
              MoneyText(
                '≈ ${formatUsdWhole(valueUsd)}',
                style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontSize: 10.5),
                maskLength: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared tinted-box look behind each legend entry below the split bar --
/// [color] matches that entry's own segment in the bar above it (primary
/// for Liquid, [AppColors.good] for Current, [AppColors.gold] for
/// Non-liquid), so the legend visually keys to the bar instead of relying
/// on position/reading order alone.
class _LegendBox extends StatelessWidget {
  const _LegendBox({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

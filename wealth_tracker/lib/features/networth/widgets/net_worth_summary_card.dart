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
            // Stacked full-width rows instead of three side-by-side boxes
            // sharing a third of the card's width each -- squeezed that
            // tight, a long value ("EGP 1,236,882" next to "≈ $24,614")
            // had nowhere to go but overflow past its box's edge (the
            // "white line" a screenshot showed: Flutter's own render
            // overflow indicator). Full width also makes "equal size" a
            // non-issue -- every row is exactly the card's width, so none
            // can be smaller than another -- and gives every row the same
            // label-then-percent-then-values order, left to right.
            _LegendRow(
              icon: Icons.water_drop_outlined,
              label: 'Liquid',
              fraction: liquidFraction,
              egpValue: usdToEgpRate == null ? null : summary.liquidUsd * usdToEgpRate!,
              usdValue: summary.liquidUsd,
              color: theme.colorScheme.primary,
            ),
            if (currentUsd != null) ...[
              const SizedBox(height: 8),
              _LegendRow(
                icon: Icons.calculate_outlined,
                label: 'Current',
                fraction: currentFraction,
                egpValue: latestSnapshot!.resultAmount,
                usdValue: currentUsd,
                color: colors.good,
              ),
            ],
            const SizedBox(height: 8),
            _LegendRow(
              icon: Icons.savings_outlined,
              label: 'Non-liquid',
              fraction: nonLiquidFraction,
              egpValue: usdToEgpRate == null ? null : summary.nonLiquidUsd * usdToEgpRate!,
              usdValue: summary.nonLiquidUsd,
              color: colors.gold,
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

/// One full-width legend row below the split bar -- shared by Liquid,
/// Current, and Non-liquid so all three are visually identical apart from
/// their icon/label/color: same left-to-right order (icon, label,
/// percentage, then the EGP/USD figures pinned to the right), same box
/// style tinted to match that entry's own segment in the bar above it.
/// Being the card's full width rather than one of three squeezed side by
/// side, no value here is ever tight enough to wrap or overflow, and
/// every row is trivially the same size as the others.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.icon,
    required this.label,
    required this.fraction,
    required this.egpValue,
    required this.usdValue,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double fraction;

  /// Null when the FX rate isn't known yet -- shown as "—" rather than a
  /// misleading zero.
  final double? egpValue;
  final double usdValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final pct = '${(fraction * 100).round()}%';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.textDim),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          MoneyText(pct, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700), maskLength: 3),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(
                egpValue == null ? '—' : formatEgpWhole(egpValue!),
                style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontWeight: FontWeight.w700),
                maskLength: 7,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              MoneyText(
                '≈ ${formatUsdWhole(usdValue)}',
                style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontSize: 10.5),
                maskLength: 5,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/money_text.dart';
import '../providers/recurring_payment_providers.dart';

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// One bar's worth of data -- either an auto-recorded past month (see
/// [RecurringPaymentHistoryRepository]) or the current, still-live month
/// (computed the same way the tab's own total card is, so the bar for
/// "now" always matches what that card currently shows).
class _MonthPoint {
  const _MonthPoint({
    required this.year,
    required this.month,
    required this.total,
    required this.paid,
  });

  final int year;
  final int month;
  final double total;
  final double paid;
}

/// Auto-generated month-by-month history for the Recurring Payments tab --
/// mirrors Ledger Statistics' "Spend by month" chart (same bar styling: a
/// visible track under every month, a full-strength color and a value
/// label on every bar that actually carries an amount, not just the most
/// recent one) plus a plain list underneath for exact figures.
class RecurringPaymentHistoryScreen extends ConsumerWidget {
  const RecurringPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(recurringPaymentHistoryStreamProvider);
    final liveSummary = ref.watch(recurringPaymentsMonthSummaryProvider);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring payments history')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (history) {
          final points = [
            for (final entry in history)
              _MonthPoint(
                year: entry.year,
                month: entry.month,
                total: entry.totalAmount,
                paid: entry.paidAmount,
              ),
            // The current month is never itself in the recorded history
            // (it only gets recorded once it's over) -- appended live here
            // so the chart always ends with "now" instead of stopping one
            // month short.
            _MonthPoint(
              year: today.year,
              month: today.month,
              total: liveSummary.total,
              paid: liveSummary.paid,
            ),
          ];

          if (points.length == 1) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'History fills in automatically once a month ends -- '
                  'come back after your first full month of recurring '
                  'payments.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total by month',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _MonthlyHistoryChart(points: points),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final point in points.reversed)
                _MonthHistoryTile(point: point),
            ],
          );
        },
      ),
    );
  }
}

/// Whether [points] spans more than one calendar year -- when it does,
/// every month label also carries a 2-digit year so a run like
/// "...Nov Dec Jan Feb..." doesn't read as one ambiguous year.
bool _spansMultipleYears(List<_MonthPoint> points) {
  if (points.isEmpty) return false;
  final years = points.map((p) => p.year).toSet();
  return years.length > 1;
}

String _monthLabel(_MonthPoint point, bool showYear) {
  final month = _monthNames[point.month - 1];
  return showYear
      ? "$month '${(point.year % 100).toString().padLeft(2, '0')}"
      : month;
}

class _MonthlyHistoryChart extends ConsumerWidget {
  const _MonthlyHistoryChart({required this.points});

  final List<_MonthPoint> points;

  static const _barAreaHeight = 170.0;
  static const _barWidth = 22.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideValues = ref.watch(hideValuesProvider);
    final color = Theme.of(context).colorScheme.primary;
    final colors = context.appColors;
    final maxValue = points
        .map((p) => p.total)
        .fold(0.0, (a, b) => a > b ? a : b);
    final showYear = _spansMultipleYears(points);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _barAreaHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points)
                Expanded(
                  child: Center(
                    child: _HistoryBar(
                      value: point.total,
                      maxValue: maxValue,
                      areaHeight: _barAreaHeight,
                      width: _barWidth,
                      barColor: color,
                      trackColor: colors.surface2,
                      hideValues: hideValues,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final point in points)
              Expanded(
                child: Center(
                  child: Text(
                    _monthLabel(point, showYear),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: colors.textDim),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Same bar-rendering approach as Ledger Statistics' `_MonthBar` -- a
/// literal child of the bar's own `Container`, clipped to it, so the
/// value label can never be anything other than genuinely inside the bar.
class _HistoryBar extends StatelessWidget {
  const _HistoryBar({
    required this.value,
    required this.maxValue,
    required this.areaHeight,
    required this.width,
    required this.barColor,
    required this.trackColor,
    required this.hideValues,
  });

  final double value;
  final double maxValue;
  final double areaHeight;
  final double width;
  final Color barColor;
  final Color trackColor;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final rawHeight = maxValue <= 0 ? 0.0 : (value / maxValue) * areaHeight;
    final hasValue = value > 0;
    final showsLabel = hasValue && !hideValues;
    final barHeight =
        (hasValue
                ? rawHeight.clamp(44.0, areaHeight)
                : rawHeight.clamp(4.0, areaHeight))
            .toDouble();

    return SizedBox(
      width: width,
      height: areaHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            child: Container(
              height: barHeight,
              color: barColor,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 4),
              child: showsLabel
                  ? RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        _shortMoney(value),
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    )
                  : (hasValue && hideValues)
                  ? const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        '•••',
                        style: TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

String _shortMoney(double value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 1000000) return '$sign${(abs / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(1)}K';
  return '$sign${abs.round()}';
}

class _MonthHistoryTile extends ConsumerWidget {
  const _MonthHistoryTile({required this.point});

  final _MonthPoint point;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final hideValues = ref.watch(hideValuesProvider);
    final now = DateTime.now();
    final isCurrentMonth = point.year == now.year && point.month == now.month;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${_monthNames[point.month - 1]} ${point.year}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isCurrentMonth) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'IN PROGRESS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  formatMoney(point.total, defaultCurrency),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maskLength: 8,
                ),
                Text(
                  hideValues
                      ? '••••'
                      : 'Paid ${formatMoney(point.paid, defaultCurrency)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textDim,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

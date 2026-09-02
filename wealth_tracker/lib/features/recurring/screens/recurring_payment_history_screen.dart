import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/models/recurring_payment_history_item.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/repositories/recurring_payment_history_repository.dart'
    show RecurringPaymentHistoryDataItems;
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

/// One past (or the current, still-live) month's totals -- either an
/// auto-recorded row (see [RecurringPaymentHistoryRepository]) or the
/// current month, computed the same way the tab's own total card is, so
/// this list always ends with "now" instead of stopping one month short.
class _MonthPoint {
  const _MonthPoint({
    required this.year,
    required this.month,
    required this.total,
    required this.paid,
    required this.items,
    required this.itemsAreLegacyMissing,
  });

  final int year;
  final int month;
  final double total;
  final double paid;

  /// Which specific payments made up [total]/[paid] -- empty (with
  /// [itemsAreLegacyMissing] true) for a month recorded before this
  /// breakdown existed.
  final List<RecurringPaymentHistoryItem> items;
  final bool itemsAreLegacyMissing;
}

/// Auto-generated month-by-month history for the Recurring Payments tab --
/// a plain list of each month's total, its paid/pending breakdown, and
/// which specific payments were paid vs. still pending that month, no
/// chart (the tab's own total card already covers "how are we doing right
/// now" visually; this screen is for looking back at exact past figures).
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
                items: entry.items,
                itemsAreLegacyMissing: entry.itemsAreLegacyMissing,
              ),
            _MonthPoint(
              year: today.year,
              month: today.month,
              total: liveSummary.total,
              paid: liveSummary.paid,
              items: liveSummary.items,
              itemsAreLegacyMissing: false,
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
              for (final point in points.reversed)
                _MonthHistoryTile(point: point),
            ],
          );
        },
      ),
    );
  }
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

    final pending = point.total - point.paid;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                MoneyText(
                  formatMoney(point.total, defaultCurrency),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maskLength: 8,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _BreakdownStat(
                    label: 'Paid',
                    amount: point.paid,
                    color: colors.good,
                    hideValues: hideValues,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BreakdownStat(
                    label: 'Pending',
                    amount: pending,
                    color: colors.textDim,
                    hideValues: hideValues,
                  ),
                ),
              ],
            ),
            if (point.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              for (final item in point.items)
                _ItemRow(item: item, hideValues: hideValues),
            ] else if (point.itemsAreLegacyMissing) ...[
              const SizedBox(height: 10),
              Text(
                'Item breakdown not available for this month.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textDim,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One payment's name, amount, and paid/pending state within a month's
/// tile -- a plain colored dot rather than a full badge (unlike the main
/// tab's own tile, this is a dense list of every payment in the month, not
/// one payment given a whole card's worth of space).
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.hideValues});

  final RecurringPaymentHistoryItem item;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final color = item.paid ? colors.good : colors.textDim;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              hideValues ? '••••••' : item.name,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.paid ? 'Paid' : 'Pending',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          MoneyText(
            formatMoney(item.amount, defaultCurrency),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maskLength: 7,
          ),
        ],
      ),
    );
  }
}

class _BreakdownStat extends StatelessWidget {
  const _BreakdownStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.hideValues,
  });

  final String label;
  final double amount;
  final Color color;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textDim,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          MoneyText(
            hideValues ? '••••' : formatMoney(amount, defaultCurrency),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
            maskLength: 7,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/recurring_payment_frequency.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/settings_action.dart';
import '../../../data/db/database.dart';
import '../../../data/recurring/recurring_payment_due.dart';
import '../../networth/providers/asset_providers.dart'
    show usdToEgpRateProvider;
import '../providers/recurring_payment_providers.dart';
import 'add_recurring_payment_screen.dart';
import 'recurring_payment_history_screen.dart';

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

/// The "Recurring payments" tab -- monthly bills/subscriptions (Netflix,
/// YouTube, Amazon Prime, ...) and yearly ones (a domain renewal, an
/// annual membership) tracked and totaled the same way the Calculator tab
/// totals cards and manual inputs: a sticky total up top, split into two
/// collapsible sections below it.
class RecurringPaymentsScreen extends ConsumerStatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  ConsumerState<RecurringPaymentsScreen> createState() =>
      _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState
    extends ConsumerState<RecurringPaymentsScreen> {
  /// Both sections start collapsed, behind just their summary header --
  /// same convention as the Net Worth tab's per-category sections.
  bool _monthlyExpanded = false;
  bool _yearlyExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Fire-and-forget: auto-records last month's totals into history the
    // moment the calendar has moved past it -- see that provider's own
    // doc comment.
    ref.watch(recurringPaymentHistoryAutoRecordProvider);
    final paymentsAsync = ref.watch(recurringPaymentsStreamProvider);
    final summary = ref.watch(recurringPaymentsMonthSummaryProvider);
    final usdToEgpRate = ref.watch(usdToEgpRateProvider);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RecurringPaymentHistoryScreen(),
              ),
            ),
          ),
          const HideValuesAction(),
          const SettingsAction(),
        ],
      ),
      body: Column(
        children: [
          _TotalCard(summary: summary, usdToEgpRate: usdToEgpRate),
          Expanded(
            child: paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (payments) {
                if (payments.isEmpty) {
                  return const Center(
                    child: Text('Tap + to add your first recurring payment.'),
                  );
                }
                final monthly = <RecurringPayment>[];
                final yearly = <RecurringPayment>[];
                for (final payment in payments) {
                  final frequency = RecurringPaymentFrequency.fromStored(
                    payment.frequency,
                  );
                  if (frequency == RecurringPaymentFrequency.yearly) {
                    yearly.add(payment);
                  } else {
                    monthly.add(payment);
                  }
                }
                int byOccurrence(RecurringPayment a, RecurringPayment b) {
                  return recurringPaymentOccurrenceDate(
                    a,
                    today,
                  ).compareTo(recurringPaymentOccurrenceDate(b, today));
                }

                monthly.sort(byOccurrence);
                yearly.sort(byOccurrence);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  children: [
                    _PaymentSection(
                      title: 'Monthly payments',
                      payments: monthly,
                      expanded: _monthlyExpanded,
                      onToggle: () =>
                          setState(() => _monthlyExpanded = !_monthlyExpanded),
                    ),
                    const SizedBox(height: 12),
                    _PaymentSection(
                      title: 'Yearly payments',
                      payments: yearly,
                      expanded: _yearlyExpanded,
                      onToggle: () =>
                          setState(() => _yearlyExpanded = !_yearlyExpanded),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add payment',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddRecurringPaymentScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.summary, required this.usdToEgpRate});

  final RecurringPaymentsMonthSummary summary;

  /// Null while the FX rate hasn't been fetched yet -- the USD line and
  /// legend USD values are hidden in that case rather than shown as a
  /// misleading zero, same convention as [NetWorthSummaryCard].
  final double? usdToEgpRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final usdTotal = (usdToEgpRate == null || usdToEgpRate == 0)
        ? null
        : summary.total / usdToEgpRate!;
    final paidFraction = summary.total <= 0
        ? 0.0
        : summary.paid / summary.total;
    final pendingFraction = summary.total <= 0
        ? 0.0
        : summary.pending / summary.total;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_repeat,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                summary.hasMinimums
                    ? 'MINIMUM TOTAL THIS MONTH'
                    : 'TOTAL THIS MONTH',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          MoneyText(
            formatEgpWhole(summary.total),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maskLength: 9,
          ),
          const SizedBox(height: 2),
          MoneyText(
            usdTotal == null ? '—' : '≈ ${formatUsdWhole(usdTotal)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.textDim),
            maskLength: 5,
          ),
          if (summary.hasMinimums) ...[
            const SizedBox(height: 6),
            Text(
              'Actual total may be higher -- some payments are minimums.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textDim,
              ),
            ),
          ],
          if (summary.total > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (summary.paid > 0)
                      Expanded(
                        flex: (paidFraction * 1000).round().clamp(1, 999),
                        child: Container(color: colors.good),
                      ),
                    if (summary.pending > 0)
                      Expanded(
                        flex: (pendingFraction * 1000).round().clamp(1, 999),
                        child: Container(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _PaymentLegendRow(
              icon: Icons.check_circle_outline,
              label: 'Paid',
              fraction: paidFraction,
              egpValue: summary.paid,
              usdValue: usdToEgpRate == null || usdToEgpRate == 0
                  ? null
                  : summary.paid / usdToEgpRate!,
              color: colors.good,
            ),
            const SizedBox(height: 8),
            _PaymentLegendRow(
              icon: Icons.hourglass_empty,
              label: 'Pending',
              fraction: pendingFraction,
              egpValue: summary.pending,
              usdValue: usdToEgpRate == null || usdToEgpRate == 0
                  ? null
                  : summary.pending / usdToEgpRate!,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}

/// One full-width legend row below the split bar -- mirrors
/// [NetWorthSummaryCard]'s own `_LegendRow` styling (a tinted box, icon,
/// label + percent on the left, EGP/USD stacked and right-aligned) so the
/// Paid/Pending split reads the same way the Net Worth tab's own
/// liquid/non-liquid split does, instead of two lines that could wrap
/// awkwardly next to each other on a narrow screen.
class _PaymentLegendRow extends StatelessWidget {
  static const _valueColumnWidth = 118.0;

  const _PaymentLegendRow({
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
  final double egpValue;

  /// Null when the FX rate isn't known yet -- shown as "—" rather than a
  /// misleading zero.
  final double? usdValue;
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
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textDim,
                    ),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                MoneyText(
                  pct,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maskLength: 3,
                ),
              ],
            ),
          ),
          SizedBox(
            width: _valueColumnWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  formatEgpWhole(egpValue),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textDim,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                  maskLength: 7,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                MoneyText(
                  usdValue == null ? '—' : '≈ ${formatUsdWhole(usdValue!)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textDim,
                    fontSize: 10.5,
                  ),
                  textAlign: TextAlign.right,
                  maskLength: 5,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.title,
    required this.payments,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final List<RecurringPayment> payments;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${title.toUpperCase()} (${payments.length})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.textDim,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: colors.textDim,
                ),
              ],
            ),
          ),
        ),
        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Text(
              'None yet.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.textDim),
            ),
          )
        else if (expanded)
          for (final payment in payments)
            _RecurringPaymentTile(payment: payment),
      ],
    );
  }
}

class _RecurringPaymentTile extends ConsumerWidget {
  const _RecurringPaymentTile({required this.payment});

  final RecurringPayment payment;

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete recurring payment?'),
            content: Text(
              'This removes "${payment.name}". This can\'t be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await ref.read(recurringPaymentRepositoryProvider).delete(payment.id);
    }
    return confirmed;
  }

  String _dueDescription(DateTime today) {
    final frequency = RecurringPaymentFrequency.fromStored(payment.frequency);
    switch (frequency) {
      case RecurringPaymentFrequency.monthly:
        return 'Bills on the ${payment.dayOfMonth}${_ordinalSuffix(payment.dayOfMonth)} of the month';
      case RecurringPaymentFrequency.interval:
        final days = payment.intervalDays ?? 0;
        final occurrence = recurringPaymentOccurrenceDate(payment, today);
        return 'Every $days day${days == 1 ? '' : 's'} · next ${_monthNames[occurrence.month - 1]} ${occurrence.day}';
      case RecurringPaymentFrequency.yearly:
        final month = payment.yearlyMonth ?? 1;
        final day = payment.yearlyDay ?? 1;
        return 'Every year on ${_monthNames[month - 1]} $day';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final hideValues = ref.watch(hideValuesProvider);
    final today = DateTime.now();
    final paid = recurringPaymentIsPaidForCurrentCycle(payment, today);
    final occurrence = recurringPaymentOccurrenceDate(payment, today);

    return Dismissible(
      key: ValueKey(payment.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, ref),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        color: paid ? colors.good.withValues(alpha: 0.08) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: paid
                ? colors.good.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddRecurringPaymentScreen(existing: payment),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                _PaidToggle(
                  paid: paid,
                  dayLabel: '${occurrence.day}',
                  onTap: () => ref
                      .read(recurringPaymentRepositoryProvider)
                      .setPaid(payment.id, !paid),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hideValues ? '••••••' : payment.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.calendar_today,
                              size: 11,
                              color: colors.textDim,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _dueDescription(today),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.textDim,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AmountTypeBadge(
                            isExactAmount: payment.isExactAmount,
                          ),
                          if (paid) ...[
                            const SizedBox(width: 6),
                            _PaidBadge(color: colors.good),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MoneyText(
                  formatMoney(payment.amount, payment.currency),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maskLength: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The leading badge in each tile -- shows the day this payment is next
/// due, or a checkmark once it's been marked paid for the current cycle.
/// Its own tap target (separate from the tile's onTap, which opens Edit)
/// toggles that paid state -- this is the "make payment look green" action
/// the total card's Paid/Pending split reads from.
class _PaidToggle extends StatelessWidget {
  const _PaidToggle({
    required this.paid,
    required this.dayLabel,
    required this.onTap,
  });

  final bool paid;
  final String dayLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final color = paid ? colors.good : theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: paid ? 'Mark as pending' : 'Mark as paid',
        child: Container(
          width: 44,
          height: 44,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: paid
              ? Center(child: Icon(Icons.check_circle, size: 20, color: color))
              // A miniature calendar-page icon -- a colored header strip
              // (like a real calendar's month band) above the day number --
              // rather than a plain colored box with a number in it, which
              // read as an arbitrary counter/badge more than "this is a
              // date."
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 13,
                      color: color,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.circle,
                        size: 3,
                        color: theme.colorScheme.surface,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          dayLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.textBody,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PaidBadge extends StatelessWidget {
  const _PaidBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'PAID',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Small colored pill making it unmistakable at a glance whether a payment's
/// amount is a fixed, known figure or just a floor the real bill could
/// exceed -- distinct from the plain "· min." text suffix this replaces,
/// which was easy to miss next to the amount.
class _AmountTypeBadge extends StatelessWidget {
  const _AmountTypeBadge({required this.isExactAmount});

  final bool isExactAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final color = isExactAmount ? colors.good : colors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isExactAmount ? 'EXACT AMOUNT' : 'MINIMUM AMOUNT',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// "1st" / "2nd" / "3rd" / "4th" ... for the day-of-month label.
String _ordinalSuffix(int day) {
  if (day >= 11 && day <= 13) return 'th';
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

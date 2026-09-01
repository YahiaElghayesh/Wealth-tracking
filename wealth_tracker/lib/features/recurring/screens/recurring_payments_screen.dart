import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/models/recurring_payment_frequency.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/settings_action.dart';
import '../../../data/db/database.dart';
import '../../../data/recurring/recurring_payment_due.dart';
import '../providers/recurring_payment_providers.dart';
import 'add_recurring_payment_screen.dart';

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
    final paymentsAsync = ref.watch(recurringPaymentsStreamProvider);
    final summary = ref.watch(recurringPaymentsMonthSummaryProvider);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring payments'),
        actions: const [HideValuesAction(), SettingsAction()],
      ),
      body: Column(
        children: [
          _TotalCard(summary: summary),
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
  const _TotalCard({required this.summary});

  final RecurringPaymentsMonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
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
          const SizedBox(height: 4),
          MoneyText(
            formatMoney(summary.total, defaultCurrency),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maskLength: 9,
          ),
          if (summary.hasMinimums) ...[
            const SizedBox(height: 3),
            Text(
              'Actual total may be higher -- some payments are minimums.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textDim,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TotalSplitLine(
                  label: 'Paid',
                  amount: summary.paid,
                  color: colors.good,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TotalSplitLine(
                  label: 'Pending',
                  amount: summary.pending,
                  color: colors.textDim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalSplitLine extends StatelessWidget {
  const _TotalSplitLine({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.appColors.textDim,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: MoneyText(
            formatMoney(amount, defaultCurrency),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
            maskLength: 7,
          ),
        ),
      ],
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 11,
                            color: colors.textDim,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _dueDescription(today),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.textDim,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: paid
              ? Icon(Icons.check_circle, size: 20, color: color)
              : Text(
                  dayLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dual_currency.dart';
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
    show pricesUsdPerUnitProvider, usdToEgpRateProvider;
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
/// totals cards and manual inputs: a total card up top (scrolling away
/// with the rest of the list, not pinned), split into two collapsible
/// sections below it.
class RecurringPaymentsScreen extends ConsumerStatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  ConsumerState<RecurringPaymentsScreen> createState() =>
      _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState
    extends ConsumerState<RecurringPaymentsScreen>
    with WidgetsBindingObserver {
  /// Both sections start expanded -- unlike the Net Worth tab's
  /// per-category sections, there are only ever two of these and the
  /// whole point of this tab is seeing what's due, so hiding it behind an
  /// extra tap by default doesn't pull its weight here.
  bool _monthlyExpanded = true;
  bool _yearlyExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// This tab's whole "what's paid/pending" picture is computed from
  /// `DateTime.now()` at build time (see [recurringPaymentIsPaidForCurrentCycle]
  /// and friends) -- but this screen sits inside the bottom nav's
  /// `IndexedStack`, which keeps every tab's widget tree alive and never
  /// tears it down when it's not the active tab, and nothing about a plain
  /// Riverpod watch on the payments stream fires again just because real
  /// time passed with no database write. Left alone, a payment correctly
  /// auto-marked "paid" (its due date had passed) the last time this tab
  /// actually rebuilt kept showing paid long after a new billing cycle
  /// started -- until *something* forced a rebuild -- which is exactly the
  /// reported "still shows paid for a bill that isn't due till the 4th, and
  /// today's only the 2nd" bug: the day/month had rolled over since this
  /// tab was last built, and nothing told it to look again. Forcing a
  /// rebuild on every foreground (locking/unlocking the phone, switching
  /// apps and back -- by far the common way a day boundary is crossed while
  /// this tab is sitting open) re-evaluates every payment's paid/pending
  /// state fresh against the real current date.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Fire-and-forget: auto-records last month's totals into history the
    // moment the calendar has moved past it -- see that provider's own
    // doc comment.
    ref.watch(recurringPaymentHistoryAutoRecordProvider);
    // Fire-and-forget: keeps every 'manual' payment's native reminder
    // notification schedule in sync -- see that provider's own doc
    // comment.
    ref.watch(recurringPaymentReminderSyncProvider);
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
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (payments) {
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
          // Sorts (and the tile badge below) both key off the *current
          // cycle's* due date, not the next upcoming occurrence -- for an
          // 'interval' payment those are two different dates (see
          // recurring_payment_due.dart's own doc comments): the due date is
          // when this cycle's charge actually happened (already in the
          // past once a cycle has started), while the occurrence is the
          // *next* charge, which can land next month. Sorting/badging by
          // occurrence instead put an already-charged, already-paid
          // "every 30 days" bill at the bottom of the list next to a
          // future date, while still showing it as paid -- looking like
          // a sort bug (a day-4 payment appearing after day-28 ones) and
          // a logic bug (marked paid against a date that hasn't happened
          // yet) at the same time. The due date is always <= today for an
          // interval payment whose first cycle has started, and always
          // this month for monthly/yearly, so this puts every payment
          // where it actually belongs.
          int byDueDate(RecurringPayment a, RecurringPayment b) {
            return recurringPaymentDueDateForCurrentCycle(
              a,
              today,
            ).compareTo(recurringPaymentDueDateForCurrentCycle(b, today));
          }

          monthly.sort(byDueDate);
          yearly.sort(byDueDate);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              _TotalCard(summary: summary, usdToEgpRate: usdToEgpRate),
              const SizedBox(height: 16),
              if (payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Tap + to add your first recurring payment.'),
                  ),
                )
              else ...[
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
            ],
          );
        },
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
    final prices = ref.watch(pricesUsdPerUnitProvider);
    final today = DateTime.now();
    final paid = recurringPaymentIsPaidForCurrentCycle(payment, today);
    // Whether this cycle's actual due date is still ahead of today --
    // used only to give a tap on the not-yet-paid toggle honest feedback
    // (see below) instead of silently doing nothing, since
    // recurringPaymentIsPaidForCurrentCycle no longer lets a mark before
    // the due date register as paid.
    final dueDate = recurringPaymentDueDateForCurrentCycle(payment, today);
    final notYetDue = dueDate.isAfter(
      DateTime(today.year, today.month, today.day),
    );
    final dualAmount = dualCurrencyAmounts(
      nativeCurrency: payment.currency,
      nativeAmount: payment.amount,
      pricesUsdPerUnit: prices,
    );

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PaidToggle(
                      paid: paid,
                      // The current cycle's actual due date -- when this
                      // cycle's charge happened (already in the past, for
                      // an 'interval' payment whose cycle has started) or
                      // is due (monthly/yearly) -- not the *next* upcoming
                      // occurrence, which for an 'interval' payment can be
                      // a different, later date shown separately in the
                      // "next ..." caption below. Badging the *next*
                      // occurrence here instead used to show a future date
                      // marked "paid," which was actually the current
                      // (already-charged) cycle wearing next cycle's date.
                      dayLabel: '${dueDate.day}',
                      monthLabel:
                          (dueDate.month != today.month ||
                              dueDate.year != today.year)
                          ? _monthNames[dueDate.month - 1].toUpperCase()
                          : null,
                      onTap: () {
                        if (!paid && notYetDue) {
                          // A tap here before the due date used to look
                          // like it "worked" -- the badge went green
                          // immediately -- but that's exactly the
                          // reported "shows paid days before it's even
                          // due" bug (whether from a deliberate early
                          // confirmation or a stray tap while scrolling
                          // past this row's badge). It's not a no-op --
                          // setPaid below still records it -- but the
                          // badge now only turns green once the cycle
                          // actually arrives, so this explains that
                          // instead of leaving the tap looking broken.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${payment.name} isn\'t due until '
                                '${_monthNames[dueDate.month - 1]} '
                                '${dueDate.day} -- it\'ll show as paid then.',
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                        ref
                            .read(recurringPaymentRepositoryProvider)
                            .setPaid(payment.id, !paid);
                      },
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
                          // Wrap, not Row -- three badges (amount type,
                          // payment mode, and now paid) can exceed a
                          // narrow tile's width on longer labels; Row would
                          // silently overflow instead of just flowing the
                          // extra badge onto a second line.
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _AmountTypeBadge(
                                isExactAmount: payment.isExactAmount,
                              ),
                              _PaymentModeBadge(
                                paymentMode: payment.paymentMode,
                              ),
                              if (paid) _PaidBadge(color: colors.good),
                            ],
                          ),
                          if (payment.notes != null &&
                              payment.notes!.isNotEmpty &&
                              !hideValues) ...[
                            const SizedBox(height: 4),
                            Text(
                              payment.notes!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.textDim,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MoneyText(
                          formatCurrencyWhole(
                            dualAmount.nativeAmount,
                            dualAmount.nativeCurrency,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maskLength: 8,
                        ),
                        MoneyText(
                          dualAmount.convertedAmount == null
                              ? '—'
                              : '≈ ${formatCurrencyWhole(dualAmount.convertedAmount!, dualAmount.convertedCurrency)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.textDim,
                          ),
                          maskLength: 6,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Its own full-width row below everything else -- packed
                // into the middle column above (next to the leading badge
                // and the trailing amount) it only had a narrow strip to
                // work with, so a longer due description (interval's
                // "Every N days · next Mon D", especially) wrapped
                // mid-sentence in a way that read as badly justified text
                // rather than one clean line.
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The leading badge in each tile -- always shows the day this payment is
/// next due, whether paid or not; the calendar's header strip turns green
/// and a small checkmark badge overlays its corner once marked paid, but
/// the date itself stays visible instead of being replaced by a checkmark
/// (which used to hide it entirely). Its own tap target (separate from
/// the tile's onTap, which opens Edit) toggles that paid state -- this is
/// the "make payment look green" action the total card's Paid/Pending
/// split reads from.
class _PaidToggle extends StatelessWidget {
  const _PaidToggle({
    required this.paid,
    required this.dayLabel,
    this.monthLabel,
    required this.onTap,
  });

  final bool paid;
  final String dayLabel;

  /// Short month abbreviation (e.g. "OCT") shown as a small corner tag when
  /// non-null -- only set for a payment whose next occurrence isn't in the
  /// current calendar month, so the bare day number doesn't get misread as
  /// "sooner than" a same-month day it's actually due after.
  final String? monthLabel;
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
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                // A miniature calendar-page icon -- a colored header strip
                // (like a real calendar's month band) above the day
                // number -- rather than a plain colored box with a number
                // in it, which read as an arbitrary counter/badge more
                // than "this is a date."
                child: Column(
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
              if (paid)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: colors.good,
                    ),
                  ),
                ),
              if (monthLabel != null)
                Positioned(
                  top: -6,
                  left: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      monthLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.surface,
                        fontWeight: FontWeight.w800,
                        fontSize: 8,
                        height: 1,
                        letterSpacing: 0.2,
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

/// Read-only view of a payment's Auto/Manual mode, right on the list tile
/// -- editing it stays exclusively in Add/Edit (this badge has no `onTap`
/// on purpose), but seeing which mode a payment is in shouldn't require
/// opening it first.
class _PaymentModeBadge extends StatelessWidget {
  const _PaymentModeBadge({required this.paymentMode});

  final String paymentMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final isManual = paymentMode == 'manual';
    final color = isManual ? theme.colorScheme.primary : colors.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isManual ? Icons.notifications_active : Icons.bolt,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isManual ? 'MANUAL' : 'AUTO',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.3,
            ),
          ),
        ],
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

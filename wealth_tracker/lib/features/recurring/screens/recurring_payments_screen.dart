import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/settings_action.dart';
import '../../../data/db/database.dart';
import '../providers/recurring_payment_providers.dart';
import 'add_recurring_payment_screen.dart';

/// The "Recurring payments" tab -- monthly bills/subscriptions (Netflix,
/// YouTube, Amazon Prime, ...) tracked and totaled the same way the
/// Calculator tab totals cards and manual inputs: a sticky total up top,
/// one row per payment below it.
class RecurringPaymentsScreen extends ConsumerWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(recurringPaymentsStreamProvider);
    final total = ref.watch(recurringPaymentsTotalProvider);
    final payments = paymentsAsync.valueOrNull ?? const [];
    final hasMinimums = payments.any((p) => !p.isExactAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring payments'),
        actions: const [HideValuesAction(), SettingsAction()],
      ),
      body: Column(
        children: [
          _TotalCard(total: total, hasMinimums: hasMinimums),
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
                final sorted = [...payments]
                  ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  children: [
                    for (final payment in sorted)
                      _RecurringPaymentTile(payment: payment),
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
  const _TotalCard({required this.total, required this.hasMinimums});

  final double total;

  /// Whether at least one payment in the list is a minimum-amount entry --
  /// when true the total includes an estimate rather than only known-exact
  /// figures, so the label says so instead of implying a hard total.
  final bool hasMinimums;

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
                hasMinimums ? 'MONTHLY MINIMUM TOTAL' : 'MONTHLY TOTAL',
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
            formatMoney(total, defaultCurrency),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maskLength: 9,
          ),
          if (hasMinimums) ...[
            const SizedBox(height: 3),
            Text(
              'Actual total may be higher -- some payments are minimums.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textDim,
              ),
            ),
          ],
        ],
      ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final hideValues = ref.watch(hideValuesProvider);

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${payment.dayOfMonth}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      Text(
                        _ordinalSuffix(payment.dayOfMonth),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
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
                          Text(
                            'Bills on the ${payment.dayOfMonth}${_ordinalSuffix(payment.dayOfMonth)} of the month',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.textDim,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _AmountTypeBadge(isExactAmount: payment.isExactAmount),
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

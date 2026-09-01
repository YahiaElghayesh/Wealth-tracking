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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring payments'),
        actions: const [HideValuesAction(), SettingsAction()],
      ),
      body: Column(
        children: [
          _TotalCard(total: total),
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
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  children: [
                    for (final payment in payments)
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
  const _TotalCard({required this.total});

  final double total;

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
                'MONTHLY TOTAL',
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.event_repeat,
                    size: 18,
                    color: theme.colorScheme.primary,
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
                      const SizedBox(height: 2),
                      Text(
                        'Bills on the ${payment.dayOfMonth}${_ordinalSuffix(payment.dayOfMonth)}'
                        '${payment.isExactAmount ? '' : ' · min.'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
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

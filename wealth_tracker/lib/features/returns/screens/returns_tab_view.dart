import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/currency_picker_field.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/db/database.dart';
import '../providers/returns_providers.dart';

/// The Returns tab's own "+" form -- a top-level function (not a method on
/// [ReturnsTabView]) so `LedgerHomeScreen`'s single shared FAB can open it
/// directly, the same way it already calls into this file's sibling
/// `_addCounterparty`/`_editCounterparty` for the other two tabs.
Future<void> showAddReturnDialog(BuildContext context, WidgetRef ref) async {
  final vendorController = TextEditingController();
  final amountController = TextEditingController();
  var currency = defaultCurrency;
  var returnDate = DateTime.now();
  final formKey = GlobalKey<FormState>();

  final save = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Add return'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: vendorController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Vendor',
                    hintText: 'e.g. Amazon',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Return amount',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null) {
                            return 'Enter a number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CurrencyPickerField(
                        value: currency,
                        labelText: 'Currency',
                        onChanged: (c) => setDialogState(() => currency = c),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Returned on'),
                  subtitle: Text(
                    '${returnDate.day}/${returnDate.month}/${returnDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: returnDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => returnDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );

  if (save == true) {
    await ref
        .read(returnsRepositoryProvider)
        .addReturn(
          vendor: vendorController.text.trim(),
          amount: double.parse(amountController.text.trim()),
          currency: currency,
          returnDate: returnDate,
        );
  }
  vendorController.dispose();
  amountController.dispose();
}

/// Whole calendar days between [from] and today -- never negative, so a
/// return dated "today" (or, oddly, in the future) still reads as day 0
/// rather than a confusing negative count.
int _daysSince(DateTime from) {
  final today = DateTime.now();
  final days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(from.year, from.month, from.day)).inDays;
  return days < 0 ? 0 : days;
}

/// "today" / "yesterday" / "N days ago", from [_daysSince]'s count.
String _daysAgoLabel(DateTime from) {
  final days = _daysSince(from);
  if (days == 0) return 'today';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}

/// A week with no movement on a return is worth flagging -- past this many
/// days, [_DaysAgoChip] switches from "still fresh" to "worth following up
/// on" styling.
const _returnOverdueAfterDays = 7;

class ReturnsTabView extends ConsumerWidget {
  const ReturnsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingReturnsProvider);

    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (pending) {
        if (pending.isEmpty) {
          return const Center(
            child: Text('Add a return to start tracking it.'),
          );
        }
        return ListView(
          // Extra bottom clearance so the last card never ends up sitting
          // under the shared FAB.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [for (final item in pending) _ReturnCard(item: item)],
        );
      },
    );
  }
}

class _ReturnCard extends ConsumerWidget {
  const _ReturnCard({required this.item});

  final Return item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.vendor,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                MoneyText(formatMoney(item.amount, item.currency)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _DaysAgoChip(returnDate: item.returnDate)),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(returnsRepositoryProvider).markReceived(item.id),
                  child: const Text('Received'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A colored pill for how long ago a return happened -- green while it's
/// still fresh, switching to the app's "bad" red-orange past
/// [_returnOverdueAfterDays] to flag it as worth following up on. Matches
/// the mockup shown when Returns' placement was being decided.
class _DaysAgoChip extends StatelessWidget {
  const _DaysAgoChip({required this.returnDate});

  final DateTime returnDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final days = _daysSince(returnDate);
    final overdue = days > _returnOverdueAfterDays;
    final color = overdue ? colors.bad : colors.good;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overdue ? Icons.warning_amber_rounded : Icons.schedule,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            'Returned ${_daysAgoLabel(returnDate)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

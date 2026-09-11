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

/// One day count -- "Returned today" / "...yesterday" / "...N days ago" --
/// shared between the pending card and (for "Received Nd after return")
/// history rows.
String _daysAgoLabel(DateTime from) {
  final today = DateTime.now();
  final days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(from.year, from.month, from.day)).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}

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
    final colors = context.appColors;
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
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Returned ${_daysAgoLabel(item.returnDate)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textDim),
                  ),
                ),
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

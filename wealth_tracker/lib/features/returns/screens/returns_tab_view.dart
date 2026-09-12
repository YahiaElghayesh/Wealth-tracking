import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/currency_picker_field.dart';
import '../../../core/widgets/money_text.dart';
import '../../../data/db/database.dart';
import '../providers/returns_providers.dart';

String _formatValue(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// The Returns tab's own add/edit form -- a top-level function (not a
/// method on [ReturnsTabView]) so `LedgerHomeScreen`'s single shared FAB
/// can open it directly, the same way it already calls into this file's
/// sibling `_addCounterparty`/`_editCounterparty` for the other two tabs.
/// [existing] switches this from "Add" to "Edit" (with its own Delete
/// action) -- same dialog either way, just pre-filled and writing back to
/// that row instead of inserting a new one.
Future<void> showReturnFormDialog(
  BuildContext context,
  WidgetRef ref, {
  Return? existing,
}) async {
  final vendorController = TextEditingController(text: existing?.vendor ?? '');
  final amountController = TextEditingController(
    text: existing == null ? '' : _formatValue(existing.amount),
  );
  var currency = existing?.currency ?? defaultCurrency;
  var returnDate = existing?.returnDate ?? DateTime.now();
  final formKey = GlobalKey<FormState>();
  final isEditing = existing != null;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(isEditing ? 'Edit return' : 'Add return'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: vendorController,
                  autofocus: !isEditing,
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
          if (isEditing)
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    ),
  );

  final repo = ref.read(returnsRepositoryProvider);
  if (result == true) {
    if (existing == null) {
      await repo.addReturn(
        vendor: vendorController.text.trim(),
        amount: double.parse(amountController.text.trim()),
        currency: currency,
        returnDate: returnDate,
      );
    } else {
      await repo.updateReturn(
        existing.copyWith(
          vendor: vendorController.text.trim(),
          amount: double.parse(amountController.text.trim()),
          currency: currency,
          returnDate: returnDate,
        ),
      );
    }
  } else if (result == null && existing != null) {
    // The Delete action pops `null` rather than posting straight away, so
    // the dialog is already closed before this runs -- same shape as
    // every other delete-from-an-edit-form flow in the app.
    await repo.deleteReturn(existing.id);
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

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete return?'),
            content: Text('This removes "${item.vendor}" for good.'),
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
      await ref.read(returnsRepositoryProvider).deleteReturn(item.id);
    }
    return confirmed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, ref),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showReturnFormDialog(context, ref, existing: item),
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
                    _DaysAgoChip(returnDate: item.returnDate),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: () => ref
                          .read(returnsRepositoryProvider)
                          .markReceived(item.id),
                      child: const Text('Received'),
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

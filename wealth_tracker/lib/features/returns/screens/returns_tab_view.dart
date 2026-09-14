import 'package:drift/drift.dart' show Value;
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

String _formatDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Pushes the Returns tab's own add/edit screen -- a top-level function
/// (not a method on [ReturnsTabView]) so `LedgerHomeScreen`'s single shared
/// FAB can open it directly, the same way it already calls into this
/// file's sibling `_addCounterparty` for the other two tabs. [existing]
/// switches this from "Add" to "Edit" (with its own Delete action) -- same
/// screen either way, just pre-filled and writing back to that row instead
/// of inserting a new one.
///
/// A real pushed screen, not a `showDialog` `AlertDialog` -- this used to
/// open its date pickers from inside an already-open dialog (the only
/// place in the app that did), which crashed with a framework
/// `_dependents.isEmpty` assertion when the outer dialog was dismissed via
/// the system back button while that nested picker route was involved.
/// Every other "Add X" form in this app (add_transaction_screen.dart,
/// add_edit_asset_screen.dart, ...) is already a pushed screen with its
/// own `showDatePicker` calls straight off its own context, never nested
/// inside another dialog -- matching that removes the nesting outright
/// instead of chasing the exact framework interaction that triggered it.
Future<void> openAddEditReturnScreen(BuildContext context, {Return? existing}) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => AddEditReturnScreen(existing: existing)));
}

/// Whole calendar days between [from] and today -- never negative, so a
/// date of "today" (or, oddly, in the future) still reads as day 0 rather
/// than a confusing negative count.
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
/// on" styling. Applies the same way to either of a return's two dates.
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
    final hasAnyDate = item.requestedAt != null || item.pickedUpAt != null;
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
          onTap: () => openAddEditReturnScreen(context, existing: item),
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
                if (hasAnyDate) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.requestedAt != null)
                        _DaysAgoChip(label: 'Requested', date: item.requestedAt!),
                      if (item.pickedUpAt != null)
                        _DaysAgoChip(label: 'Picked up', date: item.pickedUpAt!),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: () =>
                        ref.read(returnsRepositoryProvider).markReceived(item.id),
                    child: const Text('Received'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A colored pill for how long ago one of a return's dates happened --
/// green while it's still fresh, switching to the app's "bad" red-orange
/// past [_returnOverdueAfterDays] to flag it as worth following up on.
/// [label] ("Requested"/"Picked up") says which of the two dates this is.
class _DaysAgoChip extends StatelessWidget {
  const _DaysAgoChip({required this.label, required this.date});

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final days = _daysSince(date);
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
            '$label ${_daysAgoLabel(date)}',
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

/// The Returns tab's add/edit form, pushed by [openAddEditReturnScreen].
/// [Return.requestedAt] and [Return.pickedUpAt] are both optional and
/// independent -- either can be set, changed, or cleared back to unset at
/// any time, not just when the return is first added.
class AddEditReturnScreen extends ConsumerStatefulWidget {
  const AddEditReturnScreen({super.key, this.existing});

  final Return? existing;

  @override
  ConsumerState<AddEditReturnScreen> createState() =>
      _AddEditReturnScreenState();
}

class _AddEditReturnScreenState extends ConsumerState<AddEditReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _vendorController;
  late final TextEditingController _amountController;
  late String _currency;
  DateTime? _requestedAt;
  DateTime? _pickedUpAt;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _vendorController = TextEditingController(text: existing?.vendor ?? '');
    _amountController = TextEditingController(
      text: existing == null ? '' : _formatValue(existing.amount),
    );
    _currency = existing?.currency ?? defaultCurrency;
    _requestedAt = existing?.requestedAt;
    _pickedUpAt = existing?.pickedUpAt;
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickRequestedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _requestedAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _requestedAt = picked);
  }

  Future<void> _pickPickedUpAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedUpAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _pickedUpAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vendor = _vendorController.text.trim();
    final amount = double.parse(_amountController.text.trim());
    final repo = ref.read(returnsRepositoryProvider);
    final existing = widget.existing;
    if (existing == null) {
      await repo.addReturn(
        vendor: vendor,
        amount: amount,
        currency: _currency,
        requestedAt: _requestedAt,
        pickedUpAt: _pickedUpAt,
      );
    } else {
      await repo.updateReturn(
        existing.copyWith(
          vendor: vendor,
          amount: amount,
          currency: _currency,
          requestedAt: Value(_requestedAt),
          pickedUpAt: Value(_pickedUpAt),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete return?'),
            content: Text('This removes "${widget.existing!.vendor}" for good.'),
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
    if (!confirmed) return;

    await ref.read(returnsRepositoryProvider).deleteReturn(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit return' : 'Add return'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            TextFormField(
              controller: _vendorController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Vendor',
                hintText: 'e.g. Amazon',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Return amount'),
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
                    value: _currency,
                    labelText: 'Currency',
                    onChanged: (c) => setState(() => _currency = c),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _OptionalDateField(
              label: 'Return requested',
              date: _requestedAt,
              onTap: _pickRequestedAt,
              onClear: () => setState(() => _requestedAt = null),
            ),
            const SizedBox(height: 16),
            _OptionalDateField(
              label: 'Picked up',
              date: _pickedUpAt,
              onTap: _pickPickedUpAt,
              onClear: () => setState(() => _pickedUpAt = null),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: Text(_isEditing ? 'Save' : 'Add'),
      ),
    );
  }
}

/// One of [AddEditReturnScreen]'s two independent optional date rows --
/// tap to set/change, a trailing clear button (shown only once set) to go
/// back to unset. Matches add_edit_asset_screen.dart's own optional
/// purchase-date field.
class _OptionalDateField extends StatelessWidget {
  const _OptionalDateField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: '$label (optional)'),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 10),
            Text(date == null ? 'Not set' : _formatDate(date!)),
            if (date != null) ...[
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Clear',
                onPressed: onClear,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

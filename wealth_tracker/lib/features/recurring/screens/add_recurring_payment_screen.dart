import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../data/db/database.dart';
import '../providers/recurring_payment_providers.dart';

/// Add or edit one recurring payment (a monthly bill/subscription like
/// Netflix or Amazon Prime). Also reached, pre-filled, from SmsReviewScreen
/// when a detected charge is marked as a new recurring payment -- see
/// [initialName]/[initialAmount]/[initialCurrency]/[initialDayOfMonth].
class AddRecurringPaymentScreen extends ConsumerStatefulWidget {
  const AddRecurringPaymentScreen({
    super.key,
    this.existing,
    this.initialName,
    this.initialAmount,
    this.initialCurrency,
    this.initialDayOfMonth,
  });

  /// Non-null when editing an already-saved payment instead of adding a new
  /// one.
  final RecurringPayment? existing;

  final String? initialName;
  final double? initialAmount;
  final String? initialCurrency;
  final int? initialDayOfMonth;

  @override
  ConsumerState<AddRecurringPaymentScreen> createState() =>
      _AddRecurringPaymentScreenState();
}

class _AddRecurringPaymentScreenState
    extends ConsumerState<AddRecurringPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late bool _isExactAmount;
  late String _currency;
  late int _dayOfMonth;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(
      text: existing?.name ?? widget.initialName ?? '',
    );
    _amountController = TextEditingController(
      text: existing != null
          ? _formatAmount(existing.amount)
          : widget.initialAmount != null
          ? _formatAmount(widget.initialAmount!)
          : '',
    );
    _isExactAmount = existing?.isExactAmount ?? true;
    _currency = existing?.currency ?? widget.initialCurrency ?? defaultCurrency;
    _dayOfMonth =
        existing?.dayOfMonth ??
        widget.initialDayOfMonth ??
        DateTime.now().day.clamp(1, 31);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    final existing = widget.existing;
    if (existing != null) {
      await ref
          .read(recurringPaymentRepositoryProvider)
          .update(
            existing.copyWith(
              name: name,
              amount: amount,
              currency: _currency,
              isExactAmount: _isExactAmount,
              dayOfMonth: _dayOfMonth,
            ),
          );
    } else {
      await ref
          .read(recurringPaymentRepositoryProvider)
          .add(
            name: name,
            amount: amount,
            currency: _currency,
            isExactAmount: _isExactAmount,
            dayOfMonth: _dayOfMonth,
          );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete recurring payment?'),
            content: const Text("This can't be undone."),
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

    await ref
        .read(recurringPaymentRepositoryProvider)
        .delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit recurring payment' : 'Add recurring payment',
        ),
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
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Netflix',
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
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Enter a number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: supportedCurrencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (c) => setState(() => _currency = c!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Is this the exact amount every month, or just a minimum?',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Exact amount')),
                ButtonSegment(value: false, label: Text('Minimum amount')),
              ],
              selected: {_isExactAmount},
              onSelectionChanged: (s) =>
                  setState(() => _isExactAmount = s.first),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _dayOfMonth,
              decoration: const InputDecoration(labelText: 'Day of month'),
              items: [
                for (var day = 1; day <= 31; day++)
                  DropdownMenuItem(value: day, child: Text('$day')),
              ],
              onChanged: (day) {
                if (day != null) setState(() => _dayOfMonth = day);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Whole numbers print without a trailing ".0".
String _formatAmount(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

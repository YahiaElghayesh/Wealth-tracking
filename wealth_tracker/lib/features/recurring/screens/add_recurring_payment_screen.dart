import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../core/models/recurring_payment_frequency.dart';
import '../../../data/db/database.dart';
import '../providers/recurring_payment_providers.dart';

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

/// Add or edit one recurring payment (a monthly bill/subscription like
/// Netflix or Amazon Prime, or a yearly one like a domain renewal). Also
/// reached, pre-filled, from SmsReviewScreen when a detected charge is
/// marked as a new recurring payment -- see
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

  /// Only ever used to seed a *monthly* payment -- SmsReviewScreen passes
  /// the charge's own day of month, and that's the one frequency a raw SMS
  /// date maps onto without guessing.
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
  late final TextEditingController _intervalDaysController;
  late final TextEditingController _notesController;
  late bool _isExactAmount;
  late String _currency;
  late RecurringPaymentFrequency _frequency;
  late int _dayOfMonth;
  late DateTime _intervalAnchorDate;
  late int _yearlyMonth;
  late int _yearlyDay;
  late String _paymentMode;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now();
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
    _frequency = existing != null
        ? RecurringPaymentFrequency.fromStored(existing.frequency)
        : RecurringPaymentFrequency.monthly;
    _dayOfMonth =
        existing?.dayOfMonth ??
        widget.initialDayOfMonth ??
        now.day.clamp(1, 31);
    _intervalDaysController = TextEditingController(
      text: '${existing?.intervalDays ?? 30}',
    );
    _intervalAnchorDate = existing?.intervalAnchorDate ?? now;
    _yearlyMonth = existing?.yearlyMonth ?? now.month;
    _yearlyDay = existing?.yearlyDay ?? now.day.clamp(1, 31);
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _paymentMode = existing?.paymentMode ?? 'auto';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _intervalDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAnchorDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _intervalAnchorDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _intervalAnchorDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final amount = double.parse(_amountController.text.trim());
    final intervalDays = int.tryParse(_intervalDaysController.text.trim());
    final notes = _notesController.text.trim();

    final existing = widget.existing;
    if (existing != null) {
      final newDayOfMonth = _frequency == RecurringPaymentFrequency.monthly
          ? _dayOfMonth
          : existing.dayOfMonth;
      final newIntervalDays = _frequency == RecurringPaymentFrequency.interval
          ? intervalDays
          : null;
      final newIntervalAnchorDate =
          _frequency == RecurringPaymentFrequency.interval
          ? _intervalAnchorDate
          : null;
      final newYearlyMonth = _frequency == RecurringPaymentFrequency.yearly
          ? _yearlyMonth
          : null;
      final newYearlyDay = _frequency == RecurringPaymentFrequency.yearly
          ? _yearlyDay
          : null;
      // A "paid" mark answers "did this cycle's bill go out" for the
      // *old* schedule -- changing what actually determines the due date
      // invalidates that answer, so it resets to pending rather than
      // silently carrying an unrelated confirmation over onto the new
      // schedule (e.g. marking day 1 paid, then editing the day to 4,
      // shouldn't leave day 4 showing paid before it's even arrived).
      final scheduleChanged =
          existing.frequency != _frequency.stored ||
          existing.dayOfMonth != newDayOfMonth ||
          existing.intervalDays != newIntervalDays ||
          existing.intervalAnchorDate != newIntervalAnchorDate ||
          existing.yearlyMonth != newYearlyMonth ||
          existing.yearlyDay != newYearlyDay;

      await ref
          .read(recurringPaymentRepositoryProvider)
          .update(
            existing.copyWith(
              name: name,
              amount: amount,
              currency: _currency,
              isExactAmount: _isExactAmount,
              frequency: _frequency.stored,
              dayOfMonth: newDayOfMonth,
              intervalDays: Value(newIntervalDays),
              intervalAnchorDate: Value(newIntervalAnchorDate),
              yearlyMonth: Value(newYearlyMonth),
              yearlyDay: Value(newYearlyDay),
              lastPaidAt: scheduleChanged
                  ? const Value(null)
                  : const Value.absent(),
              notes: Value(notes.isEmpty ? null : notes),
              paymentMode: _paymentMode,
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
            frequency: _frequency,
            dayOfMonth: _frequency == RecurringPaymentFrequency.monthly
                ? _dayOfMonth
                : null,
            intervalDays: _frequency == RecurringPaymentFrequency.interval
                ? intervalDays
                : null,
            intervalAnchorDate: _frequency == RecurringPaymentFrequency.interval
                ? _intervalAnchorDate
                : null,
            yearlyMonth: _frequency == RecurringPaymentFrequency.yearly
                ? _yearlyMonth
                : null,
            yearlyDay: _frequency == RecurringPaymentFrequency.yearly
                ? _yearlyDay
                : null,
            notes: notes.isEmpty ? null : notes,
            paymentMode: _paymentMode,
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
              'Is this the exact amount every time, or just a minimum?',
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
            Text(
              'How often does this bill?',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<RecurringPaymentFrequency>(
              segments: const [
                ButtonSegment(
                  value: RecurringPaymentFrequency.monthly,
                  label: Text('Monthly'),
                ),
                ButtonSegment(
                  value: RecurringPaymentFrequency.interval,
                  label: Text('Every N days'),
                ),
                ButtonSegment(
                  value: RecurringPaymentFrequency.yearly,
                  label: Text('Yearly'),
                ),
              ],
              selected: {_frequency},
              onSelectionChanged: (s) => setState(() => _frequency = s.first),
            ),
            const SizedBox(height: 16),
            switch (_frequency) {
              RecurringPaymentFrequency.monthly => DropdownButtonFormField<int>(
                key: const ValueKey('day-of-month'),
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
              RecurringPaymentFrequency.interval => Column(
                key: const ValueKey('interval'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _intervalDaysController,
                    decoration: const InputDecoration(
                      labelText: 'Every how many days',
                      hintText: 'e.g. 10',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'Enter a whole number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickAnchorDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Starting from',
                      ),
                      child: Text(
                        '${_intervalAnchorDate.year}-'
                        '${_intervalAnchorDate.month.toString().padLeft(2, '0')}-'
                        '${_intervalAnchorDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ),
              RecurringPaymentFrequency.yearly => Row(
                key: const ValueKey('yearly'),
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _yearlyMonth,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: [
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem(
                            value: m,
                            child: Text(_monthNames[m - 1]),
                          ),
                      ],
                      onChanged: (m) {
                        if (m != null) setState(() => _yearlyMonth = m);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _yearlyDay,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: [
                        for (var day = 1; day <= 31; day++)
                          DropdownMenuItem(value: day, child: Text('$day')),
                      ],
                      onChanged: (day) {
                        if (day != null) setState(() => _yearlyDay = day);
                      },
                    ),
                  ),
                ],
              ),
            },
            const SizedBox(height: 16),
            Text(
              'Does this get paid automatically, or do you have to pay it yourself?',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'auto', label: Text('Auto')),
                ButtonSegment(value: 'manual', label: Text('Manual')),
              ],
              selected: {_paymentMode},
              onSelectionChanged: (s) => setState(() => _paymentMode = s.first),
            ),
            if (_paymentMode == 'manual') ...[
              const SizedBox(height: 8),
              Text(
                "You'll get a reminder notification starting at midnight on "
                "the due date, repeating every 4 hours until you mark it "
                'paid or tap Done on the notification.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional',
              ),
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

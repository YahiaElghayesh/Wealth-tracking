import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../core/models/ledger_category.dart';
import '../../../data/sms/bank_charge_notifications.dart';
import '../providers/ledger_providers.dart';

/// Opened when a bank-charge notification's body is tapped — either there
/// was no clean vendor-rule default, or the user wants to change the
/// suggested ledger/category before saving. Pre-filled from the parsed
/// SMS, but everything stays editable.
class SmsReviewScreen extends ConsumerStatefulWidget {
  const SmsReviewScreen({super.key, required this.payload});

  final BankChargePayload payload;

  @override
  ConsumerState<SmsReviewScreen> createState() => _SmsReviewScreenState();
}

class _SmsReviewScreenState extends ConsumerState<SmsReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _customCategoryController = TextEditingController();
  String? _counterpartyId;
  late String _category;
  late String _currency;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.payload.amount.toStringAsFixed(2));
    _currency = widget.payload.currency;
    _date = widget.payload.occurredAt;
    _counterpartyId = widget.payload.counterpartyId;
    final matchedCategory = widget.payload.category;
    _category = matchedCategory != null && ledgerExpenseCategories.contains(matchedCategory)
        ? matchedCategory
        : ledgerExpenseCategories.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final counterpartyId = _counterpartyId;
    if (counterpartyId == null) return;

    final amount = double.parse(_amountController.text.trim());
    final category = _category == 'Other' ? _customCategoryController.text.trim() : _category;

    await ref.read(ledgerRepositoryProvider).addTransaction(
          counterpartyId: counterpartyId,
          date: _date,
          amount: amount,
          currency: _currency,
          category: category.isEmpty ? 'Other' : category,
          description: 'Added from SMS',
        );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final counterparties = ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Add from SMS')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'From SMS: ${widget.payload.vendor}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    style: Theme.of(context).textTheme.headlineMedium,
                    decoration: const InputDecoration(hintText: '0.00'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    initialValue: _currency,
                    items: supportedCurrencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (c) => setState(() => _currency = c!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _counterpartyId,
              decoration: const InputDecoration(labelText: 'Ledger'),
              items: counterparties
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _counterpartyId = v),
              validator: (v) => v == null ? 'Pick a ledger' : null,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ledgerExpenseCategories.map((c) {
                return ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            if (_category == 'Other') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customCategoryController,
                decoration: const InputDecoration(hintText: 'Category'),
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.check),
      ),
    );
  }
}

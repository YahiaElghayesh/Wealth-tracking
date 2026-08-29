import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../core/models/ledger_category.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/sms/bank_charge_payload.dart';
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
    final theme = Theme.of(context);
    final colors = context.appColors;
    final counterparties = ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];
    final matchedByRule = widget.payload.counterpartyId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      'From SMS · ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                      style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _amountController,
                          style: theme.textTheme.headlineSmall,
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
                          isExpanded: true,
                          initialValue: _currency,
                          items: supportedCurrencies
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (c) => setState(() => _currency = c!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.textDim),
                      children: [
                        const TextSpan(text: 'at '),
                        TextSpan(
                          text: widget.payload.vendor,
                          style: TextStyle(color: colors.textBody, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  if (matchedByRule) ...[
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.good.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: colors.good),
                          const SizedBox(width: 4),
                          Text(
                            'Matched by vendor rule',
                            style: theme.textTheme.labelSmall?.copyWith(color: colors.good, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Add to which ledger?', style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _counterpartyId,
              items: counterparties
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _counterpartyId = v),
              validator: (v) => v == null ? 'Pick a ledger' : null,
            ),
            const SizedBox(height: 16),
            Text('Category', style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
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
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: colors.textDim),
                    const SizedBox(width: 12),
                    Text(
                      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Not a payment'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Confirm & add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

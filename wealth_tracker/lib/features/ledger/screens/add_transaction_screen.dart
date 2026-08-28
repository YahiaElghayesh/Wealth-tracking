import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../core/models/ledger_category.dart';
import '../providers/ledger_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    required this.counterpartyId,
    this.closeAppOnSave = false,
  });

  final String counterpartyId;

  /// True when reached via the home-screen widget's quick-add flow — the
  /// point there is speed, so saving exits straight back to the home
  /// screen instead of leaving the app open on some other screen.
  final bool closeAppOnSave;

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _customCategoryController = TextEditingController();
  bool _isPayment = true;
  String _category = ledgerExpenseCategories.first;
  String _currency = defaultCurrency;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    // autofocus alone isn't reliable right after a route push — requesting
    // focus after the first frame reliably brings the keyboard up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_amountFocusNode);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
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

    final amount = double.parse(_amountController.text.trim());
    final category = _isPayment
        ? (_category == 'Other' ? _customCategoryController.text.trim() : _category)
        : ledgerRepaymentCategory;

    await ref.read(ledgerRepositoryProvider).addTransaction(
          counterpartyId: widget.counterpartyId,
          date: _date,
          amount: _isPayment ? amount : -amount,
          currency: _currency,
          category: category.isEmpty ? 'Other' : category,
          description: null,
        );

    if (!mounted) return;
    if (widget.closeAppOnSave) {
      SystemNavigator.pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
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
            if (_isPayment) ...[
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
            ],
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('You Paid')),
                ButtonSegment(value: false, label: Text('Repaid You')),
              ],
              selected: {_isPayment},
              onSelectionChanged: (s) => setState(() => _isPayment = s.first),
            ),
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

import 'dart:async';

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
  // Null until the user actually taps a chip — defaults to whichever
  // category is first once the (async, user-managed) list loads, computed
  // fresh each build rather than seeded once, so a category added or
  // removed in Settings while this screen is open is reflected immediately.
  String? _category;
  List<String> _categoryNames = const ['Other'];
  String _currency = defaultCurrency;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    // autofocus alone isn't reliable right after a route push, and a plain
    // post-frame focus request isn't enough either when this screen is
    // reached via the quick-add widget's deep link: the enclosing route's
    // push transition (and, on a cold start, the Activity's own window
    // transition) can still be animating when the first frame completes,
    // which silently swallows the focus request and never brings up the
    // keyboard. Wait for the route transition to finish, then retry once
    // shortly after as a safety net for the cold-start case.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _waitForRouteTransition();
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_amountFocusNode);
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted || _amountFocusNode.hasFocus) return;
      FocusScope.of(context).requestFocus(_amountFocusNode);
    });
  }

  Future<void> _waitForRouteTransition() {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) return Future.value();
    final completer = Completer<void>();
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        animation.removeStatusListener(listener);
        if (!completer.isCompleted) completer.complete();
      }
    }

    animation.addStatusListener(listener);
    // Belt-and-suspenders: don't wait forever if the animation never
    // reports completed for some reason.
    Future.delayed(const Duration(milliseconds: 500), () {
      animation.removeStatusListener(listener);
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
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
    final selectedCategory = _category ?? _categoryNames.first;
    final category = _isPayment
        ? (selectedCategory == 'Other' ? _customCategoryController.text.trim() : selectedCategory)
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
    final categoriesAsync = ref.watch(ledgerCategoriesStreamProvider);
    _categoryNames = [
      ...categoriesAsync.valueOrNull?.map((c) => c.name) ?? const <String>[],
      'Other',
    ];
    final selectedCategory = _category ?? _categoryNames.first;

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
            if (_isPayment) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _categoryNames.map((c) {
                  return ChoiceChip(
                    label: Text(c),
                    selected: selectedCategory == c,
                    onSelected: (_) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              if (selectedCategory == 'Other') ...[
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
                ButtonSegment(value: false, label: Text('Paid to You')),
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

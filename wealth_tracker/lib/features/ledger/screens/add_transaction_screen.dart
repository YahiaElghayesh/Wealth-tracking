import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../core/models/ledger_category.dart';
import '../../../data/db/database.dart';
import '../providers/ledger_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    required this.counterpartyId,
    this.closeAppOnSave = false,
    this.existing,
  });

  final String counterpartyId;

  /// True when reached via the home-screen widget's quick-add flow — the
  /// point there is speed, so saving exits straight back to the home
  /// screen instead of leaving the app open on some other screen.
  final bool closeAppOnSave;

  /// Non-null when editing an already-saved entry instead of adding a new
  /// one — pre-fills every field from it and saves via `updateTransaction`
  /// instead of `addTransaction`.
  final LedgerTransaction? existing;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
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

  // The numeric keyboard must stay open for the whole time this screen is
  // up -- there's no "done" action on it that should also close it without
  // leaving the screen. These two flags are the only legitimate reasons the
  // amount field is allowed to actually lose focus: [_closing] while this
  // screen is on its way out (saving, deleting, or being popped), and
  // [_modalOpen] while a dialog that might have its own focusable field
  // (the date picker's manual-entry mode, the delete confirmation) is up --
  // fighting for focus in either case would either be pointless (the screen
  // is going away) or actively break the dialog (yanking focus back to the
  // amount field out from under whatever the dialog itself is focused on).
  bool _closing = false;
  bool _modalOpen = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(_onAmountFocusChange);
    final existing = widget.existing;
    if (existing != null) {
      _isPayment = existing.amount >= 0;
      _amountController.text = existing.amount.abs().toString();
      _currency = existing.currency;
      _date = existing.date;
      if (_isPayment) {
        _category = existing.category;
      }
    }
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
    _amountFocusNode.removeListener(_onAmountFocusChange);
    _amountController.dispose();
    _amountFocusNode.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  /// Fires on *any* loss of focus, including ones nothing on this screen
  /// caused directly -- the system's own "hide keyboard" affordance closes
  /// the IME by ending the text input connection, which unfocuses the field
  /// in Flutter's tree too even though no other widget here ever asked for
  /// focus. Immediately asking for it back is what makes the keyboard
  /// effectively impossible to dismiss without leaving the screen.
  void _onAmountFocusChange() {
    if (_amountFocusNode.hasFocus || _closing || _modalOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _closing || _modalOpen) return;
      FocusScope.of(context).requestFocus(_amountFocusNode);
    });
  }

  Future<void> _pickDate() async {
    _modalOpen = true;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    _modalOpen = false;
    if (picked != null) setState(() => _date = picked);
    _keepAmountFocused();
  }

  /// Every other control on this screen (category chips, the currency
  /// dropdown, the payment-direction toggle, the date picker) is a quick
  /// thumb tap meant to happen *while* still keying in the amount — none of
  /// them should be able to dismiss the numeric keyboard the way picking
  /// them normally would by stealing focus. Called right after each of
  /// those interactions to hand focus straight back to the amount field.
  void _keepAmountFocused() {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_amountFocusNode);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _closing = true;

    final amount = double.parse(_amountController.text.trim());
    final selectedCategory = _category ?? _categoryNames.first;
    final category = _isPayment
        ? (selectedCategory == 'Other'
              ? _customCategoryController.text.trim()
              : selectedCategory)
        : ledgerRepaymentCategory;
    final signedAmount = _isPayment ? amount : -amount;
    final resolvedCategory = category.isEmpty ? 'Other' : category;

    final existing = widget.existing;
    if (existing != null) {
      await ref
          .read(ledgerRepositoryProvider)
          .updateTransaction(
            existing.copyWith(
              date: _date,
              amount: signedAmount,
              currency: _currency,
              category: resolvedCategory,
            ),
          );
    } else {
      await ref
          .read(ledgerRepositoryProvider)
          .addTransaction(
            counterpartyId: widget.counterpartyId,
            date: _date,
            amount: signedAmount,
            currency: _currency,
            category: resolvedCategory,
            description: null,
          );
    }

    if (!mounted) return;
    if (widget.closeAppOnSave) {
      SystemNavigator.pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    _modalOpen = true;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete entry?'),
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
    _modalOpen = false;
    if (!confirmed) {
      _keepAmountFocused();
      return;
    }
    _closing = true;

    await ref
        .read(ledgerRepositoryProvider)
        .deleteTransaction(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(ledgerCategoriesStreamProvider);
    _categoryNames = [
      ...categoriesAsync.valueOrNull?.map((c) => c.name) ?? const <String>[],
      'Other',
    ];
    final selectedCategory = _category ?? _categoryNames.first;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) => _closing = true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit' : 'Add'),
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
                      items: supportedCurrencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (c) {
                        setState(() => _currency = c!);
                        _keepAmountFocused();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('You Paid')),
                  ButtonSegment(value: false, label: Text('Paid to You')),
                ],
                selected: {_isPayment},
                onSelectionChanged: (s) {
                  setState(() => _isPayment = s.first);
                  _keepAmountFocused();
                },
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
              // Categories sit last, closest to the bottom of the screen --
              // the control the user reaches for most, kept within easy
              // one-thumb reach instead of up by the amount field.
              if (_isPayment) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryNames.map((c) {
                    return ChoiceChip(
                      label: Text(c),
                      selected: selectedCategory == c,
                      onSelected: (_) {
                        setState(() => _category = c);
                        _keepAmountFocused();
                      },
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
              // Keeps this content clear of the FAB when the list is short
              // enough that it would otherwise sit right underneath it.
              const SizedBox(height: 72),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _save,
          child: const Icon(Icons.check),
        ),
      ),
    );
  }
}

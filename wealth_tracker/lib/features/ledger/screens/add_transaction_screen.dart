import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../core/models/ledger_category.dart';
import '../../../core/security/quick_add_exemption.dart';
import '../../../core/theme/app_colors.dart';
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
  // Never receives real keyboard focus -- see the keypad row built at the
  // bottom of this screen. A previous version of this screen fought
  // Android's own IME to keep it permanently open (re-requesting focus
  // whenever it closed, re-showing it after the back button, ...), which
  // never fully worked: the system keyboard can still flicker shut for a
  // frame on things like the Enter key, and a *system* affordance was
  // always going to have another way to dismiss itself eventually. A
  // number pad that's just part of this screen's own layout -- a plain
  // Column, not a platform overlay -- has no "closed" state to fight in
  // the first place.
  final _amountController = TextEditingController();
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

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
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
    // Only the quick-add-invoked instance of this screen exempts the
    // biometric lock (AppLockGate) -- reached from a ledger row's own "+"
    // button instead, closeAppOnSave is false and this never fires, so
    // that path stays behind the lock like everything else.
    if (widget.closeAppOnSave) {
      quickAddScreenActive.value = true;
    }
  }

  @override
  void dispose() {
    if (widget.closeAppOnSave) {
      quickAddScreenActive.value = false;
    }
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  /// Appends [input] (a digit, or ".") to the amount, matching how a plain
  /// numeric keyboard would -- a lone leading "0" is replaced rather than
  /// prefixed (typing "5" after "0" gives "5", not "05"), and a second "."
  /// is ignored rather than accepted, same as [TextInputType.number]'s own
  /// decimal filtering.
  void _appendDigit(String input) {
    final text = _amountController.text;
    if (input == '.') {
      if (text.contains('.')) return;
      _setAmountText(text.isEmpty ? '0.' : '$text.');
    } else {
      _setAmountText(text == '0' ? input : text + input);
    }
  }

  void _backspace() {
    final text = _amountController.text;
    if (text.isEmpty) return;
    _setAmountText(text.substring(0, text.length - 1));
  }

  /// Setting [TextEditingController.text] on its own resets the cursor to
  /// the start; every keypad tap should instead leave it at the end, where
  /// the next tap's digit will land, matching how typing normally feels.
  void _setAmountText(String text) {
    setState(() {
      _amountController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
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
      _closeQuickAdd();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Exits the app entirely rather than popping back to whatever's
  /// underneath -- used both after a successful save and when the user
  /// backs out without saving (see the `PopScope` in [build]). Quick-add is
  /// exempt from the biometric lock (AppLockGate) specifically because it's
  /// a narrow, single-purpose screen; leaving it via a plain pop would
  /// reveal the full app (whatever screen happens to be underneath) with no
  /// fresh unlock check at all, defeating the whole point of that
  /// exemption being narrow in the first place.
  void _closeQuickAdd() {
    // SystemNavigator.pop() isn't guaranteed to actually kill the task on
    // every device/Android version -- on some it just backgrounds it,
    // leaving the whole Flutter engine (and this route) alive. Popping this
    // screen off the Navigator ourselves first, before asking the system to
    // exit, means the *next* quick-add tap always finds a clean base route
    // to push onto regardless of what SystemNavigator.pop() ends up doing
    // -- this is what actually fixes the "have to back out of every payment
    // I ever quick-added" bug: without it, an un-disposed, still-mounted
    // AddTransactionScreen from last time was sitting right where the new
    // one got pushed on top of it, every time.
    Navigator.of(context).popUntil((route) => route.isFirst);
    SystemNavigator.pop();
  }

  Future<void> _delete() async {
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
    if (!confirmed) return;

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
      // Only quick-add's instance of this screen needs interception --
      // reached normally (via a ledger row's own "+" button), a plain pop
      // is exactly right, same as always.
      canPop: !widget.closeAppOnSave,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closeQuickAdd();
      },
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
        // A plain Column, not a Scaffold-managed keyboard inset -- the number
        // pad and Save bar are always-present layout, not something that
        // slides in over content the way the system IME would, so there's
        // nothing for either to ever hide behind.
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _amountController,
                              readOnly: true,
                              showCursor: true,
                              style: Theme.of(context).textTheme.headlineMedium,
                              decoration: const InputDecoration(
                                hintText: '0.00',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                final n = double.tryParse(v.trim());
                                if (n == null || n <= 0) {
                                  return 'Enter a number';
                                }
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
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (c) => setState(() => _currency = c!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('You Paid')),
                          ButtonSegment(
                            value: false,
                            label: Text('Paid to You'),
                          ),
                        ],
                        selected: {_isPayment},
                        onSelectionChanged: (s) =>
                            setState(() => _isPayment = s.first),
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
                      // Categories sit last, closest to the bottom of the
                      // scrollable content -- the control the user reaches for
                      // most, kept within easy one-thumb reach instead of up
                      // by the amount field.
                      if (_isPayment) ...[
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                            decoration: const InputDecoration(
                              hintText: 'Category',
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              _NumericKeypad(onDigit: _appendDigit, onBackspace: _backspace),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plain in-app number pad standing in for the system keyboard on this
/// screen's amount field -- see the field doc comment on
/// [_AddTransactionScreenState._amountController] for why. Four rows of
/// three: digits 1-9, then "." / 0 / backspace, each a full-width tappable
/// cell rather than a small icon-sized target.
class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({required this.onDigit, required this.onBackspace});

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows)
            Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: _KeypadKey(
                      label: key,
                      onTap: key == '⌫' ? onBackspace : () => onDigit(key),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 52,
        child: Center(
          child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
        ),
      ),
    );
  }
}

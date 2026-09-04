import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../core/models/ledger_category.dart';
import '../../../core/security/app_lock_exemption.dart';
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
  // Mutable even though it starts from widget.counterpartyId -- the "Add a
  // new ledger" option below lets this change without leaving this screen,
  // instead of the ledger being fixed for good by however this screen was
  // reached (a specific ledger row's "+", or a per-ledger quick-add
  // shortcut/widget).
  late String _counterpartyId;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _counterpartyId = widget.counterpartyId;
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
      QuickActionExemption.claim();
    }
  }

  @override
  void dispose() {
    if (widget.closeAppOnSave) {
      QuickActionExemption.release();
    }
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  /// Inserts [input] (a digit, or ".") at the amount field's current
  /// selection, matching how typing normally feels: with nothing selected
  /// this just lands at the cursor (in practice almost always the end,
  /// since every prior keypad tap leaves it collapsed there), but if the
  /// value is currently highlighted -- the field still supports the
  /// system's own tap-to-position/long-press-to-select gestures despite
  /// being `readOnly`, which was the "I mark the value and typing a number
  /// doesn't replace it" bug: this used to always append to the end
  /// regardless of what was selected -- the selected range is replaced
  /// outright instead. A lone leading "0" with nothing after it is
  /// replaced rather than prefixed (typing "5" gives "5", not "05"), and a
  /// second "." is rejected, same as [TextInputType.number]'s own decimal
  /// filtering.
  void _appendDigit(String input) {
    final text = _amountController.text;
    final selection = _amountController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    var before = text.substring(0, start);
    final after = text.substring(end);
    if (input == '.') {
      if (before.contains('.') || after.contains('.')) return;
      _setAmountText('$before.$after', caretOffset: before.length + 1);
      return;
    }
    if (before == '0' && after.isEmpty) before = '';
    _setAmountText(
      '$before$input$after',
      caretOffset: before.length + input.length,
    );
  }

  /// A single tap deletes one character -- the one just before the cursor,
  /// or the whole highlighted range if the value is currently selected
  /// (see [_appendDigit]'s doc comment for why that's possible despite
  /// `readOnly`), matching how typing over a selection works everywhere
  /// else rather than always chopping the very last character regardless
  /// of what's selected or where the cursor actually sits.
  void _backspace() {
    final text = _amountController.text;
    final selection = _amountController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final before = text.substring(0, selection.start);
      final after = text.substring(selection.end);
      _setAmountText('$before$after', caretOffset: before.length);
      return;
    }
    final caret = selection.isValid ? selection.start : text.length;
    if (caret <= 0) return;
    final before = text.substring(0, caret - 1);
    final after = text.substring(caret);
    _setAmountText('$before$after', caretOffset: before.length);
  }

  /// Long-pressing the backspace key clears the whole amount at once
  /// instead of requiring a tap per character for a long value -- the same
  /// "hold to clear" convention most calculator/numeric keypads already
  /// use.
  void _clearAmount() {
    if (_amountController.text.isEmpty) return;
    _setAmountText('');
  }

  /// Flutter's own text-selection toolbar never offers "Paste" on a
  /// `readOnly` field (see the amount `TextFormField` below) -- reasonable
  /// for a field the OS keyboard truly can't type into, but this one
  /// *does* accept programmatic edits (every keypad tap is exactly that),
  /// so there was no real reason paste couldn't work too. [_buildAmountContextMenu]
  /// adds a real "Paste" button back in; this is what it calls.
  Future<void> _pasteAmount(EditableTextState editableTextState) async {
    editableTextState.hideToolbar();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text;
    if (raw == null || raw.isEmpty) return;

    final text = _amountController.text;
    final selection = _amountController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    var before = text.substring(0, start);
    final after = text.substring(end);

    // Same one-decimal-point rule [_appendDigit] enforces one character at
    // a time -- if the field already has a '.' outside the replaced range,
    // a '.' pasted alongside it would otherwise produce something like
    // "12.5.6", which double.tryParse can't read back.
    final sanitized = _sanitizeAmountPaste(
      raw,
      allowDot: !before.contains('.') && !after.contains('.'),
    );
    if (sanitized.isEmpty) return;

    if (before == '0' && after.isEmpty) before = '';
    _setAmountText(
      '$before$sanitized$after',
      caretOffset: before.length + sanitized.length,
    );
  }

  /// Keeps only digits and (at most) one '.' from a pasted string -- e.g.
  /// copying "$1,234.56" from a bank statement pastes as "1234.56", same
  /// shape [_appendDigit] already only ever lets through one character at
  /// a time.
  String _sanitizeAmountPaste(String input, {required bool allowDot}) {
    final buffer = StringBuffer();
    var usedDot = false;
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      if (char == '.' && allowDot && !usedDot) {
        buffer.write('.');
        usedDot = true;
      } else if (RegExp(r'^[0-9]$').hasMatch(char)) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Starts from Flutter's own default menu (Copy/Select all -- everything
  /// a readOnly field normally offers) and adds a working Paste button,
  /// since this field is readOnly only to keep the OS keyboard from
  /// popping up, not because it rejects edits -- see [_pasteAmount].
  Widget _buildAmountContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final buttonItems = List<ContextMenuButtonItem>.of(
      editableTextState.contextMenuButtonItems,
    );
    final hasPaste = buttonItems.any(
      (item) => item.type == ContextMenuButtonType.paste,
    );
    if (!hasPaste) {
      buttonItems.add(
        ContextMenuButtonItem(
          type: ContextMenuButtonType.paste,
          onPressed: () => _pasteAmount(editableTextState),
        ),
      );
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  /// Setting [TextEditingController.text] on its own resets the cursor to
  /// the very start; [caretOffset] leaves it wherever the edit that just
  /// happened should logically put it (defaulting to the end, matching how
  /// every keypad tap used to always behave before edits could land
  /// mid-string).
  void _setAmountText(String text, {int? caretOffset}) {
    setState(() {
      _amountController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caretOffset ?? text.length),
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

  /// Same "add ledger" form as `LedgerHomeScreen`'s own FAB -- offered here
  /// too so a ledger that doesn't exist yet doesn't force backing all the
  /// way out to the Ledger tab, creating it there, and re-opening this
  /// screen from scratch. Selects the new ledger immediately once created.
  Future<void> _addNewLedger() async {
    final controller = TextEditingController();
    var includeInStatistics = true;
    var includeInCalculator = true;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add ledger'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Dad',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include in Statistics'),
                value: includeInStatistics,
                onChanged: (v) => setDialogState(() => includeInStatistics = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include in Calculator'),
                value: includeInCalculator,
                onChanged: (v) => setDialogState(() => includeInCalculator = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (name == null || name.isEmpty) return;

    final newId = await ref
        .read(ledgerRepositoryProvider)
        .addCounterparty(
          name,
          includeInStatistics: includeInStatistics,
          includeInCalculator: includeInCalculator,
        );
    if (mounted) setState(() => _counterpartyId = newId);
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
              counterpartyId: _counterpartyId,
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
            counterpartyId: _counterpartyId,
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
                      _LedgerPicker(
                        counterpartyId: _counterpartyId,
                        onChanged: (id) => setState(() => _counterpartyId = id),
                        onAddNew: _addNewLedger,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _amountController,
                              readOnly: true,
                              showCursor: true,
                              contextMenuBuilder: _buildAmountContextMenu,
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
              _NumericKeypad(
                onDigit: _appendDigit,
                onBackspace: _backspace,
                onClear: _clearAmount,
              ),
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

/// The "which ledger?" row at the top of the form -- a dropdown over every
/// existing ledger plus a trailing "add new" button that opens the same
/// form `LedgerHomeScreen`'s own FAB does, so a ledger that doesn't exist
/// yet doesn't force leaving this screen to create one first.
class _LedgerPicker extends ConsumerWidget {
  const _LedgerPicker({
    required this.counterpartyId,
    required this.onChanged,
    required this.onAddNew,
  });

  final String counterpartyId;
  final ValueChanged<String> onChanged;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterparties =
        ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];
    // The currently-selected id can briefly be absent from the list right
    // after this screen first opens (the stream hasn't emitted yet) or the
    // instant a brand-new ledger is created (this build can race the
    // stream's own update) -- null in either case rather than handing the
    // dropdown a value with no matching item, which would throw.
    final value = counterparties.any((c) => c.id == counterpartyId)
        ? counterpartyId
        : null;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            // DropdownButtonFormField only ever reads initialValue once, at
            // creation -- it won't notice counterpartyId changing from
            // outside the dropdown itself (specifically, right after
            // [onAddNew] creates and selects a brand-new ledger) unless the
            // widget is actually torn down and rebuilt, which keying on the
            // value itself forces. A selection made through the dropdown
            // doesn't need this (Flutter's own FormField state already
            // tracks that correctly) but remounting for it too is harmless.
            key: ValueKey('ledger-$value'),
            isExpanded: true,
            initialValue: value,
            decoration: const InputDecoration(labelText: 'Ledger'),
            items: counterparties
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (id) {
              if (id != null) onChanged(id);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: 'Add new ledger',
          onPressed: onAddNew,
        ),
      ],
    );
  }
}

/// A plain in-app number pad standing in for the system keyboard on this
/// screen's amount field -- see the field doc comment on
/// [_AddTransactionScreenState._amountController] for why. Four rows of
/// three: digits 1-9, then "." / 0 / backspace, each a full-width tappable
/// cell rather than a small icon-sized target. The backspace key alone
/// also responds to a long press -- [onClear] -- clearing the whole amount
/// at once instead of requiring a tap per character for a long value.
class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
  });

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

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
                      onLongPress: key == '⌫' ? onClear : null,
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
  const _KeypadKey({
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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

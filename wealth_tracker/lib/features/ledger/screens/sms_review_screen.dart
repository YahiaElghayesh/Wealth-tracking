import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/currency.dart';
import '../../../core/security/app_lock_exemption.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/sms/bank_charge_payload.dart';
import '../../recurring/providers/recurring_payment_providers.dart';
import '../../recurring/screens/add_recurring_payment_screen.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/ledger_providers.dart';

/// Sentinel [DropdownMenuItem] value for "this is a new recurring payment"
/// -- distinct from `null` (not recurring) and from any real
/// [RecurringPayment.id] (an existing one).
const _newRecurringSentinel = '__new_recurring__';

/// Opened when a bank-charge notification's body is tapped — either there
/// was no clean vendor-rule default, or the user wants to change the
/// suggested ledger/category before saving. Pre-filled from the parsed
/// SMS, but everything stays editable.
class SmsReviewScreen extends ConsumerStatefulWidget {
  const SmsReviewScreen({
    super.key,
    required this.payload,
    required this.wasLockedOnArrival,
  });

  final BankChargePayload payload;

  /// Whether the app was genuinely locked at the moment this charge's SMS
  /// arrived -- computed once by `processIncomingSms`, *before* it claims
  /// its own [QuickActionExemption], and passed straight through rather
  /// than re-derived here from [appUnlocked] at mount time: by the time
  /// this screen mounts, that claim (held continuously since the SMS
  /// arrived) always makes [appUnlocked] read "unlocked", regardless of
  /// what was actually true when the SMS came in.
  final bool wasLockedOnArrival;

  @override
  ConsumerState<SmsReviewScreen> createState() => _SmsReviewScreenState();
}

class _SmsReviewScreenState extends ConsumerState<SmsReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _customCategoryController = TextEditingController();
  String? _counterpartyId;
  // Null until the user taps a chip or a Vendor Rule matched -- defaults to
  // whichever category is first once the (async, user-managed) list loads,
  // computed fresh each build rather than seeded once, same pattern as
  // add_transaction_screen.dart. Fixes categories added/renamed in Settings
  // after this screen was already showing a stale hardcoded list.
  String? _category;
  List<String> _categoryNames = const ['Other'];
  late String _currency;
  late DateTime _date;
  bool _defaultLedgerApplied = false;
  // null = not recurring, [_newRecurringSentinel] = create a new recurring
  // payment after saving, or an existing RecurringPayment.id to just link
  // this charge to one already tracked (no new row created either way --
  // see [_save]).
  String? _recurringSelection;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.payload.amount.toStringAsFixed(2),
    );
    _currency = widget.payload.currency;
    _date = widget.payload.occurredAt;
    _counterpartyId = widget.payload.counterpartyId;
    _category = widget.payload.category;
    // Claimed unconditionally -- this screen is only ever reached via the
    // SMS-detected path (see the class doc comment), so it's always the
    // right thing to hold the lock exemption for as long as it's on
    // screen, same as `processIncomingSms`'s own claim that's been active
    // since the SMS arrived (this overlaps it rather than replacing it --
    // see that function's own comment for why). Not conditioned on
    // [widget.wasLockedOnArrival]: claiming while the app was genuinely
    // already unlocked is harmless (see [QuickActionExemption]'s own doc
    // comment), and gating it here would reintroduce the same
    // stale-[appUnlocked] race that flag exists to avoid.
    QuickActionExemption.claim();
  }

  @override
  void dispose() {
    QuickActionExemption.release();
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  /// Leaves this screen -- a plain pop when it was reached from an already
  /// -unlocked app (see [SmsReviewScreen.wasLockedOnArrival]), or the same
  /// close-the-app sequence [AddTransactionScreen] uses when it wasn't: a
  /// plain pop in that case would reveal the still-locked app underneath
  /// with no fresh unlock check, the exact bug this mirrors the fix for.
  void _leave() {
    if (widget.wasLockedOnArrival) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      SystemNavigator.pop();
    } else {
      Navigator.of(context).pop();
    }
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
    final selectedCategory = _category ?? _categoryNames.first;
    final category = selectedCategory == 'Other'
        ? _customCategoryController.text.trim()
        : selectedCategory;
    final resolvedCategory = category.isEmpty ? 'Other' : category;

    // Same fix as AddTransactionScreen's own save -- a custom name typed
    // after picking "Other" becomes a real, reusable LedgerCategory
    // instead of only ever existing on this one transaction.
    if (selectedCategory == 'Other' &&
        !_categoryNames.any(
          (c) => c.toLowerCase() == resolvedCategory.toLowerCase(),
        )) {
      await ref.read(ledgerCategoryRepositoryProvider).add(resolvedCategory);
    }

    await ref
        .read(ledgerRepositoryProvider)
        .addTransaction(
          counterpartyId: counterpartyId,
          date: _date,
          amount: amount,
          currency: _currency,
          category: resolvedCategory,
          source: 'sms',
        );

    if (!mounted) return;
    if (_recurringSelection == _newRecurringSentinel) {
      // Let the user name/finalize it before it's actually created --
      // AddRecurringPaymentScreen pops itself once saved (or deleted/
      // cancelled), and only then do we leave this screen too.
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddRecurringPaymentScreen(
            initialName: widget.payload.vendor,
            initialAmount: amount,
            initialCurrency: _currency,
            initialDayOfMonth: _date.day,
          ),
        ),
      );
      if (!mounted) return;
    }
    // Picking an existing recurring payment just links this charge
    // mentally to one already tracked -- it doesn't create or touch any
    // row, so nothing further to do before leaving.
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final counterparties =
        ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];
    final matchedByRule = widget.payload.counterpartyId != null;

    final categoriesAsync = ref.watch(ledgerCategoriesStreamProvider);
    _categoryNames = [
      ...categoriesAsync.valueOrNull?.map((c) => c.name) ?? const <String>[],
      'Other',
    ];
    final selectedCategory =
        (_category != null && _categoryNames.contains(_category))
        ? _category!
        : _categoryNames.first;

    // No vendor rule matched a ledger -- fall back to the Settings-picked
    // default (still just a starting point; the dropdown below stays fully
    // editable). Applied once, post-frame like the calculator screen's own
    // seeding, and only if that stored id still refers to a real ledger --
    // otherwise the dropdown would be handed a value with no matching item.
    if (!_defaultLedgerApplied &&
        _counterpartyId == null &&
        counterparties.isNotEmpty) {
      _defaultLedgerApplied = true;
      final defaultId = ref.read(defaultLedgerCounterpartyIdProvider);
      if (counterparties.any((c) => c.id == defaultId)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _counterpartyId = defaultId);
        });
      }
    }
    final validCounterpartyId =
        counterparties.any((c) => c.id == _counterpartyId)
        ? _counterpartyId
        : null;

    return PopScope(
      // Only true when this screen was itself what earned the lock
      // exemption -- reached from an already-unlocked app, backing out is
      // an ordinary pop, same as always.
      canPop: !widget.wasLockedOnArrival,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leave();
      },
      child: Scaffold(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface2,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'From SMS · ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textDim,
                          fontWeight: FontWeight.w700,
                        ),
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
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
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textDim,
                        ),
                        children: [
                          const TextSpan(text: 'at '),
                          TextSpan(
                            text: widget.payload.vendor,
                            style: TextStyle(
                              color: colors.textBody,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (matchedByRule) ...[
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.good.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: colors.good,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Matched by vendor rule',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.good,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add to which ledger?',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textDim,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: validCounterpartyId,
                items: counterparties
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _counterpartyId = v),
                validator: (v) => v == null ? 'Pick a ledger' : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Category',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textDim,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
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
                  textCapitalization: TextCapitalization.sentences,
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
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: colors.textDim,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recurring payment',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textDim,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final recurringPayments =
                      ref.watch(recurringPaymentsStreamProvider).valueOrNull ??
                      const [];
                  final validSelection =
                      _recurringSelection == null ||
                          _recurringSelection == _newRecurringSentinel ||
                          recurringPayments.any(
                            (p) => p.id == _recurringSelection,
                          )
                      ? _recurringSelection
                      : null;
                  return DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: validSelection,
                    decoration: const InputDecoration(
                      hintText: 'Not a recurring payment',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Not a recurring payment'),
                      ),
                      const DropdownMenuItem(
                        value: _newRecurringSentinel,
                        child: Text('New recurring payment'),
                      ),
                      for (final payment in recurringPayments)
                        DropdownMenuItem(
                          value: payment.id,
                          child: Text(payment.name),
                        ),
                    ],
                    onChanged: (v) => setState(() => _recurringSelection = v),
                  );
                },
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
        bottomSheet: SafeArea(
          minimum: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _leave,
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
      ),
    );
  }
}

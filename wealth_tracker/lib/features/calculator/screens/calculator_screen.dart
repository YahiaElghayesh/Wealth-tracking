import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/calculator_custom_item.dart';
import '../../../core/models/card_snapshot_entry.dart';
import '../../../core/models/currency.dart';
import '../../../core/models/manual_input_snapshot_entry.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/settings_action.dart';
import '../../../data/calculator/current_money_calculator.dart';
import '../../../data/calculator/manual_input_value_backup.dart';
import '../../../data/db/database.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../../data/repositories/calculator_repository.dart';
import '../../networth/providers/asset_providers.dart'
    show pricesUsdPerUnitProvider;
import '../../settings/screens/credit_cards_settings_screen.dart';
import '../../settings/screens/manual_inputs_settings_screen.dart';
import '../providers/calculator_providers.dart';
import 'calculator_history_screen.dart';

/// Whole numbers print without a trailing ".0" -- shared by the seeding
/// logic below and [_AdjustButton], both of which write a computed amount
/// straight into a field's text.
String _formatAmount(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _cardControllers = <String, TextEditingController>{};
  final _manualInputControllers = <String, TextEditingController>{};
  final _customItems = <CustomCalculatorItem>[];
  final _scrollController = ScrollController();

  // Cards default-prefill the first time their data arrives — to their
  // last known available balance (SMS-tracked, if bank SMS detection is
  // on; otherwise the card's own limit, "as if nothing's been spent
  // yet"). Manual inputs default-prefill from the latest saved snapshot's
  // matching-by-name entry, if any. A user edit (including clearing the
  // field back to save a snapshot) must not be overwritten on the next
  // rebuild, hence the seeded-ids set — per-id, so an item added later
  // still gets its own default without re-seeding ones already touched.
  //
  // Cards get one more thing manual inputs don't: an SMS listener can
  // update `currentAvailableBalance` in the background at any time, and
  // that write needs to reach this screen's on-screen field live, not
  // just the "Updated from SMS ..." timestamp label (which is bound
  // straight to the stream already) — otherwise the balance visibly
  // changes only after the app is fully restarted. So a card is
  // re-seeded whenever its `balanceUpdatedAt` has moved past what was
  // seeded last *and* the field still holds exactly what was seeded then
  // (i.e. the user hasn't started typing their own value over it, which
  // must never be silently clobbered).
  final _seededCardIds = <String>{};
  final _cardSeedBalanceUpdatedAt = <String, DateTime?>{};
  final _cardSeedText = <String, String>{};
  final _seededManualInputIds = <String>{};
  bool _saving = false;
  bool _scrolled = false;

  // True only while the seeding block itself is assigning `controller.text`
  // -- the field's listener can't otherwise tell that write apart from the
  // user actually typing, and only the latter should ever be persisted back
  // to the card (see _scheduleCardBalanceSave).
  bool _isSeedingCard = false;
  final _cardBalanceSaveDebounce = <String, Timer>{};

  // Same idea as _isSeedingCard/_cardBalanceSaveDebounce, for manual
  // inputs -- see ManualInput.currentValue's own doc comment (in
  // tables.dart) for the "reset itself" bug this fixes.
  bool _isSeedingManualInput = false;
  final _manualInputSaveDebounce = <String, Timer>{};

  // A second, independent copy of every manual input's last-known value --
  // see ManualInputValueBackup's own doc comment for why. Loaded once at
  // startup; seeding waits for it (see `_manualInputBackupLoaded`'s use
  // below) so a manual input is never seeded from a stale/blank value just
  // because this hadn't finished loading yet, which -- since seeding only
  // ever happens once per id -- would otherwise lock in the wrong number
  // for the rest of the session.
  Map<String, double> _manualInputBackup = {};
  bool _manualInputBackupLoaded = false;
  bool _prunedManualInputBackup = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled =
          _scrollController.hasClients && _scrollController.offset > 4;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
    ManualInputValueBackup.readAll().then((backup) {
      if (!mounted) return;
      setState(() {
        _manualInputBackup = backup;
        _manualInputBackupLoaded = true;
      });
    });
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in _cardControllers.values) {
      c.dispose();
    }
    for (final c in _manualInputControllers.values) {
      c.dispose();
    }
    for (final t in _cardBalanceSaveDebounce.values) {
      t.cancel();
    }
    for (final t in _manualInputSaveDebounce.values) {
      t.cancel();
    }
    _scrollController.dispose();
    super.dispose();
  }

  /// Persists a manual edit of [inputId]'s value field back to the manual
  /// input itself -- the same fix `_scheduleCardBalanceSave` already
  /// applies to credit cards, applied here too. Debounced so every
  /// keystroke doesn't hit the database, and skipped entirely while
  /// [_isSeedingManualInput] is true so seeding a field doesn't turn
  /// around and immediately "edit" it right back.
  void _scheduleManualInputSave(String inputId) {
    if (_isSeedingManualInput) return;
    _manualInputSaveDebounce[inputId]?.cancel();
    _manualInputSaveDebounce[inputId] = Timer(
      const Duration(milliseconds: 600),
      () => _saveManualInputValue(inputId),
    );
  }

  Future<void> _saveManualInputValue(String inputId) async {
    if (!mounted) return;
    final controller = _manualInputControllers[inputId];
    if (controller == null) return;
    final newValue = double.tryParse(controller.text.trim());
    // Leave whatever's already tracked alone rather than persisting
    // unparseable input -- a momentarily-empty field mid-edit (backspacing
    // to retype) must never wipe out a good previously-saved value.
    if (newValue == null) return;

    await ref
        .read(calculatorRepositoryProvider)
        .setManualInputCurrentValue(inputId, newValue);
    await ManualInputValueBackup.record(inputId, newValue);
    _manualInputBackup[inputId] = newValue;
  }

  /// Persists a manual edit of [cardId]'s balance field back to the card
  /// itself, so it survives a restart instead of only ever existing as
  /// this screen's in-memory snapshot input -- previously, a card's
  /// `currentAvailableBalance` was only ever written by SMS capture, so a
  /// manual edit here looked like it "took" (the field kept showing it,
  /// this session) but silently reverted to the last SMS value the next
  /// time the app opened. Debounced so every keystroke doesn't hit the
  /// database, and skipped entirely while [_isSeedingCard] is true so
  /// seeding a field from the database doesn't turn around and immediately
  /// "edit" it right back.
  void _scheduleCardBalanceSave(String cardId) {
    if (_isSeedingCard) return;
    _cardBalanceSaveDebounce[cardId]?.cancel();
    _cardBalanceSaveDebounce[cardId] = Timer(
      const Duration(milliseconds: 600),
      () => _saveCardBalance(cardId),
    );
  }

  Future<void> _saveCardBalance(String cardId) async {
    if (!mounted) return;
    final cards = ref.read(creditCardsStreamProvider).valueOrNull;
    CreditCard? card;
    for (final c in cards ?? const <CreditCard>[]) {
      if (c.id == cardId) {
        card = c;
        break;
      }
    }
    final controller = _cardControllers[cardId];
    if (card == null || controller == null) return;

    final newBalance = double.tryParse(controller.text.trim());
    // Leave whatever's already tracked alone rather than persisting
    // unparseable or unchanged input.
    if (newBalance == null || newBalance == card.currentAvailableBalance) {
      return;
    }

    final now = DateTime.now();
    await ref
        .read(calculatorRepositoryProvider)
        .updateCard(
          card.copyWith(
            currentAvailableBalance: Value(newBalance),
            balanceUpdatedAt: Value(now),
            balanceUpdatedSource: const Value('manual'),
          ),
        );
    // Keeps this screen's own seed bookkeeping in sync with what it just
    // wrote, so a later *genuine* SMS update (a newer `balanceUpdatedAt`
    // than this one) is still correctly detected as new -- without this,
    // the next rebuild would see `balanceUpdatedAt` change from under it
    // and (harmlessly, since the field's text still matches) just update
    // its bookkeeping anyway, but keeping it here in lockstep is more
    // direct than relying on that.
    _cardSeedBalanceUpdatedAt[cardId] = now;
    _cardSeedText[cardId] = controller.text;
  }

  double _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  /// Lazily creates (and wires up) a controller for [card], so newly added
  /// cards get one without disturbing controllers for cards already on
  /// screen.
  TextEditingController _cardControllerFor(CreditCard card) {
    return _cardControllers.putIfAbsent(card.id, () {
      final controller = TextEditingController();
      controller.addListener(_onFieldChanged);
      controller.addListener(() => _scheduleCardBalanceSave(card.id));
      return controller;
    });
  }

  TextEditingController _manualInputControllerFor(ManualInput input) {
    return _manualInputControllers.putIfAbsent(input.id, () {
      final controller = TextEditingController();
      controller.addListener(_onFieldChanged);
      controller.addListener(() => _scheduleManualInputSave(input.id));
      return controller;
    });
  }

  /// Owed amount per card, in the card's own currency (not yet converted).
  double _owedFor(CreditCard card) {
    return cardOwedAmount(
      limit: card.limitAmount,
      availableBalance: _parse(_cardControllerFor(card)),
    );
  }

  /// [_owedFor] converted to the app's settlement currency — falls back to
  /// the raw, unconverted figure if no FX rate is available yet, rather
  /// than silently dropping the card from the total.
  double _owedInDefaultCurrency(CreditCard card, Map<String, double> prices) {
    final owed = _owedFor(card);
    if (card.currency == defaultCurrency) return owed;
    return convertToSettlement(owed, card.currency, prices) ?? owed;
  }

  double _manualInputSignedAmount(
    ManualInput input,
    Map<String, double> prices,
  ) {
    final raw = _parse(_manualInputControllerFor(input));
    final converted = input.currency == defaultCurrency
        ? raw
        : (convertToSettlement(raw, input.currency, prices) ?? raw);
    return input.isAddition ? converted : -converted;
  }

  Future<void> _addCustomItem() async {
    final labelController = TextEditingController();
    final amountController = TextEditingController();
    var isAddition = true;

    final item = await showDialog<CustomCalculatorItem>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'What is it?'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Add (+)')),
                  ButtonSegment(value: false, label: Text('Subtract (−)')),
                ],
                selected: {isAddition},
                onSelectionChanged: (s) =>
                    setDialogState(() => isAddition = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                final label = labelController.text.trim();
                if (amount == null || amount <= 0 || label.isEmpty) return;
                Navigator.pop(
                  context,
                  CustomCalculatorItem(
                    label: label,
                    amount: amount,
                    isAddition: isAddition,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (item != null) setState(() => _customItems.add(item));
  }

  Future<void> _save(
    double ledgersTotal,
    List<CreditCard> cards,
    List<ManualInput> manualInputs,
    Map<String, double> prices,
  ) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final cardOwedAmounts = [
        for (final card in cards) _owedInDefaultCurrency(card, prices),
      ];
      final manualInputAmounts = [
        for (final input in manualInputs)
          _manualInputSignedAmount(input, prices),
      ];
      final result = calculateCurrentMoney(
        ledgersTotal: ledgersTotal,
        cardOwedAmounts: cardOwedAmounts,
        manualInputAmounts: manualInputAmounts,
        customItems: _customItems,
      );

      final cardEntries = [
        for (final card in cards)
          CardSnapshotEntry(
            name: card.name,
            bank: card.bank,
            currency: card.currency,
            limit: card.limitAmount,
            availableBalance: _parse(_cardControllerFor(card)),
            owed: _owedFor(card),
          ),
      ];
      final manualInputEntries = [
        for (final input in manualInputs)
          ManualInputSnapshotEntry(
            name: input.name,
            amount: _parse(_manualInputControllerFor(input)),
            isAddition: input.isAddition,
            currency: input.currency,
          ),
      ];

      await ref
          .read(calculatorRepositoryProvider)
          .saveSnapshot(
            resultAmount: result,
            ledgersTotal: ledgersTotal,
            cardEntries: cardEntries,
            manualInputEntries: manualInputEntries,
            customItems: _customItems,
          );

      if (!mounted) return;
      setState(() {
        _customItems.clear();
        _saving = false;
        // Re-seed cards back to their limits on the next build -- their
        // seeding reads creditCardsStreamProvider directly, which this save
        // never touches, so there's no race to worry about there.
        //
        // Manual inputs are deliberately NOT cleared the same way. Their
        // seeding reads calculatorHistoryStreamProvider's latest entry --
        // the exact stream this save just wrote a new row to -- and that
        // stream's own async update is not guaranteed to have arrived by
        // the time the next build's post-frame callback runs. Clearing
        // here raced it and usually lost: the callback fired first,
        // re-seeded from the *previous* (pre-save) snapshot instead of
        // this one, and marked itself seeded before the real update ever
        // landed -- silently overwriting what the user just typed and
        // saved with a stale older value (the reported "manual input
        // reverted to an old number by itself" bug). Every manual input's
        // controller already holds exactly what was just saved -- that's
        // literally where manualInputEntries above came from -- so nothing
        // needs to change; leaving _seededManualInputIds alone here is what
        // actually keeps it that way.
        _seededCardIds.clear();
      });

      final savedAt = TimeOfDay.now();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Saved · Recorded to history at ${savedAt.format(context)}'),
            ],
          ),
          backgroundColor: context.appColors.good,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: context.appColors.bad,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(creditCardsStreamProvider);
    final manualInputsAsync = ref.watch(manualInputsStreamProvider);
    final ledgersTotal = ref.watch(ledgersTotalProvider);
    final historyAsync = ref.watch(calculatorHistoryStreamProvider);
    final prices = ref.watch(pricesUsdPerUnitProvider);

    final latestHistory = historyAsync.valueOrNull;
    final currentCards = cardsAsync.valueOrNull;
    final currentManualInputs = manualInputsAsync.valueOrNull;
    final cardsNeedingSeed = currentCards?.where((c) {
      if (!_seededCardIds.contains(c.id)) return true;
      if (c.balanceUpdatedAt == _cardSeedBalanceUpdatedAt[c.id]) return false;
      return _cardControllerFor(c).text == _cardSeedText[c.id];
    }).toList();
    if (currentManualInputs != null &&
        _manualInputBackupLoaded &&
        !_prunedManualInputBackup) {
      _prunedManualInputBackup = true;
      unawaited(
        ManualInputValueBackup.pruneToLiveIds(
          currentManualInputs.map((m) => m.id).toSet(),
        ),
      );
    }
    // Waits for the backup to finish loading (see `_manualInputBackup`'s
    // own doc comment) before seeding anything, since seeding only ever
    // happens once per id.
    final unseededManualInputs =
        (currentManualInputs != null && _manualInputBackupLoaded)
        ? currentManualInputs
              .where((m) => !_seededManualInputIds.contains(m.id))
              .toList()
        : null;
    final needsSeeding =
        (cardsNeedingSeed != null && cardsNeedingSeed.isNotEmpty) ||
        (unseededManualInputs != null && unseededManualInputs.isNotEmpty);
    if (needsSeeding) {
      // Setting controller.text synchronously here would fire the field
      // listener (which calls setState) mid-build, which Flutter forbids —
      // defer the actual seeding to right after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (cardsNeedingSeed != null) {
            _isSeedingCard = true;
            for (final card in cardsNeedingSeed) {
              final text = _formatAmount(
                card.currentAvailableBalance ?? card.limitAmount,
              );
              _cardControllerFor(card).text = text;
              _seededCardIds.add(card.id);
              _cardSeedBalanceUpdatedAt[card.id] = card.balanceUpdatedAt;
              _cardSeedText[card.id] = text;
            }
            _isSeedingCard = false;
          }
          if (unseededManualInputs != null) {
            _isSeedingManualInput = true;
            final latest = latestHistory != null && latestHistory.isNotEmpty
                ? latestHistory.first
                : null;
            for (final input in unseededManualInputs) {
              final lastEntry = latest?.manualInputEntries
                  .where((e) => e.name == input.name)
                  .firstOrNull;
              // Falls back to the fixed legacy apartmentSavings/
              // cibAccountBalance columns, by their known fixed names, when
              // the latest snapshot predates user-managed manual inputs
              // (manualInputEntries is always empty then -- see
              // usesLegacyFixedManualInputs's own doc comment).
              final snapshotFallback =
                  lastEntry?.amount ??
                  (latest != null && latest.usesLegacyFixedManualInputs
                      ? switch (input.name) {
                          'Apartment savings' => latest.apartmentSavings,
                          'CIB Accounts Balance' => latest.cibAccountBalance,
                          _ => null,
                        }
                      : null);
              final backedUp = _manualInputBackup[input.id];
              // input.currentValue -- the actually-persisted column, kept
              // live by _saveManualInputValue -- comes first; the
              // independent backup and the last-saved-snapshot fallback
              // only matter for a row this device hasn't typed into
              // directly yet (a fresh install/upgrade, or one restored
              // from the backup after the column itself was lost -- see
              // ManualInputValueBackup's own doc comment).
              final seedAmount =
                  input.currentValue ?? backedUp ?? snapshotFallback;
              if (seedAmount != null && seedAmount != 0) {
                _manualInputControllerFor(input).text = _formatAmount(
                  seedAmount,
                );
              }
              // Self-heal: whenever the resolved value didn't already come
              // from the persisted column itself, write it back there (and
              // keep the backup in lockstep) so it isn't lost again next
              // time -- exactly the gap that let this reset in the first
              // place.
              if (seedAmount != null && input.currentValue != seedAmount) {
                unawaited(
                  ref
                      .read(calculatorRepositoryProvider)
                      .setManualInputCurrentValue(input.id, seedAmount),
                );
              }
              if (seedAmount != null && backedUp != seedAmount) {
                _manualInputBackup[input.id] = seedAmount;
                unawaited(ManualInputValueBackup.record(input.id, seedAmount));
              }
              _seededManualInputIds.add(input.id);
            }
            _isSeedingManualInput = false;
          }
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          const HideValuesAction(),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CalculatorHistoryScreen(),
              ),
            ),
          ),
          const SettingsAction(),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (cards) {
          final manualInputs = currentManualInputs ?? const <ManualInput>[];
          final cardOwedAmounts = [
            for (final card in cards) _owedInDefaultCurrency(card, prices),
          ];
          final manualInputAmounts = [
            for (final input in manualInputs)
              _manualInputSignedAmount(input, prices),
          ];
          final result = calculateCurrentMoney(
            ledgersTotal: ledgersTotal,
            cardOwedAmounts: cardOwedAmounts,
            manualInputAmounts: manualInputAmounts,
            customItems: _customItems,
          );

          return Column(
            children: [
              _StickyTotalCard(result: result, scrolled: _scrolled),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _Section(
                      title: 'Ledgers',
                      children: [
                        _SignedRow(
                          isAddition: true,
                          label: 'All ledgers combined',
                          trailing: MoneyText(
                            formatMoney(ledgersTotal, defaultCurrency),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Manual inputs',
                      subtitle: manualInputs.isEmpty
                          ? 'No manual inputs yet — add one in Settings.'
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Manage manual inputs',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ManualInputsSettingsScreen(),
                          ),
                        ),
                      ),
                      children: [
                        for (final input in manualInputs) ...[
                          _SignedAmountField(
                            // Stable across a rebuild that merely flips this
                            // input from unseeded to seeded -- an earlier
                            // version of this key included that seeded flag,
                            // which meant the moment the post-frame seeding
                            // callback ran (right after this field first
                            // appears), Flutter saw a changed Key and tore
                            // down and rebuilt this field's Element (and its
                            // FocusNode/EditableText) from scratch. If the
                            // user had already tapped in and started typing
                            // by then -- easy to do, since seeding fires on
                            // the very next frame -- that remount could
                            // silently drop what they were typing or yank
                            // focus mid-entry (the reported "manual input
                            // clears on its own" bug). The controller itself
                            // already survives across rebuilds via
                            // [_manualInputControllerFor]'s id-keyed map, so
                            // nothing here needs a key tied to seeding at all.
                            key: ValueKey('manual-${input.id}'),
                            isAddition: input.isAddition,
                            label: input.name,
                            controller: _manualInputControllerFor(input),
                            currency: input.currency,
                          ),
                          if (input != manualInputs.last)
                            const SizedBox(height: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Credit cards',
                      subtitle: cards.isEmpty
                          ? 'No cards yet — add one in Settings.'
                          : 'Enter the balance still available to spend, as shown in your banking '
                                'app — not what you owe.',
                      trailing: IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Manage cards',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreditCardsSettingsScreen(),
                          ),
                        ),
                      ),
                      children: [
                        for (final card in cards) ...[
                          _CardField(
                            card: card,
                            controller: _cardControllerFor(card),
                            owed: _owedFor(card),
                            rateMissing:
                                card.currency != defaultCurrency &&
                                convertToSettlement(0, card.currency, prices) ==
                                    null,
                          ),
                          if (card != cards.last) const SizedBox(height: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Other',
                      subtitle: 'Anything else — plus or minus.',
                      children: [
                        for (var i = 0; i < _customItems.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SignedRow(
                              isAddition: _customItems[i].isAddition,
                              label: _customItems[i].label,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MoneyText(
                                    formatMoney(
                                      _customItems[i].amount,
                                      defaultCurrency,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () => setState(
                                      () => _customItems.removeAt(i),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add item'),
                          onPressed: _addCustomItem,
                        ),
                      ],
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: cardsAsync.hasValue
          ? _SaveBar(
              saving: _saving,
              onPressed: () => _save(
                ledgersTotal,
                cardsAsync.value!,
                currentManualInputs ?? const [],
                prices,
              ),
            )
          : null,
    );
  }
}

/// The mockup's "sticky-total" card — pinned above the scrollable form
/// instead of scrolling away with it, since that's the one number this
/// whole screen exists to answer. Picks up a shadow once the form beneath
/// it has scrolled, matching the mockup's `.scrolled` state.
class _StickyTotalCard extends StatelessWidget {
  const _StickyTotalCard({required this.result, required this.scrolled});

  final double result;
  final bool scrolled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.28),
        ),
        boxShadow: scrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'CURRENT LIQUID CASH',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          MoneyText(
            formatMoney(result, defaultCurrency),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maskLength: 9,
          ),
        ],
      ),
    );
  }
}

/// Sticky, accent-filled bar pinned to the bottom of the screen (outside
/// the scrollable form) so it's always reachable, matching the mockup's
/// `.save-bar`.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: saving ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (saving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.save_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    saving ? 'Saving…' : 'Save calculation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled, bordered group — makes it visually obvious where one set of
/// inputs ends and the next begins.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Small colored +/- badge so it's unambiguous whether a line adds to or
/// subtracts from the total.
class _SignBadge extends StatelessWidget {
  const _SignBadge({required this.isAddition});

  final bool isAddition;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isAddition ? colors.good : colors.bad;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        isAddition ? '+' : '−',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _SignedRow extends StatelessWidget {
  const _SignedRow({
    required this.isAddition,
    required this.label,
    required this.trailing,
  });

  final bool isAddition;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SignBadge(isAddition: isAddition),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        trailing,
      ],
    );
  }
}

class _SignedAmountField extends ConsumerWidget {
  const _SignedAmountField({
    super.key,
    required this.isAddition,
    required this.label,
    required this.controller,
    required this.currency,
  });

  final bool isAddition;
  final String label;
  final TextEditingController controller;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideValues = ref.watch(hideValuesProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SignBadge(isAddition: isAddition),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectAllOnFocusField(
            key: key,
            controller: controller,
            decoration: InputDecoration(
              labelText: hideValues ? '••••••' : label,
              hintText: '0.00',
              suffixText: currency,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            obscureText: hideValues,
          ),
        ),
        _AdjustButton(controller: controller, currency: currency),
      ],
    );
  }
}

/// A small icon button next to a manual-input or credit-card-balance field
/// that adds or subtracts a delta from whatever the field currently holds,
/// instead of the user having to do that arithmetic themselves and retype
/// the whole new total -- e.g. "I know I spent 200 more since I last set
/// this" becomes entering "200" and picking Subtract, not computing and
/// typing the resulting balance by hand.
class _AdjustButton extends StatelessWidget {
  const _AdjustButton({required this.controller, required this.currency});

  final TextEditingController controller;
  final String currency;

  Future<void> _adjust(BuildContext context) async {
    final delta = await _showAdjustDialog(context, currency);
    if (delta == null) return;
    final current = double.tryParse(controller.text.trim()) ?? 0;
    final text = _formatAmount(current + delta);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.exposure, size: 20),
      tooltip: 'Add or subtract',
      onPressed: () => _adjust(context),
    );
  }
}

/// Prompts for an amount and a +/- sign, returning the signed delta (never
/// zero, never null unless canceled) -- shared by every [_AdjustButton].
Future<double?> _showAdjustDialog(BuildContext context, String currency) {
  final amountController = TextEditingController();
  var isAddition = true;
  return showDialog<double>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Add or subtract'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                suffixText: currency,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Add (+)')),
                ButtonSegment(value: false, label: Text('Subtract (−)')),
              ],
              selected: {isAddition},
              onSelectionChanged: (s) =>
                  setDialogState(() => isAddition = s.first),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;
              Navigator.pop(context, isAddition ? amount : -amount);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    ),
  );
}

/// A numeric field that selects its entire current value the moment it
/// gains focus, so a default-prefilled value (a card's limit, a manual
/// input's last saved figure...) is replaced by simply typing over it —
/// tapping away without typing leaves the value untouched, since only the
/// selection highlight changes, not the text itself.
///
/// [obscureText] masks the typed digits behind bullets (same convention as
/// every other money value in the app under Hide values) without disabling
/// editing — same trick `TextField.obscureText` already gives password
/// fields.
class _SelectAllOnFocusField extends StatefulWidget {
  const _SelectAllOnFocusField({
    super.key,
    required this.controller,
    this.decoration,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  State<_SelectAllOnFocusField> createState() => _SelectAllOnFocusFieldState();
}

class _SelectAllOnFocusFieldState extends State<_SelectAllOnFocusField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      obscuringCharacter: '•',
    );
  }
}

/// A short, human "how long ago" label for a card's SMS-tracked balance —
/// e.g. "just now" / "12m ago" / "3h ago" / "2d ago".
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// The mockup's "cc-card" pattern: name·bank + limit header, an available-
/// balance input, and a read-only/dashed "Owed" field the app computes.
class _CardField extends ConsumerWidget {
  const _CardField({
    required this.card,
    required this.controller,
    required this.owed,
    required this.rateMissing,
  });

  final CreditCard card;
  final TextEditingController controller;
  final double owed;
  final bool rateMissing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final hideValues = ref.watch(hideValuesProvider);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hideValues ? '••••••' : '${card.name} · ${card.bank}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              MoneyText(
                'Limit ${formatMoney(card.limitAmount, card.currency)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textDim,
                ),
                maskLength: 12,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _SelectAllOnFocusField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Available balance (${card.currency})',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  obscureText: hideValues,
                ),
              ),
              _AdjustButton(controller: controller, currency: card.currency),
            ],
          ),
          if (card.balanceUpdatedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              // balanceUpdatedSource is null only for a card whose balance
              // predates that column (updated before this distinction
              // existed) -- "Updated" alone rather than a guessed source.
              switch (card.balanceUpdatedSource) {
                'sms' =>
                  'Updated from SMS ${_relativeTime(card.balanceUpdatedAt!)}',
                'manual' =>
                  'Updated manually ${_relativeTime(card.balanceUpdatedAt!)}',
                _ => 'Updated ${_relativeTime(card.balanceUpdatedAt!)}',
              },
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Text(
                  rateMissing
                      ? 'Owed (no exchange rate yet, unconverted)'
                      : 'Owed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textDim,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                MoneyText(
                  formatMoney(owed, card.currency),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.bad,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

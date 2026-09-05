import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/calculator_custom_item.dart';
import '../../core/models/card_snapshot_entry.dart';
import '../../core/models/manual_input_snapshot_entry.dart';
import '../db/database.dart';

/// Scoped to one [profileId] -- see `AssetRepository`'s doc comment for the
/// pattern (every query filters to it, every insert stamps it, the provider
/// rebuilds on profile switch).
class CalculatorRepository {
  CalculatorRepository(this._db, this.profileId);

  final AppDatabase _db;
  final String profileId;
  static const _uuid = Uuid();

  Stream<List<CreditCard>> watchCards() {
    return (_db.select(_db.creditCards)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<void> addCard({
    required String name,
    required String bank,
    required double limit,
    required String currency,
    String? lastFourDigits,
  }) async {
    final count = await (_db.select(
      _db.creditCards,
    )..where((t) => t.profileId.equals(profileId))).get();
    await _db
        .into(_db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            id: _uuid.v4(),
            name: name,
            bank: bank,
            limitAmount: limit,
            currency: Value(currency),
            sortOrder: Value(count.length),
            lastFourDigits: Value(lastFourDigits),
            profileId: Value(profileId),
          ),
        );
  }

  Future<void> updateCard(CreditCard card) {
    return _db.update(_db.creditCards).replace(card);
  }

  Future<void> deleteCard(String id) {
    return (_db.delete(_db.creditCards)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<ManualInput>> watchManualInputs() {
    return (_db.select(_db.manualInputs)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<void> addManualInput({
    required String name,
    required bool isAddition,
    required String currency,
  }) async {
    final count = await (_db.select(
      _db.manualInputs,
    )..where((t) => t.profileId.equals(profileId))).get();
    await _db
        .into(_db.manualInputs)
        .insert(
          ManualInputsCompanion.insert(
            id: _uuid.v4(),
            name: name,
            isAddition: isAddition,
            currency: Value(currency),
            sortOrder: Value(count.length),
            profileId: Value(profileId),
          ),
        );
  }

  Future<void> updateManualInput(ManualInput input) {
    return _db.update(_db.manualInputs).replace(input);
  }

  /// Sets just [currentValue], as a single narrow-field write rather than a
  /// full-row [updateManualInput]/`.replace()` -- used by
  /// CalculatorScreen's debounced save-back (mirroring
  /// `CalculatorRepository.updateCard`'s own doc comment for
  /// [CreditCards.currentAvailableBalance]) so a rapid edit never risks
  /// clobbering the input's name/sign/currency/sortOrder with a stale
  /// snapshot of them.
  Future<void> setManualInputCurrentValue(String id, double? currentValue) {
    return (_db.update(_db.manualInputs)..where((t) => t.id.equals(id))).write(
      ManualInputsCompanion(currentValue: Value(currentValue)),
    );
  }

  Future<void> deleteManualInput(String id) {
    return (_db.delete(_db.manualInputs)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<CalculatorSnapshot>> watchSnapshots() {
    return (_db.select(_db.calculatorSnapshots)
          ..where((s) => s.profileId.equals(profileId))
          ..orderBy([(s) => OrderingTerm.desc(s.computedAt)]))
        .watch();
  }

  Future<void> saveSnapshot({
    required double resultAmount,
    required double ledgersTotal,
    required List<CardSnapshotEntry> cardEntries,
    required List<ManualInputSnapshotEntry> manualInputEntries,
    required List<CustomCalculatorItem> customItems,
  }) {
    return _db
        .into(_db.calculatorSnapshots)
        .insert(
          CalculatorSnapshotsCompanion.insert(
            id: _uuid.v4(),
            computedAt: DateTime.now(),
            resultAmount: resultAmount,
            ledgersTotal: ledgersTotal,
            // Fixed legacy columns (apartmentSavings/cibAccountBalance) are
            // only ever populated by pre-upgrade history; every new
            // snapshot leaves them at their defaults and carries its data
            // in cardEntriesJson/manualInputEntriesJson instead.
            apartmentSavings: 0.0,
            cibAccountBalance: 0.0,
            customItemsJson: Value(
              jsonEncode(customItems.map((c) => c.toJson()).toList()),
            ),
            cardEntriesJson: Value(
              jsonEncode(cardEntries.map((c) => c.toJson()).toList()),
            ),
            manualInputEntriesJson: Value(
              jsonEncode(manualInputEntries.map((e) => e.toJson()).toList()),
            ),
            // Unconditionally true -- this snapshot's card/manual-input
            // lists are authoritative even when genuinely empty (e.g. a
            // profile with zero cards configured), unlike a pre-migration
            // row where emptiness meant "the feature didn't exist yet".
            cardsRecorded: const Value(true),
            manualInputsRecorded: const Value(true),
            profileId: Value(profileId),
          ),
        );
  }

  Future<void> deleteSnapshot(String id) {
    return (_db.delete(
      _db.calculatorSnapshots,
    )..where((s) => s.id.equals(id))).go();
  }
}

extension CalculatorSnapshotCustomItems on CalculatorSnapshot {
  List<CustomCalculatorItem> get customItems {
    final decoded = jsonDecode(customItemsJson);
    if (decoded is! List) return const [];
    return decoded
        .cast<Map<String, dynamic>>()
        .map(CustomCalculatorItem.fromJson)
        .toList();
  }

  List<CardSnapshotEntry> get cardEntries {
    final decoded = jsonDecode(cardEntriesJson);
    if (decoded is! List) return const [];
    return decoded
        .cast<Map<String, dynamic>>()
        .map(CardSnapshotEntry.fromJson)
        .toList();
  }

  List<ManualInputSnapshotEntry> get manualInputEntries {
    final decoded = jsonDecode(manualInputEntriesJson);
    if (decoded is! List) return const [];
    return decoded
        .cast<Map<String, dynamic>>()
        .map(ManualInputSnapshotEntry.fromJson)
        .toList();
  }

  /// True for a snapshot saved before user-managed cards existed — its
  /// card data lives in the fixed nbe/cib* columns instead of
  /// [cardEntries], which the history screen needs to know to render it.
  /// Driven by [CalculatorSnapshot.cardsRecorded] rather than
  /// `cardEntries.isEmpty` -- an empty list is genuinely ambiguous on its
  /// own (a profile with zero cards configured produces the exact same
  /// empty list a pre-migration snapshot does), see that column's doc
  /// comment in tables.dart.
  bool get usesLegacyFixedCardColumns => !cardsRecorded;

  /// Same idea as [usesLegacyFixedCardColumns], for [manualInputEntries]
  /// and [CalculatorSnapshot.manualInputsRecorded].
  bool get usesLegacyFixedManualInputs => !manualInputsRecorded;

  /// True when every one of the three fixed legacy card columns is exactly
  /// zero -- the signal the history screen uses to tell a genuinely-legacy
  /// row (which always carried real owed figures) apart from a brand-new,
  /// empty profile's snapshot that the v16 migration's isEmpty-based
  /// backfill couldn't tell apart from legacy data (see that column's doc
  /// comment in tables.dart). Real legacy history essentially never has
  /// all three at exactly 0.
  bool get legacyCardsAreAllZero =>
      nbeOwed == 0 && cibExplorerWalletOwed == 0 && cibPlatinumOwed == 0;

  /// Same idea as [legacyCardsAreAllZero], for the two fixed legacy
  /// manual-input columns.
  bool get legacyManualInputsAreAllZero =>
      apartmentSavings == 0 && cibAccountBalance == 0;
}

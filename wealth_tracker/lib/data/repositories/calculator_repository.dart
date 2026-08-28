import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/calculator_custom_item.dart';
import '../../core/models/card_snapshot_entry.dart';
import '../db/database.dart';

class CalculatorRepository {
  CalculatorRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<CreditCard>> watchCards() {
    return (_db.select(_db.creditCards)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();
  }

  Future<void> addCard({
    required String name,
    required String bank,
    required double limit,
    required String currency,
  }) async {
    final count = await _db.select(_db.creditCards).get();
    await _db.into(_db.creditCards).insert(
          CreditCardsCompanion.insert(
            id: _uuid.v4(),
            name: name,
            bank: bank,
            limitAmount: limit,
            currency: Value(currency),
            sortOrder: Value(count.length),
          ),
        );
  }

  Future<void> updateCard(CreditCard card) {
    return _db.update(_db.creditCards).replace(card);
  }

  Future<void> deleteCard(String id) {
    return (_db.delete(_db.creditCards)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<CalculatorSnapshot>> watchSnapshots() {
    return (_db.select(_db.calculatorSnapshots)
          ..orderBy([(s) => OrderingTerm.desc(s.computedAt)]))
        .watch();
  }

  Future<void> saveSnapshot({
    required double resultAmount,
    required double ledgersTotal,
    required double apartmentSavings,
    required double cibAccountBalance,
    required List<CardSnapshotEntry> cardEntries,
    required List<CustomCalculatorItem> customItems,
  }) {
    return _db.into(_db.calculatorSnapshots).insert(
          CalculatorSnapshotsCompanion.insert(
            id: _uuid.v4(),
            computedAt: DateTime.now(),
            resultAmount: resultAmount,
            ledgersTotal: ledgersTotal,
            apartmentSavings: apartmentSavings,
            cibAccountBalance: cibAccountBalance,
            // Fixed legacy columns are only ever populated by pre-upgrade
            // history; every new snapshot leaves them at their defaults
            // and carries its cards in cardEntriesJson instead.
            customItemsJson: Value(jsonEncode(customItems.map((c) => c.toJson()).toList())),
            cardEntriesJson: Value(jsonEncode(cardEntries.map((c) => c.toJson()).toList())),
          ),
        );
  }

  Future<void> deleteSnapshot(String id) {
    return (_db.delete(_db.calculatorSnapshots)..where((s) => s.id.equals(id))).go();
  }
}

extension CalculatorSnapshotCustomItems on CalculatorSnapshot {
  List<CustomCalculatorItem> get customItems {
    final decoded = jsonDecode(customItemsJson);
    if (decoded is! List) return const [];
    return decoded.cast<Map<String, dynamic>>().map(CustomCalculatorItem.fromJson).toList();
  }

  List<CardSnapshotEntry> get cardEntries {
    final decoded = jsonDecode(cardEntriesJson);
    if (decoded is! List) return const [];
    return decoded.cast<Map<String, dynamic>>().map(CardSnapshotEntry.fromJson).toList();
  }

  /// True for a snapshot saved before user-managed cards existed — its
  /// card data lives in the fixed nbe/cib* columns instead of
  /// [cardEntries], which the history screen needs to know to render it.
  bool get usesLegacyFixedCardColumns => cardEntries.isEmpty;
}

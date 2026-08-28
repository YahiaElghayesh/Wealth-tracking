import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/calculator_card.dart';
import '../../core/models/calculator_custom_item.dart';
import '../db/database.dart';

class CalculatorRepository {
  CalculatorRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<Map<CalculatorCard, double>> watchCardLimits() {
    return _db.select(_db.calculatorInputs).watch().map((rows) {
      final byKey = {for (final row in rows) row.key: row.value};
      return {for (final card in CalculatorCard.values) card: byKey[card.storageKey] ?? card.defaultLimit};
    });
  }

  Future<void> setCardLimit(CalculatorCard card, double limit) {
    return _db.into(_db.calculatorInputs).insertOnConflictUpdate(
          CalculatorInputsCompanion.insert(
            key: card.storageKey,
            value: limit,
            updatedAt: DateTime.now(),
          ),
        );
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
    required double nbeAvailable,
    required double nbeOwed,
    required double cibExplorerWalletAvailable,
    required double cibExplorerWalletOwed,
    required double cibPlatinumAvailable,
    required double cibPlatinumOwed,
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
            nbeAvailable: nbeAvailable,
            nbeOwed: nbeOwed,
            cibExplorerWalletAvailable: cibExplorerWalletAvailable,
            cibExplorerWalletOwed: cibExplorerWalletOwed,
            cibPlatinumAvailable: cibPlatinumAvailable,
            cibPlatinumOwed: cibPlatinumOwed,
            customItemsJson: Value(jsonEncode(customItems.map((c) => c.toJson()).toList())),
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
}

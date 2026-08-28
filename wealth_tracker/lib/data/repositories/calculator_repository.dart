import '../../core/models/calculator_input.dart';
import '../db/database.dart';

class CalculatorRepository {
  CalculatorRepository(this._db);

  final AppDatabase _db;

  Stream<Map<CalculatorInputKey, double>> watchAll() {
    return _db.select(_db.calculatorInputs).watch().map((rows) {
      final result = <CalculatorInputKey, double>{};
      for (final row in rows) {
        final input = CalculatorInputKey.fromStorageKey(row.key);
        if (input != null) result[input] = row.value;
      }
      return result;
    });
  }

  Future<void> setValue(CalculatorInputKey input, double value) {
    return _db.into(_db.calculatorInputs).insertOnConflictUpdate(
          CalculatorInputsCompanion.insert(
            key: input.storageKey,
            value: value,
            updatedAt: DateTime.now(),
          ),
        );
  }
}

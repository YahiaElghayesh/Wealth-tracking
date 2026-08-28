import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/core/models/calculator_input.dart';
import 'package:wealth_tracker/data/calculator/current_money_calculator.dart';

void main() {
  group('calculateCurrentMoney', () {
    test('applies the full formula: ledgers - apartment - cards + CIB balance', () {
      final result = calculateCurrentMoney(
        ledgersTotal: 20000,
        inputs: {
          CalculatorInputKey.apartmentSavings: 5000,
          CalculatorInputKey.cibAccountBalance: 3000,
          CalculatorInputKey.cardNbe: 1000,
          CalculatorInputKey.cardCibExplorerWallet: 500,
          CalculatorInputKey.cardCibPlatinum: 200,
        },
      );

      // 20000 - 5000 - (1000 + 500 + 200) + 3000
      expect(result, closeTo(16300, 0.001));
    });

    test('missing inputs are treated as zero rather than throwing', () {
      final result = calculateCurrentMoney(ledgersTotal: 1000, inputs: {});

      expect(result, closeTo(1000, 0.001));
    });

    test('negative ledgers total (user owes overall) still works', () {
      final result = calculateCurrentMoney(
        ledgersTotal: -500,
        inputs: {CalculatorInputKey.cibAccountBalance: 200},
      );

      expect(result, closeTo(-300, 0.001));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/core/models/calculator_custom_item.dart';
import 'package:wealth_tracker/data/calculator/current_money_calculator.dart';

void main() {
  group('cardOwedAmount', () {
    test('derives owed from limit minus the available-to-spend balance', () {
      expect(cardOwedAmount(limit: 109900, availableBalance: 100000), closeTo(9900, 0.001));
    });

    test('a fully-paid-off card (available == limit) owes nothing', () {
      expect(cardOwedAmount(limit: 500000, availableBalance: 500000), closeTo(0, 0.001));
    });
  });

  group('calculateCurrentMoney', () {
    test('applies the full formula: ledgers - cards owed + manual inputs', () {
      final result = calculateCurrentMoney(
        ledgersTotal: 20000,
        cardOwedAmounts: [1000, 500, 200],
        manualInputAmounts: [-5000, 3000],
      );

      // 20000 - (1000 + 500 + 200) + (-5000 + 3000)
      expect(result, closeTo(16300, 0.001));
    });

    test('no cards is treated as zero owed rather than throwing', () {
      final result = calculateCurrentMoney(
        ledgersTotal: 1000,
        cardOwedAmounts: const [],
        manualInputAmounts: const [],
      );

      expect(result, closeTo(1000, 0.001));
    });

    test('negative ledgers total (user owes overall) still works', () {
      final result = calculateCurrentMoney(
        ledgersTotal: -500,
        cardOwedAmounts: const [],
        manualInputAmounts: const [200],
      );

      expect(result, closeTo(-300, 0.001));
    });

    test('custom items apply their sign to the total', () {
      final result = calculateCurrentMoney(
        ledgersTotal: 1000,
        cardOwedAmounts: const [],
        manualInputAmounts: const [],
        customItems: const [
          CustomCalculatorItem(label: 'Bonus', amount: 300, isAddition: true),
          CustomCalculatorItem(label: 'Fine', amount: 100, isAddition: false),
        ],
      );

      // 1000 + 300 - 100
      expect(result, closeTo(1200, 0.001));
    });

    test('a mixed-sign manual inputs list sums correctly', () {
      final result = calculateCurrentMoney(
        ledgersTotal: 0,
        cardOwedAmounts: const [],
        manualInputAmounts: const [-1000, 500, -250, 4000],
      );

      // -1000 + 500 - 250 + 4000
      expect(result, closeTo(3250, 0.001));
    });

    test('bank account balances are always added, on top of everything else', () {
      final result = calculateCurrentMoney(
        ledgersTotal: 1000,
        cardOwedAmounts: const [200],
        manualInputAmounts: const [-100],
        bankAccountAmounts: const [500, 250],
      );

      // 1000 - 200 - 100 + (500 + 250)
      expect(result, closeTo(1450, 0.001));
    });

    test('no bank accounts defaults to zero rather than throwing', () {
      final result = calculateCurrentMoney(
        ledgersTotal: 1000,
        cardOwedAmounts: const [],
        manualInputAmounts: const [],
      );

      expect(result, closeTo(1000, 0.001));
    });
  });
}

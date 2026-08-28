import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/net_worth/net_worth_calculator.dart';

Asset _asset({
  required String category,
  required String valuationMode,
  double quantity = 1,
  required String symbolOrCurrency,
}) {
  final now = DateTime(2026, 1, 1);
  return Asset(
    id: 'test-id',
    name: 'Test asset',
    category: category,
    valuationMode: valuationMode,
    quantity: quantity,
    symbolOrCurrency: symbolOrCurrency,
    notes: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('calculateNetWorth', () {
    test('sums crypto, metal and currency-valued assets into liquid/non-liquid totals', () {
      final assets = [
        _asset(category: 'crypto', valuationMode: 'crypto', quantity: 2, symbolOrCurrency: 'bitcoin'),
        _asset(category: 'gold', valuationMode: 'metal', quantity: 10, symbolOrCurrency: 'XAU_GRAM'),
        _asset(
          category: 'vehicle',
          valuationMode: 'currency',
          quantity: 250000,
          symbolOrCurrency: 'EGP',
        ),
      ];
      final prices = {'bitcoin': 50000.0, 'XAU_GRAM': 80.0, 'EGP': 1 / 48.5};

      final result = calculateNetWorth(assets, prices);

      final vehicleValueUsd = 250000 * (1 / 48.5);
      expect(result.unpricedAssets, isEmpty);
      expect(result.summary.liquidUsd, 2 * 50000.0 + 10 * 80.0);
      expect(result.summary.nonLiquidUsd, closeTo(vehicleValueUsd, 0.001));
      expect(result.summary.totalUsd, closeTo(2 * 50000.0 + 10 * 80.0 + vehicleValueUsd, 0.001));
    });

    test('excludes assets with no known price from the totals instead of counting them as zero', () {
      final assets = [
        _asset(category: 'crypto', valuationMode: 'crypto', quantity: 1, symbolOrCurrency: 'ethereum'),
      ];

      final result = calculateNetWorth(assets, const {});

      expect(result.unpricedAssets, hasLength(1));
      expect(result.summary.totalUsd, 0);
    });

    test('a manually-valued asset with an unknown currency is excluded, not counted as zero', () {
      final assets = [
        _asset(category: 'realEstate', valuationMode: 'currency', quantity: 250000, symbolOrCurrency: 'EGP'),
      ];

      final result = calculateNetWorth(assets, const {});

      expect(result.unpricedAssets, hasLength(1));
      expect(result.summary.nonLiquidUsd, 0);
    });
  });
}

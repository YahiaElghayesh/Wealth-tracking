import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/net_worth/net_worth_calculator.dart';

Asset _asset({
  required String category,
  required String valuationMode,
  double quantity = 1,
  String? symbolOrCurrency,
  double? manualValueUsd,
}) {
  final now = DateTime(2026, 1, 1);
  return Asset(
    id: 'test-id',
    name: 'Test asset',
    category: category,
    valuationMode: valuationMode,
    quantity: quantity,
    symbolOrCurrency: symbolOrCurrency,
    manualValueUsd: manualValueUsd,
    notes: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('calculateNetWorth', () {
    test('sums manual, crypto and metal assets into liquid/non-liquid totals', () {
      final assets = [
        _asset(category: 'crypto', valuationMode: 'crypto', quantity: 2, symbolOrCurrency: 'bitcoin'),
        _asset(category: 'gold', valuationMode: 'metal', quantity: 10, symbolOrCurrency: 'XAU_GRAM'),
        _asset(category: 'vehicle', valuationMode: 'manual', manualValueUsd: 5000),
      ];
      final prices = {'bitcoin': 50000.0, 'XAU_GRAM': 80.0};

      final result = calculateNetWorth(assets, prices);

      expect(result.unpricedAssets, isEmpty);
      expect(result.summary.liquidUsd, 2 * 50000.0 + 10 * 80.0);
      expect(result.summary.nonLiquidUsd, 5000.0);
      expect(result.summary.totalUsd, 2 * 50000.0 + 10 * 80.0 + 5000.0);
    });

    test('excludes assets with no known price from the totals instead of counting them as zero', () {
      final assets = [
        _asset(category: 'crypto', valuationMode: 'crypto', quantity: 1, symbolOrCurrency: 'ethereum'),
      ];

      final result = calculateNetWorth(assets, const {});

      expect(result.unpricedAssets, hasLength(1));
      expect(result.summary.totalUsd, 0);
    });

    test('manual valuation mode ignores any price map lookup', () {
      final assets = [
        _asset(category: 'realEstate', valuationMode: 'manual', manualValueUsd: 250000),
      ];

      final result = calculateNetWorth(assets, const {});

      expect(result.unpricedAssets, isEmpty);
      expect(result.summary.nonLiquidUsd, 250000.0);
    });
  });
}

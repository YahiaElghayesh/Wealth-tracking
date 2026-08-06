import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/pricing/price_provider.dart';
import 'package:wealth_tracker/data/pricing/price_refresh_service.dart';

class _FakeProvider implements PriceProvider {
  _FakeProvider(this._prices, {this.error});

  final Map<String, double> _prices;
  final PriceFetchException? error;

  @override
  String get name => 'fake';

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    if (error != null) throw error!;
    return {for (final s in symbols) if (_prices.containsKey(s)) s: _prices[s]!};
  }
}

Asset _asset(String valuationMode, String? symbol) {
  final now = DateTime(2026, 1, 1);
  return Asset(
    id: 'id',
    name: 'a',
    category: 'crypto',
    valuationMode: valuationMode,
    quantity: 1,
    symbolOrCurrency: symbol,
    manualValueUsd: null,
    notes: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('PriceRefreshService', () {
    test('merges results across providers and derives usdToEgpRate from EGP', () async {
      final service = PriceRefreshService(
        cryptoProvider: _FakeProvider({'bitcoin': 50000}),
        fxProvider: _FakeProvider({'USD': 1.0, 'EGP': 1 / 48.5}),
        metalsProvider: _FakeProvider({'XAU_GRAM': 80.0}),
      );
      final assets = [
        _asset('crypto', 'bitcoin'),
        _asset('metal', 'XAU_GRAM'),
      ];

      final result = await service.refresh(assets);

      expect(result.prices['bitcoin'], 50000);
      expect(result.prices['XAU_GRAM'], 80.0);
      expect(result.usdToEgpRate, closeTo(48.5, 0.001));
      expect(result.errors, isEmpty);
    });

    test('a failing provider reports an error without blocking the others', () async {
      final service = PriceRefreshService(
        cryptoProvider: _FakeProvider({}, error: PriceFetchException('fake', 'boom')),
        fxProvider: _FakeProvider({'USD': 1.0, 'EGP': 1 / 48.5}),
        metalsProvider: _FakeProvider({}),
      );
      final assets = [_asset('crypto', 'bitcoin')];

      final result = await service.refresh(assets);

      expect(result.errors, hasLength(1));
      expect(result.usdToEgpRate, closeTo(48.5, 0.001));
    });
  });
}

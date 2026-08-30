import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/data/pricing/fallback_price_provider.dart';
import 'package:wealth_tracker/data/pricing/price_provider.dart';

class _FakeProvider implements PriceProvider {
  _FakeProvider(this._name, this._prices, {this.error});

  final String _name;
  final Map<String, double> _prices;
  final PriceFetchException? error;

  @override
  String get name => _name;

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    if (error != null) throw error!;
    return {for (final s in symbols) if (_prices.containsKey(s)) s: _prices[s]!};
  }
}

void main() {
  group('FallbackPriceProvider', () {
    test('uses the primary result when it prices everything', () async {
      final provider = FallbackPriceProvider(
        primary: _FakeProvider('primary', {'XAU_GRAM_24K': 100}),
        secondary: _FakeProvider('secondary', {'XAU_GRAM_24K': 999}),
      );

      final result = await provider.fetchPrices({'XAU_GRAM_24K'});

      expect(result, {'XAU_GRAM_24K': 100});
    });

    test('falls back to the secondary for symbols the primary could not price', () async {
      final provider = FallbackPriceProvider(
        primary: _FakeProvider('primary', {'XAU_GRAM_24K': 100}),
        secondary: _FakeProvider('secondary', {'XAG_GRAM': 5}),
      );

      final result = await provider.fetchPrices({'XAU_GRAM_24K', 'XAG_GRAM'});

      expect(result, {'XAU_GRAM_24K': 100, 'XAG_GRAM': 5});
    });

    test('falls back entirely when the primary throws (e.g. quota exceeded)', () async {
      final provider = FallbackPriceProvider(
        primary: _FakeProvider('primary', const {}, error: PriceFetchException('primary', 'quota exceeded')),
        secondary: _FakeProvider('secondary', {'XAU_GRAM_24K': 100}),
      );

      final result = await provider.fetchPrices({'XAU_GRAM_24K'});

      expect(result, {'XAU_GRAM_24K': 100});
    });

    test('throws only when neither provider priced anything', () async {
      final provider = FallbackPriceProvider(
        primary: _FakeProvider('primary', const {}, error: PriceFetchException('primary', 'down')),
        secondary: _FakeProvider('secondary', const {}, error: PriceFetchException('secondary', 'also down')),
      );

      expect(() => provider.fetchPrices({'XAU_GRAM_24K'}), throwsA(isA<PriceFetchException>()));
    });

    test('keeps a partial primary success even if the fallback also fails', () async {
      final provider = FallbackPriceProvider(
        primary: _FakeProvider('primary', {'XAU_GRAM_24K': 100}),
        secondary: _FakeProvider('secondary', const {}, error: PriceFetchException('secondary', 'down')),
      );

      final result = await provider.fetchPrices({'XAU_GRAM_24K', 'XAG_GRAM'});

      expect(result, {'XAU_GRAM_24K': 100});
    });
  });
}

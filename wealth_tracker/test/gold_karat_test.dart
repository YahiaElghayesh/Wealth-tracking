import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/core/models/gold_karat.dart';

void main() {
  group('GoldKarat', () {
    test('purityFraction is relative to 24K pure gold', () {
      expect(GoldKarat.k24.purityFraction, 1.0);
      expect(GoldKarat.k21.purityFraction, closeTo(21 / 24, 0.0001));
      expect(GoldKarat.k18.purityFraction, closeTo(18 / 24, 0.0001));
    });

    test('priceSymbol round-trips through fromPriceSymbol', () {
      for (final karat in GoldKarat.values) {
        expect(GoldKarat.fromPriceSymbol(karat.priceSymbol), karat);
      }
    });

    test('fromPriceSymbol returns null for anything else', () {
      expect(GoldKarat.fromPriceSymbol('XAG_GRAM'), isNull);
      expect(GoldKarat.fromPriceSymbol('XAU_GRAM'), isNull);
      expect(GoldKarat.fromPriceSymbol('bitcoin'), isNull);
    });
  });
}

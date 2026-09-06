import 'package:flutter_test/flutter_test.dart';
import 'package:wealth_tracker/core/format/money_formatter.dart';

void main() {
  group('formatUsd', () {
    test('a whole number has no trailing .00', () {
      expect(formatUsd(270), '\$270');
    });

    test('a fractional value still shows its cents', () {
      expect(formatUsd(22.8), '\$22.80');
    });
  });

  group('formatEgp', () {
    test('a whole number has no trailing .00', () {
      expect(formatEgp(958), 'EGP 958');
    });

    test('a fractional value still shows its cents', () {
      expect(formatEgp(958.54), 'EGP 958.54');
    });
  });

  group('formatMoney', () {
    test('a whole number has no trailing .00', () {
      expect(formatMoney(99, 'SAR'), '99 SAR');
    });

    test('a fractional value still shows its decimals', () {
      expect(formatMoney(84.44, 'SAR'), '84.44 SAR');
    });
  });

  group('formatUsdWhole/formatEgpWhole', () {
    test('always round away a fraction, unlike formatUsd/formatEgp', () {
      expect(formatUsdWhole(22.8), '\$23');
      expect(formatEgpWhole(958.54), 'EGP 959');
    });
  });
}

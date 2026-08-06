import 'package:dio/dio.dart';

import 'price_provider.dart';

/// FX rates via open.er-api.com (free, no key, updated roughly daily —
/// plenty for net-worth purposes, not for day-trading).
///
/// [fetchPrices] returns, per currency code, the USD value of *one unit*
/// of that currency (so it slots into the same "USD per unit" contract as
/// the crypto/metals providers). [fetchRatesPerUsd] exposes the raw
/// "units of X per 1 USD" table for display conversions (e.g. showing a
/// USD total in EGP).
class FxPriceProvider implements PriceProvider {
  FxPriceProvider({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  String get name => 'open.er-api.com';

  Future<Map<String, double>> fetchRatesPerUsd() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://open.er-api.com/v6/latest/USD',
      );
      final rates = response.data?['rates'];
      if (rates is! Map) {
        throw PriceFetchException(name, 'unexpected response shape');
      }
      return rates.map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    } on DioException catch (e) {
      throw PriceFetchException(name, e.message ?? 'network error');
    }
  }

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    if (symbols.isEmpty) return {};
    final ratesPerUsd = await fetchRatesPerUsd();
    final result = <String, double>{};
    for (final code in symbols) {
      final rate = ratesPerUsd[code];
      if (rate != null && rate > 0) {
        result[code] = 1 / rate;
      }
    }
    return result;
  }
}

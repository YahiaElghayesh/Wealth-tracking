import 'package:dio/dio.dart';

import 'price_provider.dart';

/// Crypto prices via CoinGecko's free public API (no key required).
/// Symbols are CoinGecko coin IDs, e.g. `bitcoin`, `ethereum`.
class CoinGeckoPriceProvider implements PriceProvider {
  CoinGeckoPriceProvider({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  String get name => 'CoinGecko';

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    if (symbols.isEmpty) return {};

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.coingecko.com/api/v3/simple/price',
        queryParameters: {
          'ids': symbols.join(','),
          'vs_currencies': 'usd',
        },
      );

      final data = response.data ?? {};
      final result = <String, double>{};
      for (final id in symbols) {
        final entry = data[id];
        if (entry is Map && entry['usd'] is num) {
          result[id] = (entry['usd'] as num).toDouble();
        }
      }
      return result;
    } on DioException catch (e) {
      throw PriceFetchException(name, e.message ?? 'network error');
    }
  }
}

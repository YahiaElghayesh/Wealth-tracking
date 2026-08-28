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

  /// Coin name/symbol search for the asset entry screen's autocomplete, so
  /// the user picks a coin by name instead of having to know its raw
  /// CoinGecko ID (e.g. picking "Bitcoin" instead of typing "bitcoin").
  Future<List<CoinSearchResult>> searchCoins(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.coingecko.com/api/v3/search',
        queryParameters: {'query': query.trim()},
      );
      final coins = response.data?['coins'] as List<dynamic>? ?? [];
      return coins
          .whereType<Map<String, dynamic>>()
          .map(
            (c) => CoinSearchResult(
              id: c['id'] as String? ?? '',
              name: c['name'] as String? ?? '',
              symbol: (c['symbol'] as String? ?? '').toUpperCase(),
            ),
          )
          .where((c) => c.id.isNotEmpty)
          .toList();
    } on DioException {
      return [];
    }
  }
}

class CoinSearchResult {
  const CoinSearchResult({required this.id, required this.name, required this.symbol});

  final String id;
  final String name;
  final String symbol;

  @override
  String toString() => '$name ($symbol)';
}

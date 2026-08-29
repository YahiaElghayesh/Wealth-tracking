import 'package:dio/dio.dart';

import 'price_provider.dart';

/// Stock prices + symbol search via Twelve Data's free-tier REST API
/// (https://twelvedata.com) — one API covering both US exchanges
/// (NASDAQ/NYSE) and the Egyptian Exchange (EGX), which is why it was
/// picked over stitching together two separate providers. Free tier
/// requires the user's own API key (Settings), same reasoning as
/// [MetalsPriceProvider]'s goldapi.io key — we can't create that account on
/// their behalf.
///
/// Symbols are stored and requested as `TICKER:EXCHANGE` (e.g.
/// `AAPL:NASDAQ`, `COMI:EGX`) — Twelve Data accepts that exact compound
/// form directly as its `symbol` query parameter, comma-separated for a
/// batch request, so no translation is needed between what's stored on the
/// asset and what's sent over the wire.
class TwelveDataPriceProvider implements PriceProvider {
  TwelveDataPriceProvider({required this.apiKey, Dio? dio}) : _dio = dio ?? Dio();

  final String? apiKey;
  final Dio _dio;

  static const _baseUrl = 'https://api.twelvedata.com';

  @override
  String get name => 'Twelve Data';

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    if (symbols.isEmpty) return {};

    final key = apiKey;
    if (key == null || key.isEmpty) {
      throw PriceFetchException(name, 'No API key configured. Add one in Settings.');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/price',
        queryParameters: {'symbol': symbols.join(','), 'apikey': key},
      );
      final data = response.data ?? {};
      final result = <String, double>{};

      // A single-symbol request returns {"price": "123.45"} directly; a
      // batch request returns {"AAPL:NASDAQ": {"price": "..."}, ...} keyed
      // by the same compound symbol that was requested.
      if (symbols.length == 1) {
        final price = data['price'];
        if (price is String) {
          final parsed = double.tryParse(price);
          if (parsed != null) result[symbols.first] = parsed;
        }
      } else {
        for (final symbol in symbols) {
          final entry = data[symbol];
          if (entry is Map && entry['price'] is String) {
            final parsed = double.tryParse(entry['price'] as String);
            if (parsed != null) result[symbol] = parsed;
          }
        }
      }
      return result;
    } on DioException catch (e) {
      throw PriceFetchException(name, e.message ?? 'network error');
    }
  }

  /// Stock name/ticker search across every exchange Twelve Data covers
  /// (including EGX) for the asset entry screen's autocomplete.
  Future<List<StockSearchResult>> searchStocks(String query) async {
    if (query.trim().isEmpty) return [];

    final key = apiKey;
    if (key == null || key.isEmpty) return [];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/symbol_search',
        queryParameters: {'symbol': query.trim(), 'apikey': key},
      );
      final entries = response.data?['data'] as List<dynamic>? ?? [];
      return entries
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => StockSearchResult(
              symbol: e['symbol'] as String? ?? '',
              name: e['instrument_name'] as String? ?? '',
              exchange: e['exchange'] as String? ?? '',
              country: e['country'] as String? ?? '',
            ),
          )
          .where((r) => r.symbol.isNotEmpty && r.exchange.isNotEmpty)
          .toList();
    } on DioException {
      return [];
    }
  }
}

class StockSearchResult {
  const StockSearchResult({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.country,
  });

  final String symbol;
  final String name;
  final String exchange;
  final String country;

  /// What actually gets stored as the asset's `symbolOrCurrency` and sent
  /// to [TwelveDataPriceProvider.fetchPrices].
  String get compoundSymbol => '$symbol:$exchange';

  @override
  String toString() => '$name ($symbol · $exchange)';
}

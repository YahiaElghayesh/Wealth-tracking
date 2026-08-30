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
/// Symbols are stored as `TICKER:EXCHANGE` (e.g. `AAPL:NASDAQ`,
/// `COMI:EGX`), but that compound string is only a local storage
/// convenience -- Twelve Data's `/price` endpoint wants the ticker and
/// exchange as two *separate* query parameters (`symbol=AAPL&exchange=NASDAQ`),
/// not smashed together into one `symbol` value. Sending the compound form
/// as a single `symbol` was landing a 404 (confirmed on-device). Each stock
/// is fetched with its own request rather than batched, both to sidestep
/// that (each request's response is the same reliable flat `{"price": ...}`
/// shape either way) and because a batch request sharing one `exchange`
/// param can't represent a mix of EGX and NASDAQ tickers at once.
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

    final result = <String, double>{};
    final errors = <String>[];

    for (final compound in symbols) {
      final parts = compound.split(':');
      final ticker = parts.first;
      final exchange = parts.length > 1 ? parts.sublist(1).join(':') : null;
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          '$_baseUrl/price',
          queryParameters: {
            'symbol': ticker,
            if (exchange != null && exchange.isNotEmpty) 'exchange': exchange,
            'apikey': key,
          },
        );
        final price = response.data?['price'];
        if (price is String) {
          final parsed = double.tryParse(price);
          if (parsed != null) result[compound] = parsed;
        }
      } on DioException catch (e) {
        errors.add('$ticker: ${e.message ?? 'network error'}');
      }
    }

    // A total failure (nothing priced at all) is worth surfacing as an
    // error the refresh UI shows; a partial failure just quietly leaves
    // those specific assets unpriced, same as every other provider here.
    if (result.isEmpty && errors.isNotEmpty) {
      throw PriceFetchException(name, errors.join('; '));
    }
    return result;
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

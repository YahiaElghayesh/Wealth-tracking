import 'package:dio/dio.dart';

import 'price_provider.dart';
import 'yahoo_finance_price_provider.dart';

/// Second stock data source, specifically to cover the gap Yahoo Finance
/// leaves on the Egyptian Exchange: Yahoo indexes some EGX companies under
/// an opaque ISIN-style code instead of the plain ticker (see
/// [YahooFinancePriceProvider]'s doc comments), so a user searching "Palm
/// Hills" or "TMGH" the normal way can come up empty or land on the wrong
/// result. stockanalysis.com serves every EGX-listed company under its
/// plain ticker (confirmed: stockanalysis.com/quote/egx/COMI/,
/// .../egx/PHDC/, .../egx/GTEX/) and needs no signup or API key.
///
/// Its `/api/search` endpoint is a real, if undocumented-by-the-vendor,
/// endpoint the site's own frontend calls, reverse-engineered and
/// published at github.com/haskaomni/stockanalysis -- confirmed shape:
/// each result carries a `s` field like `"egx/COMI"` or `"snse/NVDA"` (a
/// slash-joined exchange/ticker pair) and a `t` type letter (`s` = US
/// stock, `e` = US ETF, `sy` = international symbol). That slash-joined
/// form is stored verbatim (prefixed so [fetchPrices] can recognize it)
/// as this app's `symbolOrCurrency`, the same "search result IS the
/// tradeable id" approach [YahooFinancePriceProvider] already uses.
///
/// The quotes endpoint for `sy`-type (international) symbols specifically
/// isn't published anywhere the search endpoint's format is -- only the
/// domestic `/api/quotes/s/{ticker}` and `/api/quotes/e/{ticker}` shapes
/// are documented. [_fetchQuotePrice] tries the type-matched path first,
/// falling back to the plain "s" path for `sy` symbols in case the site
/// only uses the type letter for search grouping rather than a distinct
/// quotes route. This is a deliberately defensive guess about an
/// endpoint's *shape*, not a per-stock hardcoded mapping -- it applies
/// identically to every symbol, known or not.
///
/// Used as the fallback behind Yahoo Finance (see `stockPriceProviderProvider`
/// in pricing_providers.dart), never the primary -- if a guess here turns
/// out wrong, the only effect is this provider silently prices nothing and
/// Yahoo's own result (or "unpriced", same as today) stands, exactly the
/// same partial-failure handling every other provider in this app already
/// gets from [FallbackPriceProvider].
class StockAnalysisPriceProvider implements PriceProvider {
  StockAnalysisPriceProvider({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _baseUrl = 'https://stockanalysis.com/api';

  @override
  String get name => 'StockAnalysis.com';

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    if (symbols.isEmpty) return {};

    final result = <String, double>{};
    final errors = <String>[];

    for (final stored in symbols) {
      final parsed = _parseStored(stored);
      // Not one of ours (e.g. a legacy Yahoo-shaped symbol) -- leave it for
      // whichever provider actually owns that format.
      if (parsed == null) continue;
      try {
        final price = await _fetchQuotePrice(parsed);
        if (price != null) result[stored] = price;
      } on DioException catch (e) {
        errors.add('$stored: ${e.message ?? 'network error'}');
      }
    }

    if (result.isEmpty && errors.isNotEmpty) {
      throw PriceFetchException(name, errors.join('; '));
    }
    return result;
  }

  ({String type, String ticker})? _parseStored(String stored) {
    if (!stored.startsWith('SA:')) return null;
    final rest = stored.substring(3);
    final separator = rest.indexOf(':');
    if (separator == -1) return null;
    return (type: rest.substring(0, separator), ticker: rest.substring(separator + 1));
  }

  Future<double?> _fetchQuotePrice(({String type, String ticker}) parsed) async {
    final candidateTypes = parsed.type == 'sy' ? ['sy', 's'] : [parsed.type];
    for (final type in candidateTypes) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          '$_baseUrl/quotes/$type/${parsed.ticker}',
          options: Options(headers: const {'User-Agent': 'Mozilla/5.0'}),
        );
        final price = response.data?['p'];
        if (price is num) return price.toDouble();
      } on DioException catch (e) {
        // A 404 just means this type-shaped path is wrong for this symbol
        // -- try the next candidate rather than failing the whole lookup.
        if (e.response?.statusCode != 404) rethrow;
      }
    }
    return null;
  }

  /// Mirrors [YahooFinancePriceProvider.searchStocks]'s contract: returns
  /// the exact tradeable form ready to store as `symbolOrCurrency`.
  Future<List<StockSearchResult>> searchStocks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final response = await _dio.get<dynamic>(
        '$_baseUrl/search',
        queryParameters: {'q': trimmed},
        options: Options(headers: const {'User-Agent': 'Mozilla/5.0'}),
      );
      final items = _extractItems(response.data);
      return items
          .map((item) {
            final rawSymbol = item['s'] as String? ?? '';
            if (rawSymbol.isEmpty) return null;
            final type = item['t'] as String? ?? 's';
            final ticker = rawSymbol.contains('/') ? rawSymbol.split('/').last : rawSymbol;
            final exchange = rawSymbol.contains('/') ? rawSymbol.split('/').first.toUpperCase() : '';
            final companyName =
                (item['n'] ?? item['name'] ?? item['companyName'] ?? ticker) as String;
            return StockSearchResult(
              symbol: 'SA:$type:${rawSymbol.toLowerCase()}',
              name: companyName,
              exchange: exchange,
              country: '',
            );
          })
          .whereType<StockSearchResult>()
          .toList();
    } on DioException {
      return [];
    }
  }

  /// The search response's top-level shape isn't published either -- try
  /// the plausible wrapper keys before giving up, so a wrong guess here
  /// just yields no results rather than throwing.
  List<Map<String, dynamic>> _extractItems(dynamic data) {
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'results', 'items', 'symbols']) {
        final value = data[key];
        if (value is List) return value.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }
}

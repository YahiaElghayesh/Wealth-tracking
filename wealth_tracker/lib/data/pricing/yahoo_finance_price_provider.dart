import 'package:dio/dio.dart';

import 'price_provider.dart';

/// Stock prices + symbol search via Yahoo Finance's unofficial (but
/// widely used, well-documented in open-source tooling) endpoints --
/// replaces Twelve Data, whose free-tier `/price` endpoint kept 404ing
/// even after correcting the request shape once already. Yahoo needs no
/// signup or API key at all, which also removes an entire class of "the
/// user's key is missing/invalid/rate-limited" failure this app has no way
/// to diagnose on their behalf.
///
/// Yahoo identifies a stock by one plain ticker, suffixed per-exchange for
/// anything outside the US (e.g. `COMI.CA` for the Egyptian Exchange, no
/// suffix for NASDAQ/NYSE) -- [searchStocks] returns that exact form
/// already (Yahoo's own search resolves the suffix), so newly-added assets
/// store it directly as `symbolOrCurrency`, with no further composition
/// needed. Assets added back when this app used Twelve Data are stored as
/// `TICKER:EXCHANGE` instead (Twelve Data's own compound form);
/// [_toYahooSymbol] converts that legacy shape on the fly so those assets
/// keep pricing without a data migration.
class YahooFinancePriceProvider implements PriceProvider {
  YahooFinancePriceProvider({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _chartBaseUrl =
      'https://query1.finance.yahoo.com/v8/finance/chart';
  static const _searchUrl =
      'https://query1.finance.yahoo.com/v1/finance/search';

  @override
  String get name => 'Yahoo Finance';

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    if (symbols.isEmpty) return {};

    final result = <String, double>{};
    final errors = <String>[];
    // Every price this app stores is USD-per-unit, but Yahoo quotes a
    // stock in its own listing currency -- COMI.CA (Egyptian Exchange)
    // comes back priced in EGP, not USD. A raw regularMarketPrice would
    // silently be off by the whole EGP/USD rate. Cache each currency's
    // conversion within this call so multiple stocks sharing an exchange
    // (and so a currency) only trigger one extra FX lookup, not one each.
    final fxRateToUsd = <String, double?>{};

    for (final stored in symbols) {
      final yahooSymbol = _toYahooSymbol(stored);
      try {
        final meta = await _fetchChartMeta(yahooSymbol);
        final price = meta?['regularMarketPrice'];
        if (price is! num) continue;
        final currency = (meta?['currency'] as String?)?.toUpperCase();

        var priceUsd = price.toDouble();
        if (currency != null && currency != 'USD') {
          final rate = fxRateToUsd.containsKey(currency)
              ? fxRateToUsd[currency]
              : await _fetchFxRateToUsd(currency);
          fxRateToUsd[currency] = rate;
          // No trustworthy conversion -- leave this one unpriced rather
          // than store a wrong-currency figure as if it were USD.
          if (rate == null) continue;
          priceUsd *= rate;
        }
        result[stored] = priceUsd;
      } on DioException catch (e) {
        errors.add('$stored: ${e.message ?? 'network error'}');
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

  Future<Map<String, dynamic>?> _fetchChartMeta(String yahooSymbol) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_chartBaseUrl/$yahooSymbol',
      queryParameters: const {'interval': '1d', 'range': '1d'},
      options: Options(headers: const {'User-Agent': 'Mozilla/5.0'}),
    );
    final results = response.data?['chart']?['result'] as List?;
    final chartResult = (results != null && results.isNotEmpty)
        ? results.first as Map<String, dynamic>?
        : null;
    return chartResult?['meta'] as Map<String, dynamic>?;
  }

  /// USD value of one unit of [currency], via Yahoo's own FX-pair ticker
  /// convention (e.g. `EGPUSD=X`). Returns null rather than throwing on
  /// failure -- callers treat that as "can't trust this price" and skip it,
  /// the same way a missing crypto/metal price is handled elsewhere.
  Future<double?> _fetchFxRateToUsd(String currency) async {
    try {
      final meta = await _fetchChartMeta('${currency}USD=X');
      final rate = meta?['regularMarketPrice'];
      return rate is num ? rate.toDouble() : null;
    } on DioException {
      return null;
    }
  }

  /// Legacy `TICKER:EXCHANGE` assets (from this app's Twelve Data days)
  /// converted to Yahoo's own suffix convention; anything already in
  /// Yahoo's own plain-ticker form (no colon -- every asset added since
  /// this provider took over) passes through unchanged.
  String _toYahooSymbol(String stored) {
    if (!stored.contains(':')) return stored;
    final parts = stored.split(':');
    final ticker = parts.first;
    final exchange = parts.length > 1
        ? parts.sublist(1).join(':').toUpperCase()
        : '';
    if (exchange == 'EGX') return '$ticker.CA';
    return ticker;
  }

  /// Stock name/ticker search for the asset entry screen's autocomplete --
  /// Yahoo's own search already resolves each result to its fully-suffixed
  /// tradeable symbol, so no separate exchange-to-suffix mapping is needed
  /// here the way [_toYahooSymbol] needs one for legacy data.
  Future<List<StockSearchResult>> searchStocks(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _searchUrl,
        queryParameters: {'q': query.trim(), 'quotesCount': 10, 'newsCount': 0},
        options: Options(headers: const {'User-Agent': 'Mozilla/5.0'}),
      );
      final quotes = response.data?['quotes'] as List<dynamic>? ?? [];
      return quotes
          .whereType<Map<String, dynamic>>()
          .where((q) => q['isYahooFinance'] != false)
          .map(
            (q) => StockSearchResult(
              symbol: q['symbol'] as String? ?? '',
              name:
                  (q['shortname'] ?? q['longname'] ?? q['symbol']) as String? ??
                  '',
              exchange: (q['exchDisp'] ?? q['exchange']) as String? ?? '',
              country: '',
            ),
          )
          .where((r) => r.symbol.isNotEmpty)
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

  /// What gets stored as the asset's `symbolOrCurrency` and sent to
  /// [YahooFinancePriceProvider.fetchPrices] -- Yahoo's [symbol] is already
  /// the exact tradeable form (suffix included), unlike Twelve Data's
  /// compound `TICKER:EXCHANGE` form this used to compose.
  String get compoundSymbol => symbol;

  @override
  String toString() => '$symbol · $name ($exchange)';
}

import 'package:dio/dio.dart';

import '../../core/models/gold_karat.dart';
import 'price_provider.dart';

const _gramsPerTroyOunce = 31.1034768;

/// Gold/silver prices via Yahoo Finance's unofficial chart endpoint -- a
/// third, keyless fallback behind goldapi.io and gold-api.com, both of
/// which now hit 429 rate limits on their free tiers. `GC=F`/`SI=F` are
/// Yahoo's tickers for COMEX gold/silver futures (continuous front-month
/// contract), quoted in USD per troy ounce -- close enough to spot for a
/// net-worth estimate. `XAUUSD=X`/`XAGUSD=X` (the `=X` FX-pair convention
/// [YahooFinancePriceProvider] uses for currency conversion) looked like
/// the more natural fit but 404s on this endpoint on-device; Yahoo doesn't
/// carry metals as FX pairs the way it does for real ISO currencies, only
/// as futures contracts.
class YahooMetalsPriceProvider implements PriceProvider {
  YahooMetalsPriceProvider({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _chartBaseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';

  @override
  String get name => 'Yahoo Finance';

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    final requestedKarats = symbols.map(GoldKarat.fromPriceSymbol).whereType<GoldKarat>().toSet();
    final needsSilver = symbols.contains('XAG_GRAM');
    if (requestedKarats.isEmpty && !needsSilver) return {};

    final result = <String, double>{};
    final errors = <String>[];

    if (requestedKarats.isNotEmpty) {
      try {
        final pureGoldPerGram = await _fetchPricePerGram('GC=F');
        for (final karat in requestedKarats) {
          result[karat.priceSymbol] = pureGoldPerGram * karat.purityFraction;
        }
      } on PriceFetchException catch (e) {
        errors.add(e.toString());
      }
    }

    if (needsSilver) {
      try {
        result['XAG_GRAM'] = await _fetchPricePerGram('SI=F');
      } on PriceFetchException catch (e) {
        errors.add(e.toString());
      }
    }

    if (result.isEmpty && errors.isNotEmpty) {
      throw PriceFetchException(name, errors.join('; '));
    }
    return result;
  }

  Future<double> _fetchPricePerGram(String yahooSymbol) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_chartBaseUrl/$yahooSymbol',
        queryParameters: const {'interval': '1d', 'range': '1d'},
        options: Options(headers: const {'User-Agent': 'Mozilla/5.0'}),
      );
      final results = response.data?['chart']?['result'] as List?;
      final chartResult = (results != null && results.isNotEmpty)
          ? results.first as Map<String, dynamic>?
          : null;
      final meta = chartResult?['meta'] as Map<String, dynamic>?;
      final pricePerOunce = meta?['regularMarketPrice'];
      if (pricePerOunce is! num) {
        throw PriceFetchException(name, 'unexpected response shape for $yahooSymbol');
      }
      return pricePerOunce.toDouble() / _gramsPerTroyOunce;
    } on DioException catch (e) {
      throw PriceFetchException(name, e.message ?? 'network error');
    }
  }
}

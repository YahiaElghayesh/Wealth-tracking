import 'package:dio/dio.dart';

import '../../core/models/gold_karat.dart';
import 'price_provider.dart';

const _gramsPerTroyOunce = 31.1034768;

/// Gold/silver spot prices via Yahoo Finance's unofficial chart endpoint --
/// a third, keyless fallback behind goldapi.io and gold-api.com, both of
/// which now hit 429 rate limits on their free tiers. `XAUUSD=X`/`XAGUSD=X`
/// are Yahoo's own standard tickers for spot gold/silver in USD per troy
/// ounce (the same `=X` FX-pair convention [YahooFinancePriceProvider]
/// already uses for currency conversion), served off the same
/// `query1.finance.yahoo.com/v8/finance/chart` endpoint this app already
/// relies on for every stock price -- no signup, and no rate-limit issues
/// observed there so far.
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
        final pureGoldPerGram = await _fetchPricePerGram('XAUUSD=X');
        for (final karat in requestedKarats) {
          result[karat.priceSymbol] = pureGoldPerGram * karat.purityFraction;
        }
      } on PriceFetchException catch (e) {
        errors.add(e.toString());
      }
    }

    if (needsSilver) {
      try {
        result['XAG_GRAM'] = await _fetchPricePerGram('XAGUSD=X');
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

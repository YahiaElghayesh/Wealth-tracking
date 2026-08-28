import 'package:dio/dio.dart';

import '../../core/models/gold_karat.dart';
import 'price_provider.dart';

const _gramsPerTroyOunce = 31.1034768;

/// Gold/silver spot prices via goldapi.io. Free tier requires the user to
/// sign up for their own API key (Settings screen) — we can't create that
/// account on their behalf. The API quotes pure metal per troy ounce;
/// gold symbols are `XAU_GRAM_<karat>K` (e.g. `XAU_GRAM_21K`) and are
/// derived from a single pure-gold (24K) fetch scaled by purity, so
/// pricing five different karats still costs one API call, not five.
/// Silver has no karat concept here — just `XAG_GRAM`.
class MetalsPriceProvider implements PriceProvider {
  MetalsPriceProvider({required this.apiKey, Dio? dio}) : _dio = dio ?? Dio();

  /// goldapi.io access token. Null/empty means metals pricing is disabled
  /// until the user configures one.
  final String? apiKey;

  final Dio _dio;

  @override
  String get name => 'goldapi.io';

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    final requestedKarats = symbols.map(GoldKarat.fromPriceSymbol).whereType<GoldKarat>().toSet();
    final needsSilver = symbols.contains('XAG_GRAM');
    if (requestedKarats.isEmpty && !needsSilver) return {};

    final key = apiKey;
    if (key == null || key.isEmpty) {
      throw PriceFetchException(name, 'No API key configured. Add one in Settings.');
    }

    final result = <String, double>{};

    if (requestedKarats.isNotEmpty) {
      final pureGoldPerGram = await _fetchPricePerGram('XAU', key);
      for (final karat in requestedKarats) {
        result[karat.priceSymbol] = pureGoldPerGram * karat.purityFraction;
      }
    }

    if (needsSilver) {
      result['XAG_GRAM'] = await _fetchPricePerGram('XAG', key);
    }

    return result;
  }

  Future<double> _fetchPricePerGram(String metalCode, String key) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://www.goldapi.io/api/$metalCode/USD',
        options: Options(headers: {'x-access-token': key}),
      );
      final pricePerOunce = response.data?['price'];
      if (pricePerOunce is! num) {
        throw PriceFetchException(name, 'unexpected response shape for $metalCode');
      }
      return pricePerOunce.toDouble() / _gramsPerTroyOunce;
    } on DioException catch (e) {
      throw PriceFetchException(name, e.message ?? 'network error');
    }
  }
}

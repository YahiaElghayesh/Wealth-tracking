import 'package:dio/dio.dart';

import 'price_provider.dart';

const _gramsPerTroyOunce = 31.1034768;

/// Gold/silver spot prices via goldapi.io. Free tier requires the user to
/// sign up for their own API key (Settings screen) — we can't create that
/// account on their behalf. Symbols are `XAU_GRAM` / `XAG_GRAM`; the API
/// quotes per troy ounce, converted to per gram here since assets are
/// tracked by weight in grams.
class MetalsPriceProvider implements PriceProvider {
  MetalsPriceProvider({required this.apiKey, Dio? dio}) : _dio = dio ?? Dio();

  /// goldapi.io access token. Null/empty means metals pricing is disabled
  /// until the user configures one.
  final String? apiKey;

  final Dio _dio;

  static const _metalCodeBySymbol = {
    'XAU_GRAM': 'XAU',
    'XAG_GRAM': 'XAG',
  };

  @override
  String get name => 'goldapi.io';

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    final requested = symbols.where(_metalCodeBySymbol.containsKey).toSet();
    if (requested.isEmpty) return {};

    final key = apiKey;
    if (key == null || key.isEmpty) {
      throw PriceFetchException(name, 'No API key configured. Add one in Settings.');
    }

    final result = <String, double>{};
    for (final symbol in requested) {
      final metalCode = _metalCodeBySymbol[symbol]!;
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          'https://www.goldapi.io/api/$metalCode/USD',
          options: Options(headers: {'x-access-token': key}),
        );
        final pricePerOunce = response.data?['price'];
        if (pricePerOunce is num) {
          result[symbol] = pricePerOunce.toDouble() / _gramsPerTroyOunce;
        }
      } on DioException catch (e) {
        throw PriceFetchException(name, e.message ?? 'network error');
      }
    }
    return result;
  }
}

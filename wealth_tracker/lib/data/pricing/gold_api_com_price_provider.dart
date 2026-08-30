import 'package:dio/dio.dart';

import '../../core/models/gold_karat.dart';
import 'price_provider.dart';

const _gramsPerTroyOunce = 31.1034768;

/// Gold/silver spot prices via gold-api.com -- a free, keyless service used
/// as an automatic fallback for [MetalsPriceProvider] (goldapi.io), whose
/// free tier keeps running out of its monthly quota. No signup, no
/// per-account quota to exhaust: `GET https://api.gold-api.com/price/XAU`
/// (or `XAG`) returns a JSON object with a `name`, a `price` (USD per troy
/// ounce), a `symbol`, and an `updatedAt` -- structurally the same "one
/// price per metal, per troy ounce, in USD" shape [MetalsPriceProvider]
/// already converts to a per-gram, per-karat price from, so the karat/
/// purity math is identical between the two providers.
class GoldApiComPriceProvider implements PriceProvider {
  GoldApiComPriceProvider({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  String get name => 'gold-api.com';

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    final requestedKarats = symbols.map(GoldKarat.fromPriceSymbol).whereType<GoldKarat>().toSet();
    final needsSilver = symbols.contains('XAG_GRAM');
    if (requestedKarats.isEmpty && !needsSilver) return {};

    final result = <String, double>{};

    if (requestedKarats.isNotEmpty) {
      final pureGoldPerGram = await _fetchPricePerGram('XAU');
      for (final karat in requestedKarats) {
        result[karat.priceSymbol] = pureGoldPerGram * karat.purityFraction;
      }
    }

    if (needsSilver) {
      result['XAG_GRAM'] = await _fetchPricePerGram('XAG');
    }

    return result;
  }

  Future<double> _fetchPricePerGram(String metalCode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('https://api.gold-api.com/price/$metalCode');
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

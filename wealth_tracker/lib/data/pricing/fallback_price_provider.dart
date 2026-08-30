import 'price_provider.dart';

/// Tries [primary] first, then falls back to [secondary] for whatever
/// [primary] couldn't price -- either because it failed outright (e.g.
/// [primary] is `MetalsPriceProvider`/goldapi.io and its free-tier monthly
/// quota is exhausted, or no API key is configured at all) or because it
/// only partially succeeded. [name] reports as [primary]'s, since that's
/// still the intended/preferred source; [secondary] only ever fills gaps.
class FallbackPriceProvider implements PriceProvider {
  const FallbackPriceProvider({required this.primary, required this.secondary});

  final PriceProvider primary;
  final PriceProvider secondary;

  @override
  String get name => primary.name;

  @override
  Future<Map<String, double>> fetchPrices(Set<String> symbols) async {
    if (symbols.isEmpty) return {};

    Map<String, double> primaryResult;
    try {
      primaryResult = await primary.fetchPrices(symbols);
    } on PriceFetchException {
      primaryResult = const {};
    }

    final missing = symbols.difference(primaryResult.keys.toSet());
    if (missing.isEmpty) return primaryResult;

    try {
      final secondaryResult = await secondary.fetchPrices(missing);
      return {...primaryResult, ...secondaryResult};
    } on PriceFetchException catch (e) {
      // Only escalate the failure if neither provider priced anything at
      // all -- a partial primary success should still reach callers
      // rather than being thrown away because the fallback also failed.
      if (primaryResult.isEmpty) throw PriceFetchException(name, e.toString());
      return primaryResult;
    }
  }
}

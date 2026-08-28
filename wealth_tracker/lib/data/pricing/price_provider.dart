/// A source of live USD prices for a set of symbols (crypto tickers,
/// `XAU_GRAM_<karat>K` / `XAG_GRAM`, or currency codes). Kept as an interface so a
/// data source can be swapped (e.g. a paid metals API) without touching
/// callers.
abstract class PriceProvider {
  /// Human-readable name shown in Settings / error messages.
  String get name;

  /// Fetches current USD prices for the given [symbols]. Implementations
  /// should return only the symbols they were able to price — callers treat
  /// a missing symbol as "still unknown" rather than erroring.
  Future<Map<String, double>> fetchPrices(Set<String> symbols);
}

class PriceFetchException implements Exception {
  PriceFetchException(this.providerName, this.message);

  final String providerName;
  final String message;

  @override
  String toString() => '$providerName: $message';
}

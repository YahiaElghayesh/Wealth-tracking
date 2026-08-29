import '../../core/models/asset_category.dart';
import '../../core/models/currency.dart';
import '../db/database.dart';
import 'price_provider.dart';

class PriceRefreshResult {
  const PriceRefreshResult({
    required this.prices,
    required this.usdToEgpRate,
    required this.errors,
  });

  /// Newly-fetched prices only (callers merge these into the existing
  /// cache rather than replacing it, so a provider outage doesn't wipe out
  /// prices we already knew).
  final Map<String, double> prices;

  /// Units of EGP per 1 USD, for converting USD totals to an EGP display
  /// figure. Null if the FX call failed.
  final double? usdToEgpRate;

  /// Human-readable messages for providers that failed this round —
  /// surfaced in the UI rather than silently swallowed.
  final List<String> errors;
}

/// Figures out which symbols are actually in use across the user's assets,
/// fans out to the three price sources, and merges the results. A failure
/// in one provider (e.g. no metals API key yet) doesn't block the others.
class PriceRefreshService {
  const PriceRefreshService({
    required this.cryptoProvider,
    required this.fxProvider,
    required this.metalsProvider,
    required this.stockProvider,
  });

  final PriceProvider cryptoProvider;
  final PriceProvider fxProvider;
  final PriceProvider metalsProvider;
  final PriceProvider stockProvider;

  Future<PriceRefreshResult> refresh(List<Asset> assets) async {
    final cryptoSymbols = <String>{};
    final metalSymbols = <String>{};
    final stockSymbols = <String>{};
    // Always fetch every supported currency (not just ones assets use) —
    // it's a single API call regardless, and the ledger's currency
    // conversion needs the full set too, independent of assets.
    final fiatSymbols = {'USD', ...supportedCurrencies};

    for (final asset in assets) {
      switch (ValuationMode.values.byName(asset.valuationMode)) {
        case ValuationMode.crypto:
          cryptoSymbols.add(asset.symbolOrCurrency);
        case ValuationMode.metal:
          metalSymbols.add(asset.symbolOrCurrency);
        case ValuationMode.stock:
          stockSymbols.add(asset.symbolOrCurrency);
        case ValuationMode.currency:
          break; // already covered by fiatSymbols above
      }
    }

    final merged = <String, double>{};
    final errors = <String>[];

    Future<void> run(Future<Map<String, double>> Function() call) async {
      try {
        merged.addAll(await call());
      } on PriceFetchException catch (e) {
        errors.add(e.toString());
      }
    }

    await run(() => cryptoProvider.fetchPrices(cryptoSymbols));
    await run(() => fxProvider.fetchPrices(fiatSymbols));
    await run(() => metalsProvider.fetchPrices(metalSymbols));
    await run(() => stockProvider.fetchPrices(stockSymbols));

    final egpValueOfOneUsd = merged['EGP'];
    final usdToEgpRate = egpValueOfOneUsd == null ? null : 1 / egpValueOfOneUsd;

    return PriceRefreshResult(prices: merged, usdToEgpRate: usdToEgpRate, errors: errors);
  }
}

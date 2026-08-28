import '../db/database.dart';
import '../repositories/price_cache_repository.dart';
import 'price_refresh_service.dart';

class PriceRefreshOutcome {
  const PriceRefreshOutcome({
    required this.allPrices,
    required this.usdToEgpRate,
    required this.errors,
  });

  /// The full price cache after this refresh — previously-cached prices
  /// merged with anything newly fetched, so a partial provider failure
  /// doesn't drop prices we already knew.
  final Map<String, double> allPrices;
  final double? usdToEgpRate;
  final List<String> errors;
}

/// Runs a price refresh and persists the result to the local cache. Shared
/// between the in-app "refresh now" flow and the periodic background task
/// (see `background_refresh.dart`) so the two can't drift apart.
Future<PriceRefreshOutcome> refreshAndPersistPrices({
  required List<Asset> assets,
  required PriceRefreshService service,
  required PriceCacheRepository cacheRepo,
}) async {
  final cached = await cacheRepo.loadAll();
  final result = await service.refresh(assets);

  var allPrices = cached;
  if (result.prices.isNotEmpty) {
    allPrices = {...cached, ...result.prices};
    await cacheRepo.upsertAll(result.prices);
  }

  final egpValueOfOneUsd = allPrices['EGP'];
  final usdToEgpRate = result.usdToEgpRate ?? (egpValueOfOneUsd == null ? null : 1 / egpValueOfOneUsd);

  return PriceRefreshOutcome(allPrices: allPrices, usdToEgpRate: usdToEgpRate, errors: result.errors);
}

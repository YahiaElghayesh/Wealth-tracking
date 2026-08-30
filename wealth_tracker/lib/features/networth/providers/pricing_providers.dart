import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/pricing/coingecko_price_provider.dart';
import '../../../data/pricing/fallback_price_provider.dart';
import '../../../data/pricing/fx_price_provider.dart';
import '../../../data/pricing/gold_api_com_price_provider.dart';
import '../../../data/pricing/metals_price_provider.dart';
import '../../../data/pricing/price_refresh_orchestrator.dart';
import '../../../data/pricing/price_refresh_service.dart';
import '../../../data/pricing/yahoo_finance_price_provider.dart';
import '../../../data/repositories/price_cache_repository.dart';
import '../../settings/providers/settings_providers.dart';
import 'asset_providers.dart';

final priceCacheRepositoryProvider = Provider<PriceCacheRepository>((ref) {
  return PriceCacheRepository(ref.watch(databaseProvider));
});

final cryptoPriceProviderProvider = Provider((ref) => CoinGeckoPriceProvider());
final _fxProviderProvider = Provider((ref) => FxPriceProvider());

final stockPriceProviderProvider = Provider((ref) => YahooFinancePriceProvider());

final priceRefreshServiceProvider = Provider<PriceRefreshService>((ref) {
  final metalsApiKey = ref.watch(metalsApiKeyProvider);
  return PriceRefreshService(
    cryptoProvider: ref.watch(cryptoPriceProviderProvider),
    fxProvider: ref.watch(_fxProviderProvider),
    // goldapi.io's free tier keeps running out of its monthly quota --
    // gold-api.com (no signup, no per-account quota) automatically fills
    // in whatever it couldn't price instead of leaving metals unpriced
    // until the quota resets.
    metalsProvider: FallbackPriceProvider(
      primary: MetalsPriceProvider(apiKey: metalsApiKey),
      secondary: GoldApiComPriceProvider(),
    ),
    stockProvider: ref.watch(stockPriceProviderProvider),
  );
});

/// Loads whatever prices were cached from the last successful refresh so
/// the dashboard has numbers to show immediately on launch, even offline.
/// Triggered once by whichever screen watches it first.
final cachedPricesLoaderProvider = FutureProvider<void>((ref) async {
  final cached = await ref.watch(priceCacheRepositoryProvider).loadAll();
  if (cached.isEmpty) return;
  ref.read(pricesUsdPerUnitProvider.notifier).state = cached;
  final egpValueOfOneUsd = cached['EGP'];
  if (egpValueOfOneUsd != null) {
    ref.read(usdToEgpRateProvider.notifier).state = 1 / egpValueOfOneUsd;
  }
});

class PriceRefreshState {
  const PriceRefreshState({this.isRefreshing = false, this.lastRefreshedAt, this.errors = const []});

  final bool isRefreshing;
  final DateTime? lastRefreshedAt;
  final List<String> errors;

  PriceRefreshState copyWith({bool? isRefreshing, DateTime? lastRefreshedAt, List<String>? errors}) {
    return PriceRefreshState(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
      errors: errors ?? this.errors,
    );
  }
}

class PriceRefreshController extends Notifier<PriceRefreshState> {
  @override
  PriceRefreshState build() => const PriceRefreshState();

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, errors: const []);

    final assets = ref.read(assetsStreamProvider).valueOrNull ?? const [];
    final outcome = await refreshAndPersistPrices(
      assets: assets,
      service: ref.read(priceRefreshServiceProvider),
      cacheRepo: ref.read(priceCacheRepositoryProvider),
    );

    ref.read(pricesUsdPerUnitProvider.notifier).state = outcome.allPrices;
    if (outcome.usdToEgpRate != null) {
      ref.read(usdToEgpRateProvider.notifier).state = outcome.usdToEgpRate;
    }

    state = state.copyWith(isRefreshing: false, lastRefreshedAt: DateTime.now(), errors: outcome.errors);
  }
}

final priceRefreshControllerProvider =
    NotifierProvider<PriceRefreshController, PriceRefreshState>(PriceRefreshController.new);

/// Loading the cache alone only shows what was last fetched — nothing was
/// actually kicking off a *live* fetch on its own, so prices could go
/// stale indefinitely between manual taps of "refresh" (the periodic
/// background task exists too, but its first run isn't guaranteed to be
/// prompt). This kicks off one live refresh automatically per app launch,
/// once the cache is loaded and the asset list has emitted at least once.
/// Watched once from the dashboard, same pattern as [cachedPricesLoaderProvider].
final autoRefreshOnLaunchProvider = FutureProvider<void>((ref) async {
  await ref.read(cachedPricesLoaderProvider.future);
  await ref.read(assetsStreamProvider.future);
  unawaited(ref.read(priceRefreshControllerProvider.notifier).refresh());
});

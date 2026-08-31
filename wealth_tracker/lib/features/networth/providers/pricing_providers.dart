import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/pricing/coingecko_price_provider.dart';
import '../../../data/pricing/fallback_price_provider.dart';
import '../../../data/pricing/fx_price_provider.dart';
import '../../../data/pricing/gold_api_com_price_provider.dart';
import '../../../data/pricing/metals_price_provider.dart';
import '../../../data/pricing/price_provider.dart';
import '../../../data/pricing/price_refresh_orchestrator.dart';
import '../../../data/pricing/price_refresh_service.dart';
import '../../../data/pricing/stock_search_aggregator.dart';
import '../../../data/pricing/stockanalysis_price_provider.dart';
import '../../../data/pricing/yahoo_finance_price_provider.dart';
import '../../../data/pricing/yahoo_metals_price_provider.dart';
import '../../../data/repositories/price_cache_repository.dart';
import '../../settings/providers/settings_providers.dart';
import 'asset_providers.dart';

final priceCacheRepositoryProvider = Provider<PriceCacheRepository>((ref) {
  return PriceCacheRepository(ref.watch(databaseProvider));
});

final cryptoPriceProviderProvider = Provider((ref) => CoinGeckoPriceProvider());
final fxPriceProviderProvider = Provider((ref) => FxPriceProvider());

final yahooFinancePriceProviderProvider = Provider((ref) => YahooFinancePriceProvider());
final stockAnalysisPriceProviderProvider = Provider((ref) => StockAnalysisPriceProvider());

/// Yahoo Finance first, stockanalysis.com filling in whatever Yahoo
/// couldn't price -- primarily EGX names Yahoo indexes under an opaque
/// code instead of the plain ticker. See [StockAnalysisPriceProvider]'s
/// doc comment for why this is safe to add as a pure fallback.
final stockPriceProviderProvider = Provider<PriceProvider>((ref) {
  return FallbackPriceProvider(
    primary: ref.watch(yahooFinancePriceProviderProvider),
    secondary: ref.watch(stockAnalysisPriceProviderProvider),
  );
});

/// Search, unlike price fetching, merges both sources rather than treating
/// one as a fallback for the other -- see [StockSearchAggregator].
final stockSearchAggregatorProvider = Provider((ref) {
  return StockSearchAggregator(
    yahoo: ref.watch(yahooFinancePriceProviderProvider),
    stockAnalysis: ref.watch(stockAnalysisPriceProviderProvider),
  );
});

/// The real, three-tier gold/silver fallback chain used both by the normal
/// refresh flow and by the Settings > Live Prices "Test price sources"
/// diagnostic -- shared so the diagnostic exercises exactly what
/// production uses (including the user's own goldapi.io key), not a
/// separate stand-in that could pass while the real chain doesn't.
///
/// goldapi.io's free tier keeps running out of its monthly quota, and
/// gold-api.com -- the first fallback -- has started 429-rate-limiting too.
/// Yahoo Finance (keyless, same reliable endpoint this app already uses for
/// every stock price) is the third and last resort.
final metalsPriceProviderProvider = Provider<PriceProvider>((ref) {
  final metalsApiKey = ref.watch(metalsApiKeyProvider);
  return FallbackPriceProvider(
    primary: FallbackPriceProvider(
      primary: MetalsPriceProvider(apiKey: metalsApiKey),
      secondary: GoldApiComPriceProvider(),
    ),
    secondary: YahooMetalsPriceProvider(),
  );
});

final priceRefreshServiceProvider = Provider<PriceRefreshService>((ref) {
  return PriceRefreshService(
    cryptoProvider: ref.watch(cryptoPriceProviderProvider),
    fxProvider: ref.watch(fxPriceProviderProvider),
    metalsProvider: ref.watch(metalsPriceProviderProvider),
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

/// One source's outcome from [PriceSourceTestController.testAll].
class PriceSourceCheck {
  const PriceSourceCheck({required this.label, required this.ok, this.detail});

  final String label;
  final bool ok;

  /// The exact error text on failure -- surfaced verbatim (not summarized)
  /// so a report back from the user is immediately actionable instead of
  /// "it doesn't work."
  final String? detail;
}

class PriceSourceTestState {
  const PriceSourceTestState({this.isTesting = false, this.results = const []});

  final bool isTesting;
  final List<PriceSourceCheck> results;

  PriceSourceTestState copyWith({bool? isTesting, List<PriceSourceCheck>? results}) {
    return PriceSourceTestState(isTesting: isTesting ?? this.isTesting, results: results ?? this.results);
  }
}

/// Calls each price source directly with a fixed, always-available test
/// symbol (BTC, USD->EGP, gold, silver, AAPL) regardless of what assets the
/// user actually holds -- unlike a normal refresh, which only ever queries
/// symbols in use, so a user with no stock assets would never actually
/// exercise the stock provider. Gold and silver go through
/// [metalsPriceProviderProvider], the exact same three-tier fallback chain
/// (goldapi.io -> gold-api.com -> Yahoo Finance) production uses, so a pass
/// here means the real chain -- not a stand-in -- is currently reachable.
class PriceSourceTestController extends Notifier<PriceSourceTestState> {
  @override
  PriceSourceTestState build() => const PriceSourceTestState();

  Future<void> testAll() async {
    state = state.copyWith(isTesting: true, results: const []);

    Future<PriceSourceCheck> check(String label, PriceProvider provider, Set<String> symbols) async {
      try {
        final prices = await provider.fetchPrices(symbols);
        if (prices.isEmpty) {
          return PriceSourceCheck(label: label, ok: false, detail: 'No price returned');
        }
        return PriceSourceCheck(label: label, ok: true);
      } catch (e) {
        return PriceSourceCheck(label: label, ok: false, detail: e.toString());
      }
    }

    final results = [
      await check('Crypto (CoinGecko)', ref.read(cryptoPriceProviderProvider), {'bitcoin'}),
      await check('Currency exchange (open.er-api.com)', ref.read(fxPriceProviderProvider), {'EGP'}),
      await check('Gold', ref.read(metalsPriceProviderProvider), {'XAU_GRAM_24K'}),
      await check('Silver', ref.read(metalsPriceProviderProvider), {'XAG_GRAM'}),
      await check('Stocks (Yahoo Finance)', ref.read(yahooFinancePriceProviderProvider), {'AAPL'}),
      await check(
        'Stocks (StockAnalysis.com, EGX fallback)',
        ref.read(stockAnalysisPriceProviderProvider),
        {'SA:s:aapl'},
      ),
    ];

    state = state.copyWith(isTesting: false, results: results);
  }
}

final priceSourceTestControllerProvider =
    NotifierProvider<PriceSourceTestController, PriceSourceTestState>(PriceSourceTestController.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/pricing/coingecko_price_provider.dart';
import '../../../data/pricing/fx_price_provider.dart';
import '../../../data/pricing/metals_price_provider.dart';
import '../../../data/pricing/price_refresh_service.dart';
import '../../../data/repositories/price_cache_repository.dart';
import '../../settings/providers/settings_providers.dart';
import 'asset_providers.dart';

final priceCacheRepositoryProvider = Provider<PriceCacheRepository>((ref) {
  return PriceCacheRepository(ref.watch(databaseProvider));
});

final _cryptoProviderProvider = Provider((ref) => CoinGeckoPriceProvider());
final _fxProviderProvider = Provider((ref) => FxPriceProvider());

final priceRefreshServiceProvider = Provider<PriceRefreshService>((ref) {
  final metalsApiKey = ref.watch(metalsApiKeyProvider);
  return PriceRefreshService(
    cryptoProvider: ref.watch(_cryptoProviderProvider),
    fxProvider: ref.watch(_fxProviderProvider),
    metalsProvider: MetalsPriceProvider(apiKey: metalsApiKey),
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
    final service = ref.read(priceRefreshServiceProvider);
    final result = await service.refresh(assets);

    if (result.prices.isNotEmpty) {
      final merged = {...ref.read(pricesUsdPerUnitProvider), ...result.prices};
      ref.read(pricesUsdPerUnitProvider.notifier).state = merged;
      await ref.read(priceCacheRepositoryProvider).upsertAll(result.prices);
    }
    if (result.usdToEgpRate != null) {
      ref.read(usdToEgpRateProvider.notifier).state = result.usdToEgpRate;
    }

    state = state.copyWith(isRefreshing: false, lastRefreshedAt: DateTime.now(), errors: result.errors);
  }
}

final priceRefreshControllerProvider =
    NotifierProvider<PriceRefreshController, PriceRefreshState>(PriceRefreshController.new);

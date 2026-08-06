import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/net_worth/net_worth_calculator.dart';
import '../../../data/repositories/asset_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(databaseProvider));
});

final assetsStreamProvider = StreamProvider<List<Asset>>((ref) {
  return ref.watch(assetRepositoryProvider).watchAll();
});

/// Live USD price per unit, keyed by symbol/currency code. Populated by the
/// pricing layer (see `data/pricing`); empty until a refresh has run, in
/// which case only manually-valued assets contribute to net worth.
final pricesUsdPerUnitProvider = StateProvider<Map<String, double>>((ref) => {});

/// USD -> EGP rate used to derive the EGP display totals from the USD
/// totals net worth is computed in.
final usdToEgpRateProvider = StateProvider<double?>((ref) => null);

final netWorthResultProvider = Provider<NetWorthResult>((ref) {
  final assets = ref.watch(assetsStreamProvider).valueOrNull ?? const [];
  final prices = ref.watch(pricesUsdPerUnitProvider);
  return calculateNetWorth(assets, prices);
});

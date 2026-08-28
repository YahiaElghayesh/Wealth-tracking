import '../../core/models/asset_category.dart';
import '../db/database.dart';

/// Totals in USD. EGP (or any other display currency) is derived by
/// multiplying by a live FX rate at the UI layer — there is nothing
/// currency-specific baked into these numbers.
class NetWorthSummary {
  final double liquidUsd;
  final double nonLiquidUsd;

  const NetWorthSummary({required this.liquidUsd, required this.nonLiquidUsd});

  static const zero = NetWorthSummary(liquidUsd: 0, nonLiquidUsd: 0);

  double get totalUsd => liquidUsd + nonLiquidUsd;
}

/// Resolves the USD value of a single [Asset] given a lookup of live
/// per-unit USD prices, keyed by the asset's `symbolOrCurrency` (crypto
/// ticker, `XAU_GRAM` / `XAG_GRAM`, or a currency code). The formula is the
/// same regardless of [ValuationMode] — quantity times the live price of
/// whatever it's denominated in — the mode only determines which price
/// provider supplies that number.
///
/// Returns `null` (rather than 0) when the asset needs a live price that
/// isn't in [pricesUsdPerUnit] yet, so callers can distinguish "genuinely
/// worth zero" from "price unknown" instead of silently under-counting net
/// worth.
double? valueUsdForAsset(Asset asset, Map<String, double> pricesUsdPerUnit) {
  final price = pricesUsdPerUnit[asset.symbolOrCurrency];
  if (price == null) return null;
  return asset.quantity * price;
}

/// Sums a list of assets into liquid/non-liquid USD totals. Assets whose
/// live price is currently unknown are excluded from the totals (rather
/// than counted as zero) — [unpricedAssets] reports which ones so the UI
/// can flag them instead of silently understating net worth.
class NetWorthResult {
  final NetWorthSummary summary;
  final List<Asset> unpricedAssets;

  const NetWorthResult(this.summary, this.unpricedAssets);
}

NetWorthResult calculateNetWorth(
  List<Asset> assets,
  Map<String, double> pricesUsdPerUnit,
) {
  var liquid = 0.0;
  var nonLiquid = 0.0;
  final unpriced = <Asset>[];

  for (final asset in assets) {
    final value = valueUsdForAsset(asset, pricesUsdPerUnit);
    if (value == null) {
      unpriced.add(asset);
      continue;
    }
    final assetClass = AssetCategory.values.byName(asset.category).defaultClass;
    if (assetClass == AssetClass.liquid) {
      liquid += value;
    } else {
      nonLiquid += value;
    }
  }

  return NetWorthResult(
    NetWorthSummary(liquidUsd: liquid, nonLiquidUsd: nonLiquid),
    unpriced,
  );
}

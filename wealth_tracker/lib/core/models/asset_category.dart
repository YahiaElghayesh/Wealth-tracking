/// Whether an asset can realistically be turned into cash quickly.
enum AssetClass { liquid, nonLiquid }

/// How an asset's current value is determined.
enum ValuationMode {
  /// Priced via a crypto symbol (e.g. BTC, ETH) against [Asset.quantity].
  crypto,

  /// Priced via a precious metal (gold/silver) per gram against
  /// [Asset.quantity] (grams held).
  metal,

  /// An amount denominated in a chosen currency (see `core/models/currency.dart`),
  /// converted to USD via live FX. Covers both literal cash holdings and
  /// assets the user assigns a value to directly (a car, an apartment) —
  /// mechanically identical, since "a car worth 500,000 EGP" and "500,000
  /// EGP in the bank" price the same way.
  currency,
}

/// Broad category an asset falls under. Drives the default liquid /
/// non-liquid split and the default [ValuationMode].
enum AssetCategory {
  crypto('Crypto', AssetClass.liquid, ValuationMode.crypto),
  gold('Gold', AssetClass.liquid, ValuationMode.metal),
  silver('Silver', AssetClass.liquid, ValuationMode.metal),
  cash('Cash', AssetClass.liquid, ValuationMode.currency),
  vehicle('Vehicle', AssetClass.nonLiquid, ValuationMode.currency),
  realEstate('Real Estate', AssetClass.nonLiquid, ValuationMode.currency),
  other('Other', AssetClass.nonLiquid, ValuationMode.currency);

  final String label;
  final AssetClass defaultClass;
  final ValuationMode defaultValuationMode;

  const AssetCategory(this.label, this.defaultClass, this.defaultValuationMode);
}

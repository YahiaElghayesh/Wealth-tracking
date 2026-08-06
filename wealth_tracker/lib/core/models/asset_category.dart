/// Whether an asset can realistically be turned into cash quickly.
enum AssetClass { liquid, nonLiquid }

/// How an asset's current value is determined.
enum ValuationMode {
  /// User types the current value directly (e.g. a car, an apartment).
  manual,

  /// Priced via a crypto symbol (e.g. BTC, ETH) against [Asset.quantity].
  crypto,

  /// Priced via a precious metal (gold/silver) per gram against
  /// [Asset.quantity] (grams held).
  metal,

  /// Priced via an FX rate for a fiat currency (e.g. USD, EGP) against
  /// [Asset.quantity] (units of that currency held).
  fiatCurrency,
}

/// Broad category an asset falls under. Drives the default liquid /
/// non-liquid split and the default [ValuationMode].
enum AssetCategory {
  crypto('Crypto', AssetClass.liquid, ValuationMode.crypto),
  gold('Gold', AssetClass.liquid, ValuationMode.metal),
  silver('Silver', AssetClass.liquid, ValuationMode.metal),
  cash('Cash', AssetClass.liquid, ValuationMode.fiatCurrency),
  vehicle('Vehicle', AssetClass.nonLiquid, ValuationMode.manual),
  realEstate('Real Estate', AssetClass.nonLiquid, ValuationMode.manual),
  other('Other', AssetClass.nonLiquid, ValuationMode.manual);

  final String label;
  final AssetClass defaultClass;
  final ValuationMode defaultValuationMode;

  const AssetCategory(this.label, this.defaultClass, this.defaultValuationMode);
}

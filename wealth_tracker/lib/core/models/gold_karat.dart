/// Gold purity. Price per gram scales linearly with purity against 24K
/// (pure gold) — 21K jewelry (the common purity in Egypt) is worth
/// 21/24 of the pure-gold price per gram, and so on.
enum GoldKarat {
  k24(24),
  k22(22),
  k21(21),
  k18(18),
  k14(14),
  k10(10);

  final int purity;

  const GoldKarat(this.purity);

  String get label => '${purity}K';

  double get purityFraction => purity / 24;

  /// The price-cache/price-provider symbol for this karat's gold, e.g.
  /// `XAU_GRAM_21K`.
  String get priceSymbol => 'XAU_GRAM_${purity}K';

  static GoldKarat? fromPriceSymbol(String symbol) {
    for (final k in values) {
      if (k.priceSymbol == symbol) return k;
    }
    return null;
  }
}

/// 21K ("Egyptian gold") is the standard local jewelry purity — the
/// sensible default here, though any karat is selectable.
const defaultGoldKarat = GoldKarat.k21;

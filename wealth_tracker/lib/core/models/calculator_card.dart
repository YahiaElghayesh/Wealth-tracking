/// The three credit cards tracked by the "current liquid cash" calculator.
/// [defaultLimit] seeds the persisted, user-editable limit (see Settings)
/// the first time it's read — after that, whatever the user set there
/// wins.
///
/// The user enters each card's *available-to-spend* balance (what their
/// banking app shows), not what they owe — the owed amount is derived as
/// `limit - availableBalance`. See `current_money_calculator.dart`.
enum CalculatorCard {
  nbe('card_nbe_limit', 'NBE Wallet', defaultLimit: 500000),
  cibExplorerWallet('card_cib_explorer_wallet_limit', 'CIB Explore World', defaultLimit: 109900),
  cibPlatinum('card_cib_platinum_limit', 'CIB Platinum', defaultLimit: 145500);

  const CalculatorCard(this.storageKey, this.label, {required this.defaultLimit});

  final String storageKey;
  final String label;
  final double defaultLimit;

  static CalculatorCard? fromStorageKey(String key) {
    for (final card in values) {
      if (card.storageKey == key) return card;
    }
    return null;
  }
}

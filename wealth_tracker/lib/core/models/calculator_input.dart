/// The fixed set of manually-entered values behind the "current liquid
/// cash" calculator (everything besides the ledger totals, which auto-sum
/// from existing data). [creditLimit] is informational only — shown next to
/// the balance field for reference — and never enters the calculation.
///
/// Named `...Key` (not `CalculatorInput`) because drift generates a row
/// class called `CalculatorInput` from the `CalculatorInputs` table — same
/// singularization drift applies to `Assets` -> `Asset`.
enum CalculatorInputKey {
  apartmentSavings('apartment_savings', 'Apartment savings', isCard: false),
  cibAccountBalance('cib_account_balance', 'CIB account balance', isCard: false),
  cardNbe('card_nbe', 'NBE', isCard: true, creditLimit: 500000),
  cardCibExplorerWallet('card_cib_explorer_wallet', 'CIB Explorer Wallet', isCard: true, creditLimit: 109900),
  cardCibPlatinum('card_cib_platinum', 'CIB Platinum', isCard: true, creditLimit: 145500);

  const CalculatorInputKey(this.storageKey, this.label, {required this.isCard, this.creditLimit});

  final String storageKey;
  final String label;
  final bool isCard;

  /// Reference-only credit limit in EGP, shown alongside the card's current
  /// balance field; not used anywhere in the calculation itself.
  final double? creditLimit;

  static const cards = [cardNbe, cardCibExplorerWallet, cardCibPlatinum];

  static CalculatorInputKey? fromStorageKey(String key) {
    for (final input in values) {
      if (input.storageKey == key) return input;
    }
    return null;
  }
}

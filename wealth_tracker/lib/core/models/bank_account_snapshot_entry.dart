/// A bank account's numbers at the moment a Calculator snapshot was saved —
/// captured directly (not just a reference to the live [BankAccount] row)
/// so renaming or deleting one later never changes past history. Mirrors
/// [CardSnapshotEntry]'s role for credit cards.
class BankAccountSnapshotEntry {
  const BankAccountSnapshotEntry({
    required this.name,
    required this.bank,
    required this.currency,
    required this.availableBalance,
  });

  final String name;
  final String bank;
  final String currency;

  /// In [currency] — not yet converted to the app's settlement currency.
  final double availableBalance;

  Map<String, dynamic> toJson() => {
    'name': name,
    'bank': bank,
    'currency': currency,
    'availableBalance': availableBalance,
  };

  static BankAccountSnapshotEntry fromJson(Map<String, dynamic> json) =>
      BankAccountSnapshotEntry(
        name: json['name'] as String,
        bank: json['bank'] as String,
        currency: json['currency'] as String,
        availableBalance: (json['availableBalance'] as num).toDouble(),
      );
}

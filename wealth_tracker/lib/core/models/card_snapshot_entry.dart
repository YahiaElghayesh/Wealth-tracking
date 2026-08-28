/// A credit card's numbers at the moment a Calculator snapshot was saved —
/// captured directly (not just a reference to the live [CreditCard] row) so
/// renaming, re-limiting, or deleting a card later never changes past
/// history.
class CardSnapshotEntry {
  const CardSnapshotEntry({
    required this.name,
    required this.bank,
    required this.currency,
    required this.limit,
    required this.availableBalance,
    required this.owed,
  });

  final String name;
  final String bank;
  final String currency;
  final double limit;
  final double availableBalance;

  /// In [currency] — not yet converted to the app's settlement currency.
  final double owed;

  Map<String, dynamic> toJson() => {
        'name': name,
        'bank': bank,
        'currency': currency,
        'limit': limit,
        'availableBalance': availableBalance,
        'owed': owed,
      };

  static CardSnapshotEntry fromJson(Map<String, dynamic> json) => CardSnapshotEntry(
        name: json['name'] as String,
        bank: json['bank'] as String,
        currency: json['currency'] as String,
        limit: (json['limit'] as num).toDouble(),
        availableBalance: (json['availableBalance'] as num).toDouble(),
        owed: (json['owed'] as num).toDouble(),
      );
}

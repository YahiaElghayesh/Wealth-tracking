/// A manual input's numbers at the moment a Calculator snapshot was saved —
/// captured directly (not just a reference to the live [ManualInput] row)
/// so renaming or deleting one later never changes past history. Mirrors
/// [CardSnapshotEntry]'s role for credit cards.
class ManualInputSnapshotEntry {
  const ManualInputSnapshotEntry({
    required this.name,
    required this.amount,
    required this.isAddition,
    required this.currency,
  });

  final String name;

  /// The magnitude entered, in [currency] -- not yet signed or converted.
  final double amount;
  final bool isAddition;
  final String currency;

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'isAddition': isAddition,
        'currency': currency,
      };

  static ManualInputSnapshotEntry fromJson(Map<String, dynamic> json) => ManualInputSnapshotEntry(
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        isAddition: json['isAddition'] as bool,
        currency: json['currency'] as String,
      );
}

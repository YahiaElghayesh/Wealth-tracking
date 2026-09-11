/// An expected transaction's numbers at the moment a Calculator snapshot
/// was saved — captured directly (not just a reference to the live
/// [ExpectedTransaction] row) so renaming or deleting one later never
/// changes past history. Mirrors [ManualInputSnapshotEntry]'s role, with
/// one addition: [enabled], since only an enabled expected transaction
/// actually counted toward that snapshot's total -- history needs to show
/// which was which, not just what existed.
class ExpectedTransactionSnapshotEntry {
  const ExpectedTransactionSnapshotEntry({
    required this.name,
    required this.amount,
    required this.isAddition,
    required this.currency,
    required this.enabled,
  });

  final String name;
  final double amount;
  final bool isAddition;
  final String currency;
  final bool enabled;

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'isAddition': isAddition,
    'currency': currency,
    'enabled': enabled,
  };

  static ExpectedTransactionSnapshotEntry fromJson(Map<String, dynamic> json) =>
      ExpectedTransactionSnapshotEntry(
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        isAddition: json['isAddition'] as bool,
        currency: json['currency'] as String,
        enabled: json['enabled'] as bool,
      );
}

/// One recurring payment that was due within a recorded history month --
/// one per entry in [RecurringPaymentHistory.itemsJson] (see that column's
/// own doc comment in tables.dart). [amount] is already converted to the
/// app's settlement currency at record time, the same convention
/// [RecurringPaymentHistory.totalAmount]/[paidAmount] already use, so this
/// list's amounts always sum to within rounding of those two totals.
class RecurringPaymentHistoryItem {
  const RecurringPaymentHistoryItem({
    required this.name,
    required this.amount,
    required this.paid,
  });

  final String name;
  final double amount;
  final bool paid;

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'paid': paid,
  };

  static RecurringPaymentHistoryItem fromJson(Map<String, dynamic> json) =>
      RecurringPaymentHistoryItem(
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        paid: json['paid'] as bool,
      );
}

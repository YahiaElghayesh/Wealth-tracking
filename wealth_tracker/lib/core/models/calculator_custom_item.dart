/// One ad-hoc line item the user adds to a calculation for anything not
/// covered by the fixed categories (ledgers, apartment savings, CIB
/// balance, cards) — a label, an amount, and whether it adds to or
/// subtracts from the total.
class CustomCalculatorItem {
  const CustomCalculatorItem({required this.label, required this.amount, required this.isAddition});

  final String label;
  final double amount;
  final bool isAddition;

  /// Signed contribution to the total.
  double get signedAmount => isAddition ? amount : -amount;

  Map<String, dynamic> toJson() => {'label': label, 'amount': amount, 'isAddition': isAddition};

  static CustomCalculatorItem fromJson(Map<String, dynamic> json) => CustomCalculatorItem(
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
        isAddition: json['isAddition'] as bool,
      );
}

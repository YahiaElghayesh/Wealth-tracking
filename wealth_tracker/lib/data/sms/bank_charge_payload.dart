/// One detected bank charge, ready for the review screen — carries a
/// vendor-rule match when one exists so the screen can pre-fill instead of
/// asking the user to pick a ledger from nothing.
class BankChargePayload {
  const BankChargePayload({
    required this.vendor,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.dedupeId,
    this.counterpartyId,
    this.category,
  });

  final String vendor;
  final double amount;
  final String currency;
  final DateTime occurredAt;
  final String dedupeId;

  /// Non-null only when a vendor rule matched.
  final String? counterpartyId;
  final String? category;
}

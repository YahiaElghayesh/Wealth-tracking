/// A [CreditCard.supplementaryLastFourDigits] cell holds a comma-separated
/// list rather than a single value -- chosen over a JSON array (or a
/// separate join table) specifically so it needed no schema migration at
/// all: every value already stored there before this supported more than
/// one card is a plain 4-digit string, which decodes here as a
/// single-element list exactly like a real comma-separated list of one
/// would.
List<String> decodeSupplementaryLastFour(String? raw) {
  if (raw == null) return const [];
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Inverse of [decodeSupplementaryLastFour] -- null (not an empty string)
/// once the list is empty, matching how the column's "no supplementary
/// card" state has always been represented.
String? encodeSupplementaryLastFour(List<String> digits) {
  final cleaned = digits
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return cleaned.isEmpty ? null : cleaned.join(',');
}

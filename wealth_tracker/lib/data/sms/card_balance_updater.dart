import 'package:drift/drift.dart';

import '../db/database.dart';
import 'bank_sms_parser.dart';

/// If [parsed] carries last-4-digits that match a known [CreditCard],
/// updates that card's tracked available balance and returns it — a
/// passive, unconfirmed update (unlike a ledger entry, there's no "on
/// whose behalf" decision to make, just a number to keep current), so this
/// never asks the user anything.
///
/// Prefers the balance the bank itself stated after the transaction
/// ([ParsedBankSms.availableBalanceAfter]) whenever *that figure's own
/// currency* ([ParsedBankSms.availableBalanceCurrency], falling back to
/// [ParsedBankSms.currency] for older callers that don't distinguish the
/// two) matches the card's tracked currency — this is deliberately checked
/// independently of the charge's own currency, since a bank can state an
/// available balance in a different currency than the transaction that
/// triggered the alert (e.g. NBE reports a EGP-billed card's balance in
/// EGP even when the charge itself was in USD). Falls back to adding or
/// subtracting [ParsedBankSms.amount] from whatever was last known (or the
/// card's limit, if nothing was ever recorded) when no usable stated
/// balance is available and the charge's own currency matches the card's.
/// Returns `null` when there's no matching card, or neither of those two
/// paths can be trusted (mixing currencies here would silently corrupt the
/// balance).
Future<CreditCard?> updateCardBalanceFromSms(AppDatabase db, ParsedBankSms parsed, {required String profileId}) async {
  final lastFour = parsed.lastFourDigits;
  if (lastFour == null) return null;

  final cards = await (db.select(db.creditCards)..where((c) => c.profileId.equals(profileId))).get();
  CreditCard? card;
  for (final c in cards) {
    if (c.lastFourDigits == lastFour) {
      card = c;
      break;
    }
  }
  if (card == null) return null;

  final availCurrency = parsed.availableBalanceCurrency ?? parsed.currency;
  final double newBalance;
  if (parsed.availableBalanceAfter != null && availCurrency == card.currency) {
    newBalance = parsed.availableBalanceAfter!;
  } else if (card.currency == parsed.currency) {
    final current = card.currentAvailableBalance ?? card.limitAmount;
    newBalance = parsed.isCharge ? current - parsed.amount : current + parsed.amount;
  } else {
    return null;
  }

  final updated = card.copyWith(
    currentAvailableBalance: Value(newBalance),
    balanceUpdatedAt: Value(DateTime.now()),
  );
  await db.update(db.creditCards).replace(updated);
  return updated;
}

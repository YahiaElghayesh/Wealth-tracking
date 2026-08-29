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
/// ([ParsedBankSms.availableBalanceAfter]); falls back to adding or
/// subtracting [ParsedBankSms.amount] from whatever was last known (or the
/// card's limit, if nothing was ever recorded) when the SMS didn't state
/// one. Returns `null` when there's no matching card or the currencies
/// don't line up (mixing currencies here would silently corrupt the
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
  if (card == null || card.currency != parsed.currency) return null;

  final newBalance = parsed.availableBalanceAfter ??
      () {
        final current = card!.currentAvailableBalance ?? card.limitAmount;
        return parsed.isCharge ? current - parsed.amount : current + parsed.amount;
      }();

  final updated = card.copyWith(
    currentAvailableBalance: Value(newBalance),
    balanceUpdatedAt: Value(DateTime.now()),
  );
  await db.update(db.creditCards).replace(updated);
  return updated;
}

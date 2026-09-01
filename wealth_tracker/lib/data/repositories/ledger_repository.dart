import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// Scoped to one [profileId] -- see `AssetRepository`'s doc comment for the
/// pattern (every query filters to it, every insert stamps it, the provider
/// rebuilds on profile switch).
class LedgerRepository {
  LedgerRepository(this._db, this.profileId);

  final AppDatabase _db;
  final String profileId;
  static const _uuid = Uuid();

  Stream<List<Counterparty>> watchCounterparties() {
    return (_db.select(_db.counterparties)
          ..where((c) => c.profileId.equals(profileId))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  /// Returns the new ledger's id -- callers that need to select it right
  /// away (e.g. the "add a new ledger" option inline on Add Payment) don't
  /// have any other way to get it, since it's generated here rather than
  /// passed in.
  Future<String> addCounterparty(
    String name, {
    bool includeInStatistics = true,
    bool includeInCalculator = true,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.counterparties)
        .insert(
          CounterpartiesCompanion.insert(
            id: id,
            name: name,
            includeInStatistics: Value(includeInStatistics),
            includeInCalculator: Value(includeInCalculator),
            profileId: Value(profileId),
          ),
        );
    return id;
  }

  Future<void> deleteCounterparty(String id) async {
    await (_db.delete(
      _db.ledgerTransactions,
    )..where((t) => t.counterpartyId.equals(id))).go();
    await (_db.delete(_db.counterparties)..where((c) => c.id.equals(id))).go();
  }

  Future<void> updateCounterparty(Counterparty counterparty) {
    return _db.update(_db.counterparties).replace(counterparty);
  }

  Stream<List<LedgerTransaction>> watchTransactions(String counterpartyId) {
    return (_db.select(_db.ledgerTransactions)
          ..where((t) => t.counterpartyId.equals(counterpartyId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Every transaction across every counterparty *in this profile*.
  /// `runningBalance` applied to this combined list is the calculator's "sum
  /// of all ledgers" figure — summing amounts is linear, so this is
  /// equivalent to totaling each counterparty's own balance, just without
  /// grouping.
  Stream<List<LedgerTransaction>> watchAllTransactions() {
    return (_db.select(
      _db.ledgerTransactions,
    )..where((t) => t.profileId.equals(profileId))).watch();
  }

  Future<void> addTransaction({
    required String counterpartyId,
    required DateTime date,
    required double amount,
    required String currency,
    required String category,
    String? description,
  }) {
    return _db
        .into(_db.ledgerTransactions)
        .insert(
          LedgerTransactionsCompanion.insert(
            id: _uuid.v4(),
            counterpartyId: counterpartyId,
            date: date,
            amount: amount,
            currency: Value(currency),
            category: category,
            description: Value(description),
            createdAt: DateTime.now(),
            profileId: Value(profileId),
          ),
        );
  }

  Future<void> updateTransaction(LedgerTransaction transaction) {
    return _db.update(_db.ledgerTransactions).replace(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await (_db.delete(
      _db.ledgerTransactions,
    )..where((t) => t.id.equals(id))).go();
  }
}

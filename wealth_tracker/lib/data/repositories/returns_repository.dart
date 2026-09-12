import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// Scoped to one [profileId] -- see `AssetRepository`'s doc comment for the
/// pattern (every query filters to it, every insert stamps it, the provider
/// rebuilds on profile switch).
class ReturnsRepository {
  ReturnsRepository(this._db, this.profileId);

  final AppDatabase _db;
  final String profileId;
  static const _uuid = Uuid();

  /// Every return for this profile, pending and received alike -- the
  /// Returns tab and its History screen both watch this and split it
  /// client-side by [Return.receivedAt], the same way Statistics filters
  /// [counterpartiesStreamProvider] instead of keeping a separate stream.
  Stream<List<Return>> watchAll() {
    return (_db.select(_db.returns)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.returnDate)]))
        .watch();
  }

  Future<void> addReturn({
    required String vendor,
    required double amount,
    required String currency,
    required DateTime returnDate,
  }) {
    return _db
        .into(_db.returns)
        .insert(
          ReturnsCompanion.insert(
            id: _uuid.v4(),
            vendor: vendor,
            amount: amount,
            currency: Value(currency),
            returnDate: returnDate,
            createdAt: DateTime.now(),
            profileId: Value(profileId),
          ),
        );
  }

  Future<void> updateReturn(Return returnItem) {
    return _db.update(_db.returns).replace(returnItem);
  }

  /// Marks a pending return received -- this alone is what moves it from
  /// the pending list into history (see [watchAll]'s own doc comment).
  Future<void> markReceived(String id) {
    return (_db.update(_db.returns)..where((t) => t.id.equals(id))).write(
      ReturnsCompanion(receivedAt: Value(DateTime.now())),
    );
  }

  /// Undoes a mistaken "Received" tap from the History screen -- moves the
  /// entry back to pending.
  Future<void> markPending(String id) {
    return (_db.update(_db.returns)..where((t) => t.id.equals(id))).write(
      const ReturnsCompanion(receivedAt: Value(null)),
    );
  }

  Future<void> deleteReturn(String id) {
    return (_db.delete(_db.returns)..where((t) => t.id.equals(id))).go();
  }
}

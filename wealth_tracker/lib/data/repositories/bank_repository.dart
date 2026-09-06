import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// Scoped to one [profileId] -- see `AssetRepository`'s doc comment for the
/// pattern. The shared list of bank names Credit Cards, Bank Accounts, and
/// SMS Rules all pick from.
class BankRepository {
  BankRepository(this._db, this.profileId);

  final AppDatabase _db;
  final String profileId;
  static const _uuid = Uuid();

  Stream<List<Bank>> watchAll() {
    return (_db.select(_db.banks)
          ..where((b) => b.profileId.equals(profileId))
          ..orderBy([(b) => OrderingTerm.asc(b.sortOrder)]))
        .watch();
  }

  Future<String> add(String name) async {
    final count = await (_db.select(
      _db.banks,
    )..where((b) => b.profileId.equals(profileId))).get();
    final id = _uuid.v4();
    await _db
        .into(_db.banks)
        .insert(
          BanksCompanion.insert(
            id: id,
            name: name,
            sortOrder: Value(count.length),
            profileId: Value(profileId),
          ),
        );
    return id;
  }

  Future<void> rename(String id, String name) {
    return (_db.update(
      _db.banks,
    )..where((b) => b.id.equals(id))).write(BanksCompanion(name: Value(name)));
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.banks)..where((b) => b.id.equals(id))).go();
  }
}

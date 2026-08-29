import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// Scoped to one [profileId] -- every query filters to it, every insert
/// stamps it. The provider that constructs this rebuilds whenever the
/// active profile changes (see `activeProfileIdProvider`), so callers never
/// pass a profile id themselves.
class AssetRepository {
  AssetRepository(this._db, this.profileId);

  final AppDatabase _db;
  final String profileId;
  static const _uuid = Uuid();

  Stream<List<Asset>> watchAll() {
    return (_db.select(_db.assets)
          ..where((a) => a.profileId.equals(profileId))
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .watch();
  }

  Future<List<Asset>> getAll() {
    return (_db.select(_db.assets)..where((a) => a.profileId.equals(profileId))).get();
  }

  Future<void> add(AssetsCompanion asset) async {
    final now = DateTime.now();
    await _db.into(_db.assets).insert(
          asset.copyWith(
            id: Value(asset.id.present ? asset.id.value : _uuid.v4()),
            profileId: Value(profileId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> update(String id, AssetsCompanion changes) async {
    await (_db.update(_db.assets)..where((a) => a.id.equals(id)))
        .write(changes.copyWith(updatedAt: Value(DateTime.now())));
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.assets)..where((a) => a.id.equals(id))).go();
  }
}

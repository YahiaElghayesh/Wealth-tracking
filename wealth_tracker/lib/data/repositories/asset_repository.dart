import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

class AssetRepository {
  AssetRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Asset>> watchAll() {
    return (_db.select(_db.assets)
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .watch();
  }

  Future<List<Asset>> getAll() => _db.select(_db.assets).get();

  Future<void> add(AssetsCompanion asset) async {
    final now = DateTime.now();
    await _db.into(_db.assets).insert(
          asset.copyWith(
            id: Value(asset.id.present ? asset.id.value : _uuid.v4()),
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

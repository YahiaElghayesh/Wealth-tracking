import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// Scoped to one [profileId] -- see `AssetRepository`'s doc comment for the
/// pattern (every query filters to it, every insert stamps it, the provider
/// rebuilds on profile switch).
class LedgerCategoryRepository {
  LedgerCategoryRepository(this._db, this.profileId);

  final AppDatabase _db;
  final String profileId;
  static const _uuid = Uuid();

  Stream<List<LedgerCategory>> watchAll() {
    return (_db.select(_db.ledgerCategories)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<void> add(String name) async {
    final count = await (_db.select(_db.ledgerCategories)..where((t) => t.profileId.equals(profileId))).get();
    await _db.into(_db.ledgerCategories).insert(
          LedgerCategoriesCompanion.insert(
            id: _uuid.v4(),
            name: name,
            sortOrder: Value(count.length),
            profileId: Value(profileId),
          ),
        );
  }

  Future<void> rename(String id, String name) {
    return (_db.update(_db.ledgerCategories)..where((t) => t.id.equals(id)))
        .write(LedgerCategoriesCompanion(name: Value(name)));
  }

  Future<void> updateIcon(String id, String icon) {
    return (_db.update(_db.ledgerCategories)..where((t) => t.id.equals(id)))
        .write(LedgerCategoriesCompanion(icon: Value(icon)));
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.ledgerCategories)..where((t) => t.id.equals(id))).go();
  }
}

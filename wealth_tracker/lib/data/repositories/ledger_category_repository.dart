import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

class LedgerCategoryRepository {
  LedgerCategoryRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<LedgerCategory>> watchAll() {
    return (_db.select(_db.ledgerCategories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();
  }

  Future<void> add(String name) async {
    final count = await _db.select(_db.ledgerCategories).get();
    await _db.into(_db.ledgerCategories).insert(
          LedgerCategoriesCompanion.insert(id: _uuid.v4(), name: name, sortOrder: Value(count.length)),
        );
  }

  Future<void> rename(String id, String name) {
    return (_db.update(_db.ledgerCategories)..where((t) => t.id.equals(id)))
        .write(LedgerCategoriesCompanion(name: Value(name)));
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.ledgerCategories)..where((t) => t.id.equals(id))).go();
  }
}

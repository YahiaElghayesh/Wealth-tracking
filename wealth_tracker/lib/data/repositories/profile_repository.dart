import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// Manages the [Profiles] list itself -- unlike every other repository in
/// this app, this one is never scoped to a single active profile (it has to
/// see all of them, to switch between or delete one).
class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Profile>> watchAll() {
    return (_db.select(_db.profiles)..orderBy([(p) => OrderingTerm.asc(p.sortOrder)])).watch();
  }

  Future<List<Profile>> getAll() => _db.select(_db.profiles).get();

  Future<String> addProfile(String name) async {
    final count = await _db.select(_db.profiles).get();
    final id = _uuid.v4();
    await _db.into(_db.profiles).insert(
          ProfilesCompanion.insert(
            id: id,
            name: name,
            sortOrder: Value(count.length),
            createdAt: DateTime.now(),
          ),
        );
    // A brand-new profile needs the same starter ledger categories a fresh
    // install gets, or its add-transaction screen would start with zero
    // quick-pick chips.
    await _db.seedDefaultLedgerCategories(id);
    return id;
  }

  Future<void> renameProfile(String id, String name) {
    return (_db.update(_db.profiles)..where((p) => p.id.equals(id)))
        .write(ProfilesCompanion(name: Value(name)));
  }

  /// Deletes [id] and every row belonging to it across every user-data
  /// table -- foreign-key enforcement isn't turned on for this database (see
  /// the other repositories' own manual-cascade deletes, e.g.
  /// `LedgerRepository.deleteCounterparty`), so this cascades by hand
  /// instead, the same way.
  Future<void> deleteProfile(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.assets)..where((t) => t.profileId.equals(id))).go();
      await (_db.delete(_db.ledgerTransactions)..where((t) => t.profileId.equals(id))).go();
      await (_db.delete(_db.counterparties)..where((t) => t.profileId.equals(id))).go();
      await (_db.delete(_db.calculatorSnapshots)..where((t) => t.profileId.equals(id))).go();
      await (_db.delete(_db.creditCards)..where((t) => t.profileId.equals(id))).go();
      await (_db.delete(_db.manualInputs)..where((t) => t.profileId.equals(id))).go();
      await (_db.delete(_db.ledgerCategories)..where((t) => t.profileId.equals(id))).go();
      await (_db.delete(_db.vendorRules)..where((t) => t.profileId.equals(id))).go();
      await (_db.delete(_db.profiles)..where((p) => p.id.equals(id))).go();
    });
  }
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// Scoped to one [profileId] -- see `AssetRepository`'s doc comment for the
/// pattern (every query filters to it, every insert stamps it, the provider
/// rebuilds on profile switch).
class VendorRuleRepository {
  VendorRuleRepository(this._db, this.profileId);

  final AppDatabase _db;
  final String profileId;
  static const _uuid = Uuid();

  Stream<List<VendorRule>> watchAll() {
    return (_db.select(_db.vendorRules)..where((r) => r.profileId.equals(profileId))).watch();
  }

  Future<List<VendorRule>> loadAll() {
    return (_db.select(_db.vendorRules)..where((r) => r.profileId.equals(profileId))).get();
  }

  Future<void> addRule({
    required String vendorPattern,
    required String counterpartyId,
    required String category,
  }) {
    return _db.into(_db.vendorRules).insert(
          VendorRulesCompanion.insert(
            id: _uuid.v4(),
            vendorPattern: vendorPattern,
            counterpartyId: counterpartyId,
            category: category,
            profileId: Value(profileId),
          ),
        );
  }

  Future<void> updateRule(VendorRule rule) {
    return _db.update(_db.vendorRules).replace(rule);
  }

  Future<void> deleteRule(String id) {
    return (_db.delete(_db.vendorRules)..where((r) => r.id.equals(id))).go();
  }
}

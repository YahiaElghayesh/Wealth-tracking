import 'package:uuid/uuid.dart';

import '../db/database.dart';

class VendorRuleRepository {
  VendorRuleRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<VendorRule>> watchAll() {
    return _db.select(_db.vendorRules).watch();
  }

  Future<List<VendorRule>> loadAll() {
    return _db.select(_db.vendorRules).get();
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

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/sms_rule_segment.dart';
import '../db/database.dart';
import '../sms/sms_rule_engine.dart' show encodeSmsRuleSegments;

/// Scoped to one [profileId] -- see `AssetRepository`'s doc comment for the
/// pattern. Note that matching a rule against an incoming SMS itself
/// (`sms_ledger_processor.dart`) deliberately loads *every* profile's
/// rules, not just this one's -- mirroring the app's existing cross-profile
/// SMS balance-update behavior -- so this profile-scoped stream is only
/// for the SMS Rules settings screen's own list.
class SmsRuleRepository {
  SmsRuleRepository(this._db, this.profileId);

  final AppDatabase _db;
  final String profileId;
  static const _uuid = Uuid();

  Stream<List<SmsRule>> watchAll() {
    return (_db.select(_db.smsRules)
          ..where((r) => r.profileId.equals(profileId))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .watch();
  }

  Future<void> add({
    required String bankId,
    required String operation,
    required String sampleText,
    required List<SmsRuleSegment> segments,
    String? targetCounterpartyId,
    String? currency,
    required bool notifyOnMatch,
    String matchMode = 'strict',
    String? name,
    bool autoAddCharges = false,
    String? category,
  }) {
    return _db
        .into(_db.smsRules)
        .insert(
          SmsRulesCompanion.insert(
            id: _uuid.v4(),
            bankId: bankId,
            name: Value(name),
            operation: operation,
            sampleText: sampleText,
            segmentsJson: encodeSmsRuleSegments(segments),
            targetCounterpartyId: Value(targetCounterpartyId),
            currency: Value(currency),
            notifyOnMatch: Value(notifyOnMatch),
            matchMode: Value(matchMode),
            autoAddCharges: Value(autoAddCharges),
            category: Value(category),
            createdAt: DateTime.now(),
            profileId: Value(profileId),
          ),
        );
  }

  Future<void> updateRule(SmsRule rule) {
    return _db.update(_db.smsRules).replace(rule);
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.smsRules)..where((r) => r.id.equals(id))).go();
  }
}

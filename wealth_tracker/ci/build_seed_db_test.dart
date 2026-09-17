// Builds a ready-to-push sqlite file containing exactly one matching SMS
// Rule, so verify_quick_add.sh can fire a *real* Quick Add tap (a real
// JSON payload against a real charge SMS) and check that a ledger entry
// actually gets created -- not just that the broadcast reaches Dart.
//
// A previous version of this CI test used a fake, non-JSON payload
// ("test"), specifically to avoid needing a matching rule at all. That
// meant `jsonDecode` in app.dart's `_commitQuickAddFromBackground` always
// threw and returned early, so the entire rest of that function --
// opening a real AppDatabase(), reading SharedPreferences, loading
// SecureSettingsStore (a real flutter_secure_storage platform-channel
// call a plain `flutter test` never exercises either, since that runs
// with no real platform channels at all), resolving the active profile,
// and finally commitSmsQuickAdd's own ledger write -- was never actually
// exercised on a real device by that test. It passing proved the native
// broadcast plumbing works; it proved nothing about whether Quick Add's
// own effect (a ledger entry) ever happens for real.
//
// A `flutter test`, not a plain `dart run` script: package:wealth_tracker
// /data/db/database.dart transitively imports drift_flutter, which pulls
// in dart:ui -- unavailable outside Flutter's own test VM (confirmed by
// running this as a plain script first: it fails to even compile with
// "Dart library 'dart:ui' is not available on this platform"). Uses
// AppDatabase.forTesting (the same constructor the unit tests use)
// pointed at a real file instead of an in-memory one, so schema creation
// goes through the app's own real migration code, not hand-written SQL
// that could drift from the actual schema.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/core/models/sms_rule_segment.dart';
import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/sms/sms_rule_engine.dart'
    show encodeSmsRuleSegments;

/// The exact SMS this seeded rule matches. verify_quick_add.sh quotes this
/// same literal string in its own JSON payloads -- a shell script can't
/// import a Dart constant, so keep the two in sync by hand if this ever
/// changes.
const chargeSms =
    'Card #4912 charged EGP 958.54 at Breadfast. Available limit EGP 85891.16.';

List<SmsRuleSegment> _chargeSegments() => [
  const SmsRuleSegment.literal('Card #'),
  const SmsRuleSegment.placeholder(text: '4912', tag: 'cardNumber'),
  const SmsRuleSegment.literal(' charged EGP 958.54 at '),
  const SmsRuleSegment.placeholder(text: 'Breadfast', tag: 'vendor'),
  const SmsRuleSegment.literal('. Available limit EGP '),
  const SmsRuleSegment.placeholder(
    text: '85891.16',
    tag: 'value',
    role: 'set',
  ),
  const SmsRuleSegment.literal('.'),
];

/// A *different* charge, matched by a rule with no target counterparty and
/// no vendor mapping -- resolveLedgerTarget's own "ask which ledger" case.
/// This is the exact real-world scenario reported as broken (Quick Add
/// "does nothing" for a charge it can't resolve) that the seeded [chargeSms]
/// rule above can never exercise, since it always resolves to
/// ci-seed-counterparty. verify_quick_add.sh's own Part 3 fires Quick Add
/// against this SMS, then taps the notification it reposts, to prove the
/// whole "ask which ledger" round trip for real, not just that a
/// *resolvable* charge still works.
const unresolvableChargeSms =
    'Card #7777 charged EGP 120.00 at Uber. Available limit EGP 40000.00.';

List<SmsRuleSegment> _unresolvableChargeSegments() => [
  const SmsRuleSegment.literal('Card #'),
  const SmsRuleSegment.placeholder(text: '7777', tag: 'cardNumber'),
  const SmsRuleSegment.literal(' charged EGP 120.00 at '),
  const SmsRuleSegment.placeholder(text: 'Uber', tag: 'vendor'),
  const SmsRuleSegment.literal('. Available limit EGP '),
  const SmsRuleSegment.placeholder(
    text: '40000.00',
    tag: 'value',
    role: 'set',
  ),
  const SmsRuleSegment.literal('.'),
];

void main() {
  test('build seed database for verify_quick_add.sh', () async {
    final outputPath = Platform.environment['SEED_DB_OUTPUT'];
    if (outputPath == null) {
      fail('SEED_DB_OUTPUT env var must name where to write the sqlite file');
    }
    final file = File(outputPath);
    if (file.existsSync()) file.deleteSync();

    final db = AppDatabase.forTesting(NativeDatabase(file));

    const bankId = 'ci-seed-bank';
    const counterpartyId = 'ci-seed-counterparty';
    const ruleId = 'ci-seed-rule';

    // The first real query is what actually triggers onCreate (full
    // schema + the default profile + default categories) -- same as any
    // other use of AppDatabase.forTesting.
    await db
        .into(db.banks)
        .insert(
          BanksCompanion.insert(
            id: bankId,
            name: 'CI Test Bank',
            profileId: const Value(defaultProfileId),
          ),
        );
    await db
        .into(db.counterparties)
        .insert(
          CounterpartiesCompanion.insert(
            id: counterpartyId,
            name: 'CI Test Ledger',
            profileId: const Value(defaultProfileId),
          ),
        );
    await db
        .into(db.smsRules)
        .insert(
          SmsRulesCompanion.insert(
            id: ruleId,
            bankId: bankId,
            operation: 'ledgerPayment',
            sampleText: chargeSms,
            segmentsJson: encodeSmsRuleSegments(_chargeSegments()),
            targetCounterpartyId: const Value(counterpartyId),
            currency: const Value('EGP'),
            createdAt: DateTime(2026),
            profileId: const Value(defaultProfileId),
          ),
        );

    // No targetCounterpartyId, no vendorTargetsJson -- deliberately
    // unresolvable, see unresolvableChargeSms's own doc comment above.
    await db
        .into(db.smsRules)
        .insert(
          SmsRulesCompanion.insert(
            id: 'ci-seed-unresolvable-rule',
            bankId: bankId,
            operation: 'ledgerPayment',
            sampleText: unresolvableChargeSms,
            segmentsJson: encodeSmsRuleSegments(_unresolvableChargeSegments()),
            currency: const Value('EGP'),
            createdAt: DateTime(2026),
            profileId: const Value(defaultProfileId),
          ),
        );

    await db.close();
    // ignore: avoid_print
    print('Seed database written to ${file.path}');
  });
}

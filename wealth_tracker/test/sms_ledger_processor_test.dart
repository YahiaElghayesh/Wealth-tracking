import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:wealth_tracker/core/models/sms_rule_segment.dart';
import 'package:wealth_tracker/data/db/database.dart';
import 'package:wealth_tracker/data/sms/sms_ledger_processor.dart';
import 'package:wealth_tracker/data/sms/sms_rule_engine.dart';

/// A real platform implementation only ever exists on-device (registered by
/// flutter_local_notifications' own plugin registration, which never runs
/// in a plain `flutter test`) -- without something registered here,
/// [commitSmsAutoDetect]'s unconditional `showSmsChargeReviewNotification`
/// call for a reviewable charge would throw `LateInitializationError`
/// reading `FlutterLocalNotificationsPlatform.instance` before ever
/// reaching a real platform channel. Registering any concrete subclass is
/// enough to fix that: `resolvePlatformSpecificImplementation` type-checks
/// the registered instance against the platform-specific type it wants
/// (e.g. `AndroidFlutterLocalNotificationsPlugin`), finds this fake isn't
/// one, and returns null -- so `initialize`/`show` become harmless no-ops
/// without this class needing to override anything itself.
class _NoopNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

/// A charge shaped like the app's old hardwired CIB pattern -- card number,
/// value (stated post-charge available balance), vendor -- but matched
/// here by a *rule* built from a marked-up sample, not hardwired code.
const _chargeSms =
    'Card #4912 charged EGP 958.54 at Breadfast. Available limit EGP 85891.16.';

/// A card-payment (paying the card down, the opposite of a charge) shaped
/// like the app's old hardwired CIB Arabic payment pattern -- no stated
/// resulting balance, so the matching rule's role is "add" (net onto
/// whatever's already tracked) rather than "set".
const _paymentSms = 'Payment of EGP 8860.36 received on card #8455.';

/// A ledger repayment -- someone paying back what they owed, netting off
/// the tracked balance directly with no review needed (unlike a charge).
const _repaymentSms = 'We received your payment of EGP 250.00. Thank you.';

void main() {
  setUpAll(() {
    FlutterLocalNotificationsPlatform.instance = _NoopNotificationsPlatform();
    // showSmsChargeReviewNotification/showSmsRuleNotification now also
    // read the "silent notifications" preference off SharedPreferences
    // directly (see sms_rule_notifications.dart's own doc comment on
    // _notificationsSilent) -- SharedPreferences.getInstance() throws
    // without this, since nothing else in this suite touches it.
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<String> insertCounterparty(String name) async {
    final id = const Uuid().v4();
    await db
        .into(db.counterparties)
        .insert(
          CounterpartiesCompanion.insert(
            id: id,
            name: name,
            profileId: const Value('test-profile'),
          ),
        );
    return id;
  }

  Future<void> insertCard({
    required String lastFourDigits,
    double currentAvailableBalance = 0,
  }) {
    return db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            id: const Uuid().v4(),
            name: 'Test card',
            bank: 'Test bank',
            limitAmount: 100000,
            currency: const Value('EGP'),
            lastFourDigits: Value(lastFourDigits),
            currentAvailableBalance: Value(currentAvailableBalance),
            profileId: const Value('test-profile'),
          ),
        );
  }

  Future<String> insertBank() async {
    final id = const Uuid().v4();
    await db
        .into(db.banks)
        .insert(BanksCompanion.insert(id: id, name: 'Test bank'));
    return id;
  }

  /// A rule matching [_chargeSms]: card number, a "set" value (the stated
  /// post-charge available balance), and a vendor -- everything a real
  /// 'creditCardBalance' or 'ledgerPayment' rule built from this same
  /// sample would carry.
  List<SmsRuleSegment> chargeSegments() => [
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

  /// A rule matching [_paymentSms]: an "add" value (nets onto whatever
  /// balance is already tracked, since no resulting balance is stated) and
  /// a card number.
  List<SmsRuleSegment> paymentSegments() => [
    const SmsRuleSegment.literal('Payment of EGP '),
    const SmsRuleSegment.placeholder(
      text: '8860.36',
      tag: 'value',
      role: 'add',
    ),
    const SmsRuleSegment.literal(' received on card #'),
    const SmsRuleSegment.placeholder(text: '8455', tag: 'cardNumber'),
    const SmsRuleSegment.literal('.'),
  ];

  /// A rule matching [_repaymentSms]: a "repayment" value with nothing
  /// else tagged -- nets directly onto the tracked ledger balance, no
  /// vendor/category needed.
  List<SmsRuleSegment> repaymentSegments() => [
    const SmsRuleSegment.literal('We received your payment of EGP '),
    const SmsRuleSegment.placeholder(
      text: '250.00',
      tag: 'value',
      role: 'repayment',
    ),
    const SmsRuleSegment.literal('. Thank you.'),
  ];

  Future<void> insertLedgerPaymentRule(
    String bankId,
    String? counterpartyId, {
    List<SmsRuleSegment>? segments,
    String? sampleText,
    bool autoAddCharges = false,
    String? vendorTargetsJson,
  }) {
    return db
        .into(db.smsRules)
        .insert(
          SmsRulesCompanion.insert(
            id: const Uuid().v4(),
            bankId: bankId,
            operation: 'ledgerPayment',
            sampleText: sampleText ?? _chargeSms,
            segmentsJson: encodeSmsRuleSegments(segments ?? chargeSegments()),
            targetCounterpartyId: Value(counterpartyId),
            currency: const Value('EGP'),
            autoAddCharges: Value(autoAddCharges),
            vendorTargetsJson: Value(vendorTargetsJson),
            createdAt: DateTime(2026),
            profileId: const Value('test-profile'),
          ),
        );
  }

  Future<void> insertCreditCardBalanceRule(
    String bankId,
    List<SmsRuleSegment> segments,
    String sampleText,
  ) {
    return db
        .into(db.smsRules)
        .insert(
          SmsRulesCompanion.insert(
            id: const Uuid().v4(),
            bankId: bankId,
            operation: 'creditCardBalance',
            sampleText: sampleText,
            segmentsJson: encodeSmsRuleSegments(segments),
            createdAt: DateTime(2026),
            profileId: const Value('test-profile'),
          ),
        );
  }

  group('commitSmsQuickAdd', () {
    test('adds a ledger entry when a ledgerPayment rule matches', () async {
      final bankId = await insertBank();
      final counterpartyId = await insertCounterparty('Dad');
      await insertLedgerPaymentRule(bankId, counterpartyId);

      final added = await commitSmsQuickAdd(
        db,
        body: _chargeSms,
        timestampMillis: 1000,
        profileId: 'test-profile',
      );

      expect(added, isTrue);
      final rows = await db.select(db.ledgerTransactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.counterpartyId, counterpartyId);
      expect(rows.single.category, 'Breadfast');
      expect(rows.single.amount, closeTo(85891.16, 0.001));
      expect(rows.single.currency, 'EGP');
      expect(rows.single.source, 'sms');
    });

    test('does nothing when no SMS Rule matches', () async {
      final added = await commitSmsQuickAdd(
        db,
        body: _chargeSms,
        timestampMillis: 1000,
        profileId: 'test-profile',
      );

      expect(added, isFalse);
      expect(await db.select(db.ledgerTransactions).get(), isEmpty);
    });

    test(
      'a charge that matches but can\'t resolve a ledger posts a review '
      'notification instead of silently doing nothing',
      () async {
        final bankId = await insertBank();
        // No counterpartyId and no vendorTargetsJson -- exactly
        // resolveLedgerTarget's own "ask which ledger" case. Quick Add's
        // own notification action has already cancelled the tapped
        // notification by the time this runs (flutter_local_notifications'
        // own default), so there's nothing left for the user to act on
        // unless this posts a fresh one -- this only asserts that
        // commitSmsQuickAdd does so without throwing (a real platform
        // channel isn't available under `flutter test`; see
        // _NoopNotificationsPlatform's own doc comment) and, just as
        // importantly, doesn't add anything or mark the SMS processed --
        // it's still fully reviewable from that fresh notification.
        await insertLedgerPaymentRule(bankId, null);

        final added = await commitSmsQuickAdd(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(added, isFalse);
        expect(await db.select(db.ledgerTransactions).get(), isEmpty);

        // Not marked processed -- a later tap (Quick Add again, or the
        // fresh review notification this should have posted) still has
        // something to do.
        final againAdded = await commitSmsQuickAdd(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );
        expect(againAdded, isFalse);
      },
    );

    test('does nothing for unrelated text', () async {
      final bankId = await insertBank();
      final counterpartyId = await insertCounterparty('Dad');
      await insertLedgerPaymentRule(bankId, counterpartyId);

      final added = await commitSmsQuickAdd(
        db,
        body: 'Your OTP is 123456.',
        timestampMillis: 1000,
        profileId: 'test-profile',
      );

      expect(added, isFalse);
      expect(await db.select(db.ledgerTransactions).get(), isEmpty);
    });

    test(
      'the same SMS is only ever committed once, even across repeated calls',
      () async {
        final bankId = await insertBank();
        final counterpartyId = await insertCounterparty('Dad');
        await insertLedgerPaymentRule(bankId, counterpartyId);

        final first = await commitSmsQuickAdd(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );
        final second = await commitSmsQuickAdd(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(first, isTrue);
        expect(second, isFalse);
        expect(await db.select(db.ledgerTransactions).get(), hasLength(1));
      },
    );

    test(
      'a card-payment SMS updates the balance but is never added as a ledger entry',
      () async {
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(
          bankId,
          paymentSegments(),
          _paymentSms,
        );
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );

        final added = await commitSmsQuickAdd(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(added, isFalse);
        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(50000 + 8860.36, 0.001));
      },
    );
  });

  group('commitSmsAutoDetect', () {
    test(
      'a card-payment SMS updates the balance with no ledger entry',
      () async {
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(
          bankId,
          paymentSegments(),
          _paymentSms,
        );
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );

        await commitSmsAutoDetect(db, body: _paymentSms, timestampMillis: 1000);

        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(50000 + 8860.36, 0.001));
      },
    );

    test('does nothing for text that matches no rule', () async {
      await commitSmsAutoDetect(
        db,
        body: 'Your OTP is 123456.',
        timestampMillis: 1000,
      );

      expect(await db.select(db.creditCards).get(), isEmpty);
      expect(await db.select(db.ledgerTransactions).get(), isEmpty);
    });

    test(
      'the same SMS is only ever applied once, even across repeated calls',
      () async {
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(
          bankId,
          paymentSegments(),
          _paymentSms,
        );
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );

        await commitSmsAutoDetect(db, body: _paymentSms, timestampMillis: 1000);
        await commitSmsAutoDetect(db, body: _paymentSms, timestampMillis: 1000);

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(50000 + 8860.36, 0.001));
      },
    );

    test(
      'a charge-shaped balance rule updates the balance directly, same as any other balance match',
      () async {
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(bankId, chargeSegments(), _chargeSms);
        await insertCard(
          lastFourDigits: '4912',
          currentAvailableBalance: 50000,
        );

        await commitSmsAutoDetect(db, body: _chargeSms, timestampMillis: 1000);

        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(85891.16, 0.001));
      },
    );

    test(
      'a matched ledgerPayment charge is left pending for review, not added directly',
      () async {
        final bankId = await insertBank();
        final counterpartyId = await insertCounterparty('Dad');
        await insertLedgerPaymentRule(bankId, counterpartyId);

        await commitSmsAutoDetect(db, body: _chargeSms, timestampMillis: 1000);

        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
      },
    );

    test(
      'a charge from a rule with autoAddCharges on is added straight to the '
      'ledger, no review notification or pending state at all',
      () async {
        final bankId = await insertBank();
        final counterpartyId = await insertCounterparty('Dad');
        await insertLedgerPaymentRule(
          bankId,
          counterpartyId,
          autoAddCharges: true,
        );

        await commitSmsAutoDetect(db, body: _chargeSms, timestampMillis: 1000);

        expect(await db.select(db.ledgerTransactions).get(), hasLength(1));
        // Fully settled already -- a later Quick add for the same SMS finds
        // nothing left to do, exactly like a repayment.
        final addedAgain = await commitSmsQuickAdd(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );
        expect(addedAgain, isFalse);
        expect(await db.select(db.ledgerTransactions).get(), hasLength(1));
      },
    );

    test(
      'a charge from a rule with autoAddCharges on and a vendor mapping is '
      "added to that vendor's own ledger, not the rule's fallback",
      () async {
        final bankId = await insertBank();
        final fallbackId = await insertCounterparty('Fallback');
        final breadfastId = await insertCounterparty('Breadfast ledger');
        await insertLedgerPaymentRule(
          bankId,
          fallbackId,
          autoAddCharges: true,
          vendorTargetsJson: encodeVendorTargets([
            VendorLedgerTarget(vendor: 'Breadfast', counterpartyId: breadfastId),
          ]),
        );

        await commitSmsAutoDetect(db, body: _chargeSms, timestampMillis: 1000);

        final entry = await db.select(db.ledgerTransactions).getSingle();
        expect(entry.counterpartyId, breadfastId);
      },
    );

    test(
      'a charge with autoAddCharges on but no vendor mapping and no '
      "fallback ledger is left reviewable instead of silently dropped",
      () async {
        final bankId = await insertBank();
        await insertLedgerPaymentRule(bankId, null, autoAddCharges: true);

        await commitSmsAutoDetect(db, body: _chargeSms, timestampMillis: 1000);

        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
        // Still reviewable -- a later Quick add can't resolve a ledger
        // either (there's still nothing to auto-apply to), but confirming
        // the SMS was left pending, not marked fully settled, is the
        // actual behavior under test here: only SmsReviewScreen (asking
        // the user which ledger) can actually finish this one.
        final addedAgain = await commitSmsQuickAdd(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );
        expect(addedAgain, isFalse);
        expect(await db.select(db.ledgerTransactions).get(), isEmpty);
      },
    );

    test(
      'a charge left pending by commitSmsAutoDetect can still be committed afterward via commitSmsQuickAdd',
      () async {
        final bankId = await insertBank();
        final counterpartyId = await insertCounterparty('Dad');
        await insertLedgerPaymentRule(bankId, counterpartyId);

        await commitSmsAutoDetect(db, body: _chargeSms, timestampMillis: 1000);
        final added = await commitSmsQuickAdd(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(added, isTrue);
        expect(await db.select(db.ledgerTransactions).get(), hasLength(1));
      },
    );

    test('a repayment match applies directly, with no review needed', () async {
      final bankId = await insertBank();
      final counterpartyId = await insertCounterparty('Dad');
      await insertLedgerPaymentRule(
        bankId,
        counterpartyId,
        segments: repaymentSegments(),
        sampleText: _repaymentSms,
      );

      await commitSmsAutoDetect(db, body: _repaymentSms, timestampMillis: 1000);

      final rows = await db.select(db.ledgerTransactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.amount, closeTo(-250.00, 0.001));
    });

    test('a disabled rule is skipped entirely', () async {
      final bankId = await insertBank();
      await insertCreditCardBalanceRule(bankId, paymentSegments(), _paymentSms);
      final rule = await db.select(db.smsRules).getSingle();
      await db.update(db.smsRules).replace(rule.copyWith(enabled: false));
      await insertCard(lastFourDigits: '8455', currentAvailableBalance: 50000);

      await commitSmsAutoDetect(db, body: _paymentSms, timestampMillis: 1000);

      final card = await db.select(db.creditCards).getSingle();
      expect(card.currentAvailableBalance, 50000);
    });

    test(
      'a balance already applied by commitSmsAutoDetect is not double-applied when '
      'commitSmsQuickAdd later runs for the same SMS',
      () async {
        final bankId = await insertBank();
        await insertCreditCardBalanceRule(
          bankId,
          paymentSegments(),
          _paymentSms,
        );
        await insertCard(
          lastFourDigits: '8455',
          currentAvailableBalance: 50000,
        );

        await commitSmsAutoDetect(db, body: _paymentSms, timestampMillis: 1000);
        await commitSmsQuickAdd(
          db,
          body: _paymentSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        final card = await db.select(db.creditCards).getSingle();
        expect(card.currentAvailableBalance, closeTo(50000 + 8860.36, 0.001));
      },
    );
  });

  group('processIncomingSms', () {
    // No MaterialApp/Navigator is ever pumped in this test file, so
    // navigatorKey.currentState is always null here -- exactly the "cold
    // start, first frame isn't up yet" case processIncomingSms itself has
    // to survive. This used to mark the SMS "processed" regardless and
    // give up silently (the real bug behind "the notification opens the
    // app but never shows a ledger picker"): a charge that could never be
    // shown was nonetheless burned, with nothing left to retry it. This
    // test runs the real, un-shortened `_awaitNavigator` wait, so it's
    // slow (a few seconds) by design -- it's proving the timing behavior
    // itself, not just the outcome.
    test(
      'a reviewable charge is still committable via commitSmsQuickAdd '
      'afterward when no Navigator was available to show it',
      () async {
        final bankId = await insertBank();
        final counterpartyId = await insertCounterparty('Dad');
        await insertLedgerPaymentRule(bankId, counterpartyId);

        await processIncomingSms(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        // If processIncomingSms had wrongly marked this dedupeId processed
        // despite never actually showing a review screen for it (the bug),
        // this would return false and add nothing -- the charge would be
        // gone for good with no way to recover it, matching exactly what
        // was reported from real use.
        final added = await commitSmsQuickAdd(
          db,
          body: _chargeSms,
          timestampMillis: 1000,
          profileId: 'test-profile',
        );

        expect(added, isTrue);
        final transactions = await db.select(db.ledgerTransactions).get();
        expect(transactions, hasLength(1));
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}

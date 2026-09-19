import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/settings_repository.dart';

const _channelId = 'sms_rules';
const _silentChannelId = 'sms_rules_silent';
const _channelName = 'SMS Rules';
const _silentChannelName = 'SMS Rules (silent)';
const _channelDescription =
    'Shown when an SMS Rule updates a card/account balance or adds a '
    'ledger entry from a bank text';

const _reviewChannelId = 'sms_charge_review';
const _silentReviewChannelId = 'sms_charge_review_silent';
const _reviewChannelName = 'Charge review';
const _silentReviewChannelName = 'Charge review (silent)';
const _reviewChannelDescription =
    'Shown when a bank text looks like a charge that needs your review '
    'before it becomes a ledger entry';

/// Both notification functions below call this rather than taking a
/// `silent` parameter -- they're called from headless WorkManager
/// isolates with no [SettingsRepository] instance already built, so
/// reading the one preference key they need directly off
/// [SharedPreferences] avoids constructing one just for this.
Future<bool> _notificationsSilent() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(SettingsRepository.smsNotificationsSilentKey) ?? false;
}

/// Shows a local notification for an [SmsRule] that just fired (see
/// `sms_rule_engine.dart`'s `SmsRuleApplyOutcome`) -- only ever called when
/// that rule's own `notifyOnMatch` is on. Re-initializes the plugin on
/// every call rather than once at app start: this also runs from the
/// WorkManager background isolates `sms_ledger_processor.dart`'s headless
/// entry points execute in, which are a fresh Dart VM each time with no
/// earlier initialization to rely on. Cheap and idempotent either way.
Future<void> showSmsRuleNotification({
  required String title,
  required String body,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(android: androidSettings),
  );
  final silent = await _notificationsSilent();
  // A unique id per call -- rather than one fixed id, which silently
  // replaced an still-unread "balance updated" notification the moment
  // another one arrived. Two balance updates in quick succession (a
  // charge and its refund a minute apart, one from each of two cards)
  // now both stay visible instead of one erasing the other.
  final id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  await plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        silent ? _silentChannelId : _channelId,
        silent ? _silentChannelName : _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: !silent,
        enableVibration: !silent,
        // Its own group of one, not left ungrouped -- Android auto-bundles
        // several ungrouped notifications from the same app into a single
        // collapsed "N notifications" stack (most visible on the lock
        // screen, which is what got reported), but only for notifications
        // that don't already belong to *some* group. Giving each one a
        // group key unique to itself opts it out of that without actually
        // grouping it with anything.
        groupKey: 'sms_rule_$id',
      ),
    ),
  );
}

/// The JSON shape [showSmsChargeReviewNotification] encodes as its
/// payload, and app.dart's notification-response handling decodes -- just
/// enough for `commitSmsQuickAdd`/`processIncomingSms` to re-run their own
/// (already tested) matching against the same raw SMS, rather than trying
/// to thread the already-computed match through the notification itself.
/// [quickAddFailed] tells that handling which of the two to re-run: see
/// [showSmsChargeReviewNotification]'s own doc comment.
Map<String, dynamic> smsChargeReviewPayload({
  required String body,
  required int timestampMillis,
  bool quickAddFailed = false,
}) {
  return {
    'body': body,
    'timestampMillis': timestampMillis,
    if (quickAddFailed) 'quickAddFailed': true,
  };
}

/// Shows the notification for a matched 'ledgerPayment' rule tagged as a
/// charge -- the case that needs the user's review before it becomes a
/// ledger entry, posted by `commitSmsAutoDetect` (`sms_ledger_processor
/// .dart`) since that headless isolate has no Navigator to push
/// `SmsReviewScreen` onto directly. Carries a JSON payload (see
/// [smsChargeReviewPayload]) so tapping it -- handled in app.dart via
/// flutter_local_notifications' own response callbacks and the native
/// fallback in MainActivity.kt/native_sms_channel.dart -- can re-run the
/// real matching logic against the original SMS.
///
/// A single tap on the body is the *only* interaction this notification
/// offers -- there used to also be a separate "Quick add" action button,
/// removed after a real, reported device-specific failure mode: Android's
/// heads-up (pop-up) presentation of a notification doesn't reliably
/// register a tap on an action button until the notification has settled
/// into the shade a moment later (a tap on the button during the pop-up
/// itself was silently swallowed, working only on a second tap once it had
/// already dropped into the notification pane) -- a body tap, launching
/// the app the same ordinary way any notification does, doesn't have that
/// same failure mode. [quickAddFailed] is what the removed button used to
/// signal implicitly through its own presence/absence: false (the normal,
/// first-ever notification for this charge) means a tap should attempt
/// `commitSmsQuickAdd` first, same as the old button did; true (this
/// exact notification is itself a repost, from `commitSmsQuickAdd` having
/// already tried and failed to resolve a ledger for this SMS) means a tap
/// should go straight to `processIncomingSms` instead, opening the review
/// screen's ledger picker rather than repeating the same failing attempt.
///
/// Notification id is derived from [timestampMillis] (not fixed, unlike
/// [showSmsRuleNotification]) so multiple pending charges each get their
/// own notification instead of one overwriting another -- matching how
/// the old native-posted notification worked.
Future<void> showSmsChargeReviewNotification({
  required String body,
  required int timestampMillis,
  required String vendor,
  String? amountText,
  String? targetName,
  bool quickAddFailed = false,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(android: androidSettings),
  );
  final silent = await _notificationsSilent();
  final addedTo = amountText == null
      ? null
      : (targetName == null
            ? '$amountText will be added'
            : '$amountText will be added to $targetName');
  final notificationBody = quickAddFailed
      ? '${addedTo ?? 'A charge was detected'}. Tap to pick a ledger.'
      : (addedTo == null ? 'Tap to add.' : '$addedTo. Tap to add.');
  final id = timestampMillis & 0x7fffffff; // masked to a positive 32-bit id
  await plugin.show(
    id: id,
    title: 'Charge detected: $vendor',
    body: notificationBody,
    payload: jsonEncode(
      smsChargeReviewPayload(
        body: body,
        timestampMillis: timestampMillis,
        quickAddFailed: quickAddFailed,
      ),
    ),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        silent ? _silentReviewChannelId : _reviewChannelId,
        silent ? _silentReviewChannelName : _reviewChannelName,
        channelDescription: _reviewChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: !silent,
        enableVibration: !silent,
        // See showSmsRuleNotification's own comment on groupKey -- same
        // "its own group of one" fix for the same lock-screen stacking
        // report, applied here too since this is the other notification
        // kind this app posts.
        groupKey: 'sms_review_$id',
      ),
    ),
  );
}

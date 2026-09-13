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

/// Action id [showSmsChargeReviewNotification] attaches to its "Quick add"
/// button -- app.dart's notification-response handling (both the
/// foreground callback and the background one) checks for this to decide
/// whether a tap means "commit headlessly" rather than "open the review
/// screen".
const smsChargeReviewQuickAddActionId = 'quick_add';

/// The JSON shape [showSmsChargeReviewNotification] encodes as its
/// payload, and app.dart's notification-response handling decodes -- just
/// enough for `commitSmsQuickAdd`/`processIncomingSms` to re-run their own
/// (already tested) matching against the same raw SMS, rather than trying
/// to thread the already-computed match through the notification itself.
Map<String, dynamic> smsChargeReviewPayload({
  required String body,
  required int timestampMillis,
}) {
  return {'body': body, 'timestampMillis': timestampMillis};
}

/// Shows the notification for a matched 'ledgerPayment' rule tagged as a
/// charge -- the case that needs the user's review before it becomes a
/// ledger entry, posted by `commitSmsAutoDetect` (`sms_ledger_processor
/// .dart`) since that headless isolate has no Navigator to push
/// `SmsReviewScreen` onto directly. Carries a JSON payload (see
/// [smsChargeReviewPayload]) so tapping it -- handled in app.dart via
/// flutter_local_notifications' own response callbacks, both foreground
/// and background -- can re-run the real matching logic against the
/// original SMS: tapping the notification body itself re-invokes
/// `processIncomingSms` to open the review screen for real, while the
/// "Quick add" action ([smsChargeReviewQuickAddActionId],
/// `showsUserInterface: false` so it never brings up the UI at all)
/// re-invokes `commitSmsQuickAdd` headlessly.
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
  final notificationBody = addedTo == null
      ? 'Tap to review, or Quick add to log it as-is.'
      : '$addedTo. Tap to review, or Quick add to log it as-is.';
  final id = timestampMillis & 0x7fffffff; // masked to a positive 32-bit id
  await plugin.show(
    id: id,
    title: 'Charge detected: $vendor',
    body: notificationBody,
    payload: jsonEncode(
      smsChargeReviewPayload(body: body, timestampMillis: timestampMillis),
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
        actions: const [
          AndroidNotificationAction(
            smsChargeReviewQuickAddActionId,
            'Quick add',
          ),
        ],
      ),
    ),
  );
}

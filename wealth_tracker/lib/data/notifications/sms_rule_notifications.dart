import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _channelId = 'sms_rules';
const _channelName = 'SMS Rules';
const _channelDescription =
    'Shown when an SMS Rule updates a card/account balance or adds a '
    'ledger entry from a bank text';

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
  await plugin.show(
    // A fixed id -- one SMS rule notification replacing the last one it
    // hasn't been dismissed yet is preferable to a growing pile of stale
    // "balance updated" notifications from earlier in the day.
    id: 9001,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
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
}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(android: androidSettings),
  );
  await plugin.show(
    id: timestampMillis & 0x7fffffff, // masked to a positive 32-bit id
    title: 'Charge detected: $vendor',
    body: 'Tap to review, or Quick add to log it as-is.',
    payload: jsonEncode(
      smsChargeReviewPayload(body: body, timestampMillis: timestampMillis),
    ),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
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

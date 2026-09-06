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

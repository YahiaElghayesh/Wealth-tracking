import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Everything the "Add"/"Ignore" actions and the review-screen tap need to
/// know about one detected bank charge — round-tripped as the
/// notification's JSON payload so each isolate that might handle a tap
/// (main, or the separate background isolates for SMS/notification
/// actions) can act on it without re-deriving anything.
class BankChargePayload {
  const BankChargePayload({
    required this.vendor,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.dedupeId,
    this.counterpartyId,
    this.category,
  });

  final String vendor;
  final double amount;
  final String currency;
  final DateTime occurredAt;
  final String dedupeId;

  /// Non-null only when a vendor rule matched — the notification's "Add"
  /// quick action uses these directly rather than re-matching.
  final String? counterpartyId;
  final String? category;

  int get notificationId => dedupeId.hashCode & 0x7fffffff;

  String encode() => jsonEncode({
        'vendor': vendor,
        'amount': amount,
        'currency': currency,
        'occurredAtMillis': occurredAt.millisecondsSinceEpoch,
        'dedupeId': dedupeId,
        'counterpartyId': counterpartyId,
        'category': category,
      });

  static BankChargePayload decode(String payload) {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return BankChargePayload(
      vendor: json['vendor'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(json['occurredAtMillis'] as int),
      dedupeId: json['dedupeId'] as String,
      counterpartyId: json['counterpartyId'] as String?,
      category: json['category'] as String?,
    );
  }
}

const _channelId = 'bank_charges';
const _channelName = 'Bank charges';
const _channelDescription = 'A detected bank card charge you can add to a ledger';

const _addAction = 'add';
const _ignoreAction = 'ignore';

/// Minimal per-isolate setup needed before this isolate can call `.show()`
/// or `.cancel()` — every isolate that might touch the plugin (the SMS
/// background isolate, the notification-action background isolate) is a
/// fresh Dart isolate with its own uninitialized plugin instance, so each
/// needs this exactly once. Doesn't register response callbacks — only the
/// main isolate does that, in `_RootShellState._initNotifications` (it
/// needs a `WidgetRef` to navigate, which these headless isolates don't
/// have).
Future<FlutterLocalNotificationsPlugin> initNotificationsForIsolate() async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  return plugin;
}

/// Shows the "add this to a ledger?" notification for one detected charge.
/// When [payload.counterpartyId] is set (a vendor rule matched), the
/// notification offers one-tap "Add"/"Ignore" actions that resolve without
/// opening the app; otherwise there's no clean single default, so only
/// "Ignore" is offered and the notification body itself must be tapped to
/// open the review screen.
Future<void> showBankChargeNotification(
  FlutterLocalNotificationsPlugin plugin,
  BankChargePayload payload,
) async {
  final matched = payload.counterpartyId != null;
  final title = matched ? 'Add to ledger?' : 'Bank charge detected';
  final body = matched
      ? '${payload.vendor} charged ${_formatAmount(payload)} — add as ${payload.category}?'
      : '${payload.vendor} charged ${_formatAmount(payload)} — tap to add to a ledger.';

  final actions = <AndroidNotificationAction>[
    if (matched)
      const AndroidNotificationAction(_addAction, 'Add', showsUserInterface: false, cancelNotification: true),
    const AndroidNotificationAction(_ignoreAction, 'Ignore', showsUserInterface: false, cancelNotification: true),
  ];

  await plugin.show(
    id: payload.notificationId,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        actions: actions,
      ),
    ),
    payload: payload.encode(),
  );
}

String _formatAmount(BankChargePayload payload) {
  final whole = payload.amount.round();
  return '$whole ${payload.currency}';
}

bool isAddAction(String? actionId) => actionId == _addAction;

bool isIgnoreAction(String? actionId) => actionId == _ignoreAction;

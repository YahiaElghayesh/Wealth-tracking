import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/sms/bank_charge_notifications.dart';
import '../screens/sms_review_screen.dart';

/// Opens the SMS review screen for a tapped bank-charge notification —
/// either a warm-app tap (delivered directly to this callback) or a
/// cold-start tap (checked once via `getNotificationAppLaunchDetails` after
/// the first frame). The "Add"/"Ignore" quick actions never reach here —
/// both are `showsUserInterface: false`, so Android resolves them in
/// `bankChargeNotificationBackgroundHandler` without launching the app;
/// `actionId` is only non-null here in some unexpected edge case, so it's
/// still guarded against rather than assumed impossible.
Future<void> handleNotificationResponse(NotificationResponse? response, WidgetRef ref) async {
  if (response == null || response.actionId != null) return;
  final payloadJson = response.payload;
  if (payloadJson == null) return;

  final navigator = await _awaitNavigator();
  if (navigator == null) return;

  final payload = BankChargePayload.decode(payloadJson);
  navigator.push(MaterialPageRoute(builder: (_) => SmsReviewScreen(payload: payload)));
}

/// [navigatorKey]'s Navigator is usually already mounted by the time this
/// runs (callers wait for the first frame), but polls briefly rather than
/// giving up immediately, as a safety net against rarer timing races.
Future<NavigatorState?> _awaitNavigator() async {
  for (var attempt = 0; attempt < 10; attempt++) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) return navigator;
    await Future.delayed(const Duration(milliseconds: 100));
  }
  return null;
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../db/database.dart';
import 'bank_charge_notifications.dart';
import 'sms_ledger_processor.dart';

/// Handles a tap on the notification's "Add" or "Ignore" action — both are
/// `showsUserInterface: false`, so Android runs this in its own background
/// isolate without launching the app (a plain tap on the notification body
/// instead, launching the app, goes through `handleNotificationResponse`).
/// A fresh isolate means a fresh, uninitialized plugin instance and no DB
/// connection, so both are set up here, matching the same pattern used for
/// the other headless entry points in this app (background price refresh,
/// the SMS listener's background handler).
@pragma('vm:entry-point')
void bankChargeNotificationBackgroundHandler(NotificationResponse response) async {
  final plugin = await initNotificationsForIsolate();
  final payloadJson = response.payload;
  final payload = payloadJson == null ? null : BankChargePayload.decode(payloadJson);

  if (isAddAction(response.actionId) && payload?.counterpartyId != null && payload?.category != null) {
    final db = AppDatabase();
    try {
      await recordBankCharge(
        db,
        counterpartyId: payload!.counterpartyId!,
        category: payload.category!,
        amount: payload.amount,
        currency: payload.currency,
        occurredAt: payload.occurredAt,
      );
    } finally {
      await db.close();
    }
  }

  await plugin.cancel(id: response.id ?? payload?.notificationId ?? 0);
}

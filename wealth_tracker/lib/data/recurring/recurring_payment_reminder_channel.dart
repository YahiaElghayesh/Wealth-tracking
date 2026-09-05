import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges to the native `money_hub/recurring_reminders` channel (see
/// MainActivity.kt / RecurringPaymentReminder.kt) -- Android-only, since
/// there's no equivalent always-on background execution model on Windows
/// (same reason background_refresh.dart's periodic price refresh is
/// Android-only). Every call is fire-and-forget and swallows failures: a
/// missed schedule/cancel here just means a reminder fires slightly
/// late/early or not at all for one cycle, never a crash.
class RecurringPaymentReminderChannel {
  RecurringPaymentReminderChannel._();

  static const _channel = MethodChannel('money_hub/recurring_reminders');

  /// Schedules (or reschedules, replacing any existing one) the repeating
  /// reminder for [paymentId], first firing at [dueAt] (midnight on the
  /// payment's current due date) and then, entirely natively with no
  /// Flutter engine involved, every 4 hours after that until the
  /// notification's own "Done" action -- or [cancel], from the in-app paid
  /// toggle -- stops it.
  static Future<void> schedule({
    required String paymentId,
    required String name,
    required String amountLabel,
    required DateTime dueAt,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('scheduleReminder', {
        'id': paymentId,
        'name': name,
        'amount': amountLabel,
        'dueAtMillis': dueAt.millisecondsSinceEpoch,
      });
    } catch (_) {
      // Best-effort -- see class doc comment.
    }
  }

  /// Stops [paymentId]'s repeating reminder and dismisses its notification
  /// if one is currently showing -- called once it's paid (whichever path
  /// actually paid it) or once it stops being a 'manual' payment.
  static Future<void> cancel(String paymentId) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('cancelReminder', {'id': paymentId});
    } catch (_) {
      // Best-effort -- see class doc comment.
    }
  }
}

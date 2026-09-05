import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A redundant, independent record of every RecurringPayment's
/// [RecurringPayment.paymentMode] (from `lib/data/db/tables.dart`) -- kept
/// in SharedPreferences, a completely separate storage file from the
/// sqlite database that column actually lives in -- written every time the
/// user explicitly sets it via AddRecurringPaymentScreen, and consulted
/// once per app session (see `recurringPaymentModeReconcileProvider` in
/// recurring_payment_providers.dart) to repair the database if the two
/// ever disagree.
///
/// Exists because a payment's mode has been reported reverting from
/// 'manual' to 'auto' on its own -- once right after an app update, and
/// separately just from closing and reopening the app -- with no
/// reproducible cause found after auditing every write path this app has
/// to that column: `setPaid`, the reminder notification's "Done" action,
/// and the history/reminder-sync side-effect providers all perform
/// narrow, single-field writes that never touch `paymentMode`; only
/// AddRecurringPaymentScreen's own save ever sets it, and does so
/// correctly. Since the actual mechanism couldn't be pinpointed (and may
/// be something outside this app's own code entirely -- a process
/// killed mid-write, a plugin quirk, ...), this is a second, independent
/// copy of the same value with its own self-healing reconciliation on
/// every open, rather than a fix aimed at one specific hypothesized cause.
class RecurringPaymentModeBackup {
  RecurringPaymentModeBackup._();

  static const _prefsKey = 'recurring_payment_modes_backup';

  static Future<void> record(String paymentId, String paymentMode) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _read(prefs);
    map[paymentId] = paymentMode;
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  static Future<void> forget(String paymentId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _read(prefs);
    if (map.remove(paymentId) != null) {
      await prefs.setString(_prefsKey, jsonEncode(map));
    }
  }

  static Future<Map<String, String>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs);
  }

  /// Drops every backed-up id no longer present in [liveIds] -- keeps this
  /// from growing forever as payments get deleted.
  static Future<void> pruneToLiveIds(Set<String> liveIds) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _read(prefs);
    final staleIds = map.keys.where((id) => !liveIds.contains(id)).toList();
    if (staleIds.isEmpty) return;
    for (final id in staleIds) {
      map.remove(id);
    }
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  static Map<String, String> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((k, v) => MapEntry(k as String, v as String));
    } catch (_) {
      return {};
    }
  }
}

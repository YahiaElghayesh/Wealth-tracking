import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A redundant, independent record of every ManualInput's
/// [ManualInput.currentValue] (from `lib/data/db/tables.dart`) -- kept in
/// SharedPreferences, a completely separate storage file from the sqlite
/// database that column actually lives in -- written every time
/// CalculatorScreen's debounced save-back persists an edit, and consulted
/// on every app open (see CalculatorScreen's `_reconcileManualInputValues`)
/// to repair the database if the two ever disagree.
///
/// A manual input's typed value has been repeatedly reported reverting to
/// an old (or blank) number on its own -- once right after an app update,
/// and separately just from closing and reopening the app -- both before
/// and after `currentValue` itself was added specifically to fix this
/// class of bug. Rather than assume that one persisted column is
/// sufficient this time either, this is a second, independent copy of the
/// same value with its own self-healing reconciliation on every open.
class ManualInputValueBackup {
  ManualInputValueBackup._();

  static const _prefsKey = 'manual_input_values_backup';

  static Future<void> record(String inputId, double value) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _read(prefs);
    map[inputId] = value;
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  static Future<void> forget(String inputId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _read(prefs);
    if (map.remove(inputId) != null) {
      await prefs.setString(_prefsKey, jsonEncode(map));
    }
  }

  static Future<Map<String, double>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs);
  }

  /// Drops every backed-up id no longer present in [liveIds] -- keeps this
  /// from growing forever as manual inputs get deleted.
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

  static Map<String, double> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      );
    } catch (_) {
      return {};
    }
  }
}

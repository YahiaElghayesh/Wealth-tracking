import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captures every `debugPrint` call this app already makes (the SMS/Quick
/// Add breadcrumbs added throughout `sms_ledger_processor.dart`/`app.dart`/
/// `background_refresh.dart`, plus anything else) into a small persisted
/// log a user can view and copy straight from Settings -- no `adb logcat`,
/// no computer, no USB debugging. Exists because every attempt to diagnose
/// a real-device-only Quick Add/notification-tap failure so far has hit the
/// same wall: CI can prove the code correct on a real (if emulated) Android
/// system, but there is no way to see what actually happened on a specific
/// user's own phone without this.
///
/// Backed by [SharedPreferences] rather than an in-memory list because the
/// breadcrumbs this needs to capture run across genuinely separate Dart
/// isolates/engines that share no memory with each other or with the main
/// app: the foreground isolate ([install] is called from `main()`) and the
/// WorkManager headless isolate (`priceRefreshCallbackDispatcher`,
/// background_refresh.dart) -- a plain static list would only ever capture
/// whichever one of those happened to install it.
class AppDebugLog {
  AppDebugLog._();

  static const _key = 'app_debug_log_entries_v1';
  static const _cap = 400;

  /// Wraps the existing top-level [debugPrint] so every call site that
  /// already logs a breadcrumb (no code changes needed there) also gets
  /// captured here -- installed once per isolate, from as early as
  /// possible in that isolate's entry point. Chains to whatever
  /// [debugPrint] implementation was already installed (normally
  /// [debugPrintThrottled]) rather than replacing it, so nothing already
  /// relying on the normal console output loses it.
  static void install() {
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      previous(message, wrapWidth: wrapWidth);
      if (message != null) unawaited(_append(message));
    };
  }

  static Future<void> _append(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = _read(prefs);
      entries.add('${DateTime.now().toIso8601String()}  $message');
      while (entries.length > _cap) {
        entries.removeAt(0);
      }
      await prefs.setString(_key, jsonEncode(entries));
    } catch (_) {
      // A logging helper must never itself be a new source of crashes --
      // especially not from inside a headless isolate with no UI to
      // surface one.
    }
  }

  static List<String> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.cast<String>() : [];
    } catch (_) {
      return [];
    }
  }

  /// Newest first, for display.
  static Future<List<String>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs).reversed.toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

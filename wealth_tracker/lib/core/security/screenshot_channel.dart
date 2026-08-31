import 'dart:io';

import 'package:flutter/services.dart';

/// Native counterpart lives in `MainActivity.kt`. `onCreate` already applies
/// the persisted [SettingsRepository.allowScreenshots] value before this
/// channel (or any Flutter engine) even exists, by reading the same
/// SharedPreferences key directly -- this call exists only for the *live*
/// case: flipping the Settings toggle while the app is already running, so
/// the change takes effect on the current window immediately rather than
/// waiting for the next cold start.
const _channel = MethodChannel('money_hub/security');

Future<void> applyScreenshotsAllowed(bool allowed) async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod('setScreenshotsAllowed', {'allowed': allowed});
  } on PlatformException {
    // Best-effort -- worst case the window keeps whatever FLAG_SECURE state
    // onCreate already set it to until the next cold start picks this up.
  }
}

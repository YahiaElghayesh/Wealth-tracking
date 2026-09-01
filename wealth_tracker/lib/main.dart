import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/security/quick_add_exemption.dart';
import 'data/pricing/background_refresh.dart';
import 'data/repositories/settings_repository.dart';
import 'data/sms/native_sms_channel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  if (Platform.isAndroid) {
    // Fire-and-forget: registration talks to the OS's job scheduler, no
    // need to hold up first frame for it, and a failure here shouldn't
    // block the app from starting.
    final hours = SettingsRepository(prefs).priceRefreshIntervalHours;
    unawaited(
      registerBackgroundPriceRefresh(frequency: Duration(hours: hours)),
    );

    // Claims the biometric-lock exemption *before* AppLockGate (built as
    // part of WealthTrackerApp below) even mounts, closing a race
    // app.dart's own equivalent, later check can't: AppLockGate's
    // auto-prompt only waits a fixed short delay for that later check to
    // claim the exemption, and on a loaded cold start this native
    // round-trip -- reading the Intent that launched the app, in case it's
    // a "bank text detected" notification tap -- can outlast that delay.
    // Awaiting it here, before the first frame, removes the race instead
    // of tuning the delay. `takePendingSms` is memoized (see
    // native_sms_channel.dart) so the real handling in app.dart, which
    // still needs to run once the Navigator exists, sees the exact same
    // result rather than the native side's already-cleared "nothing
    // pending" on a second call.
    final pendingSms = await takePendingSms();
    if (pendingSms != null) {
      quickAddScreenActive.value = true;
    }
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const WealthTrackerApp(),
    ),
  );
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/security/app_lock_exemption.dart';
import 'data/pricing/background_refresh.dart';
import 'data/repositories/settings_repository.dart';
import 'data/sms/native_sms_channel.dart';
import 'features/ledger/providers/quick_add_launch.dart';

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
    // app.dart's own equivalent, later checks can't: AppLockGate only
    // waits a bounded amount of time for a later check to claim the
    // exemption, and on a loaded cold start these native round-trips --
    // reading the Intent that launched the app, in case it's a "bank text
    // detected" notification tap or a quick-add widget/shortcut tap -- can
    // outlast that wait. Awaiting them here, before the first frame,
    // removes the race instead of tuning a delay. Both checks are
    // memoized (see native_sms_channel.dart and quick_add_launch.dart) so
    // the real handling in app.dart, which still needs to run once the
    // Navigator exists, sees the exact same result rather than the native
    // side's already-cleared "nothing pending" on a second call. Run
    // together rather than sequentially -- neither depends on the other,
    // so both futures are started before either is awaited.
    final pendingSmsFuture = takePendingSms();
    final widgetLaunchUriFuture = takeInitialWidgetLaunchUri();
    final pendingSms = await pendingSmsFuture;
    final widgetLaunchUri = await widgetLaunchUriFuture;
    if (pendingSms != null || widgetLaunchUri != null) {
      QuickActionExemption.claim();
    }
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const WealthTrackerApp(),
    ),
  );
}

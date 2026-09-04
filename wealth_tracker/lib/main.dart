import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/security/app_lock_exemption.dart';
import 'core/security/secure_settings_store.dart';
import 'data/pricing/background_refresh.dart';
import 'data/repositories/settings_repository.dart';
import 'data/sms/native_sms_channel.dart';
import 'features/ledger/providers/quick_add_launch.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final secureSettings = await SecureSettingsStore.load(prefs);

  if (Platform.isAndroid) {
    // Fire-and-forget: registration talks to the OS's job scheduler, no
    // need to hold up first frame for it, and a failure here shouldn't
    // block the app from starting.
    final hours = SettingsRepository(
      prefs,
      secureSettings,
    ).priceRefreshIntervalHours;
    unawaited(
      registerBackgroundPriceRefresh(frequency: Duration(hours: hours)),
    );

    // Tells AppLockGate (built as part of WealthTrackerApp below), before
    // it even mounts, that a real QuickActionExemption claim is on its way
    // once app.dart's own launch handling runs -- closing a race app.dart's
    // equivalent, later checks can't: AppLockGate's very first evaluation
    // runs synchronously in its own initState, before the widget tree that
    // would ever claim that exemption has even been built, so on a loaded
    // cold start these native round-trips -- reading the Intent that
    // launched the app, in case it's a "bank text detected" notification
    // tap or a quick-add widget/shortcut tap -- need to be known about
    // *before* that first evaluation runs, not just claimed by whoever gets
    // there first (see coldStartLaunchPending's own doc comment for why
    // this is a plain flag rather than a pre-claimed exemption). Both
    // checks are memoized (see native_sms_channel.dart and
    // quick_add_launch.dart) so the real handling in app.dart, which still
    // needs to run once the Navigator exists, sees the exact same result
    // rather than the native side's already-cleared "nothing pending" on a
    // second call. Run together rather than sequentially -- neither
    // depends on the other, so both futures are started before either is
    // awaited.
    final pendingSmsFuture = takePendingSms();
    final widgetLaunchUriFuture = takeInitialWidgetLaunchUri();
    final pendingSms = await pendingSmsFuture;
    final widgetLaunchUri = await widgetLaunchUriFuture;
    if (pendingSms != null || widgetLaunchUri != null) {
      coldStartLaunchPending = true;
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureSettingsStoreProvider.overrideWithValue(secureSettings),
      ],
      child: const WealthTrackerApp(),
    ),
  );
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/debug/debug_log.dart';
import 'core/providers/core_providers.dart';
import 'core/security/app_lock_exemption.dart';
import 'core/security/secure_settings_store.dart';
import 'data/pricing/background_refresh.dart';
import 'data/repositories/settings_repository.dart';
import 'data/sms/native_sms_channel.dart';
import 'features/ledger/providers/quick_add_launch.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDebugLog.install();
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
    // cold start these round-trips -- reading the Intent that launched the
    // app, in case it's a quick-add widget/shortcut tap or a tap on
    // showSmsChargeReviewNotification's "review this charge" notification
    // -- need to be known about *before* that first evaluation runs, not
    // just claimed by whoever gets there first (see coldStartLaunchPending's
    // own doc comment for why this is a plain flag rather than a
    // pre-claimed exemption). The pending-SMS check is legacy (see
    // native_sms_channel.dart's own doc comment -- nothing sets those
    // launch-Intent extras anymore now that SmsReceiver.kt never posts a
    // notification itself, so this always resolves null, harmlessly) but
    // left in place rather than pulled out along with everything else this
    // change touched. All three checks run together rather than
    // sequentially -- none depends on another, so every future is started
    // before any is awaited. flutter_local_notifications' own
    // getNotificationAppLaunchDetails needs `initialize` called first, but
    // that's a cheap, side-effect-free call safe to repeat -- app.dart's own
    // later `initialize` (with the real tap handlers this early one has no
    // use for) re-registers everything once the Navigator exists.
    final pendingSmsFuture = takePendingSms();
    final widgetLaunchUriFuture = takeInitialWidgetLaunchUri();
    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    await notificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final notificationLaunchFuture = notificationsPlugin
        .getNotificationAppLaunchDetails();
    final pendingSms = await pendingSmsFuture;
    final widgetLaunchUri = await widgetLaunchUriFuture;
    final notificationLaunch = await notificationLaunchFuture;
    if (pendingSms != null ||
        widgetLaunchUri != null ||
        (notificationLaunch?.didNotificationLaunchApp ?? false)) {
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/navigation/app_navigator.dart';
import 'core/security/app_lock_gate.dart';
import 'core/security/secure_settings_store.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_bottom_nav.dart';
import 'data/db/database.dart';
import 'data/notifications/sms_rule_notifications.dart';
import 'data/repositories/settings_repository.dart';
import 'data/sms/native_sms_channel.dart';
import 'data/sms/sms_ledger_processor.dart';
import 'features/calculator/screens/calculator_screen.dart';
import 'features/ledger/providers/quick_add_launch.dart';
import 'features/ledger/providers/widget_counterparties_sync.dart';
import 'features/ledger/screens/ledger_home_screen.dart';
import 'features/ledger/screens/statistics_screen.dart';
import 'features/networth/providers/asset_providers.dart' show databaseProvider;
import 'features/networth/providers/home_widget_providers.dart';
import 'features/networth/providers/pricing_providers.dart';
import 'features/networth/screens/dashboard_screen.dart';
import 'features/recurring/screens/recurring_payments_screen.dart';
import 'features/settings/providers/settings_providers.dart';

/// Top-level (per flutter_local_notifications' own requirement) handler
/// for a notification action tapped while this app's Dart VM isn't
/// running at all -- the only action any notification in this app
/// attaches is [showSmsChargeReviewNotification]'s "Quick add"
/// (`showsUserInterface: false`, so tapping it never launches the UI, and
/// always arrives here rather than [_RootShellState]'s own foreground
/// handler). Builds its own [AppDatabase] and profile lookup exactly like
/// `runSmsQuickAddTask` (background_refresh.dart) does for the same
/// action fired from a live isolate -- there is no ProviderScope here.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId != smsChargeReviewQuickAddActionId) return;
  unawaited(_commitQuickAddFromBackground(response));
}

Future<void> _commitQuickAddFromBackground(
  NotificationResponse response,
) async {
  final payload = response.payload;
  if (payload == null) return;
  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(payload) as Map<String, dynamic>;
  } catch (_) {
    return;
  }
  final body = decoded['body'] as String?;
  final timestampMillis = decoded['timestampMillis'] as int?;
  if (body == null || timestampMillis == null) return;

  final db = AppDatabase();
  try {
    final prefs = await SharedPreferences.getInstance();
    final secureSettings = await SecureSettingsStore.load(prefs);
    final profileId = SettingsRepository(prefs, secureSettings).activeProfileId;
    await commitSmsQuickAdd(
      db,
      body: body,
      timestampMillis: timestampMillis,
      profileId: profileId,
    );
  } finally {
    await db.close();
  }
}

class WealthTrackerApp extends ConsumerWidget {
  const WealthTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Money Hub',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      home: const _RootShell(),
      // Wraps *whatever route is currently on screen*, not just `home` --
      // unlike an earlier version of this gate that only covered
      // `_RootShell` and left any pushed route (Settings, Add Asset, a
      // quick-add screen, ...) visible if the app was backgrounded and
      // resumed while on one of those. AppLockGate's own doc comment covers
      // how it still exempts the quick-add flow specifically despite that.
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell>
    with WidgetsBindingObserver {
  int _index = 0;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  static const _staleAfter = Duration(minutes: 30);

  /// How long the app can sit backgrounded before a resume resets it back
  /// to the Dashboard tab with no pushed screens on top -- so coming back
  /// to the app after a while never lands on whatever settings/detail
  /// screen happened to be open when it was left, the same way most apps
  /// forget where you were after enough time away. A short backgrounding
  /// (switching to another app for a moment, the screen locking briefly)
  /// stays exactly where it was, since only [didChangeAppLifecycleState]'s
  /// resume path checks this, not every pause.
  static const _resetHomeAfter = Duration(minutes: 10);
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      (uri) => handleQuickAddLaunch(uri, ref),
    );
    // Deferred to after the first frame: called this early, navigatorKey's
    // Navigator isn't mounted yet, so the cold-start deep link would
    // silently drop (this was the "sometimes it just opens the app"
    // report — a timing race, not a deterministic failure).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      takeInitialWidgetLaunchUri().then(
        (uri) => handleQuickAddLaunch(uri, ref),
      );
    });
    if (Platform.isAndroid) {
      _initSmsCapture();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initSmsRuleNotificationHandling();
      });
    }
  }

  /// Registers this (now-live) isolate's handlers for
  /// [showSmsChargeReviewNotification]'s tap/action, then checks whether
  /// *this* cold start was itself caused by tapping one -- re-initializing
  /// the plugin here (on top of `main()`'s own earlier call, which only
  /// needed a bare answer to "was there one" for [coldStartLaunchPending])
  /// is what actually wires up [_onNotificationResponse] for this launch,
  /// and for any later tap while the app stays running.
  Future<void> _initSmsRuleNotificationHandling() async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    final launchDetails = await plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        response != null) {
      _onNotificationResponse(response);
    }
  }

  /// Handles a tap on [showSmsChargeReviewNotification] while this isolate
  /// is alive -- either the app was already open, or it just cold-started
  /// from that very tap (see [_initSmsRuleNotificationHandling]). The
  /// "Quick add" action ([smsChargeReviewQuickAddActionId]) commits
  /// headlessly via [commitSmsQuickAdd]; tapping the notification body
  /// itself re-runs [processIncomingSms], which re-matches the same SMS
  /// and pushes [SmsReviewScreen] for real -- both re-derive everything
  /// from the raw body/timestamp in the payload rather than trusting
  /// anything precomputed, the same "re-run the tested logic, don't thread
  /// a result through" choice [commitSmsAutoDetect] itself makes.
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final body = decoded['body'] as String?;
    final timestampMillis = decoded['timestampMillis'] as int?;
    if (body == null || timestampMillis == null) return;

    if (response.actionId == smsChargeReviewQuickAddActionId) {
      unawaited(
        commitSmsQuickAdd(
          ref.read(databaseProvider),
          body: body,
          timestampMillis: timestampMillis,
          profileId: ref.read(activeProfileIdProvider),
        ),
      );
      return;
    }

    unawaited(
      processIncomingSms(
        ref.read(databaseProvider),
        body: body,
        timestampMillis: timestampMillis,
        profileId: ref.read(activeProfileIdProvider),
      ),
    );
  }

  /// Legacy: `listenForNewSms`/`takePendingSms` (native_sms_channel.dart)
  /// only ever fired for a *native* notification's launch-Intent extras --
  /// both a cold start from tapping it and an already-running app brought
  /// forward by it worked this same way, since that notification's own
  /// PendingIntent was always what triggered either path, never a truly
  /// direct "SMS arrived while foregrounded" callback. Nothing sets those
  /// extras anymore now that SmsReceiver.kt never posts a notification
  /// itself (see its own doc comment) -- kept in place as a harmless no-op
  /// rather than pulled out along with everything else this change
  /// touched. See [_initSmsRuleNotificationHandling] for the real
  /// notification this app shows now ([showSmsChargeReviewNotification])
  /// and how its tap is actually handled.
  void _initSmsCapture() {
    listenForNewSms((sms) {
      processIncomingSms(
        ref.read(databaseProvider),
        body: sms.body,
        timestampMillis: sms.timestampMillis,
        profileId: ref.read(activeProfileIdProvider),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pending = await takePendingSms();
      if (pending != null) {
        await processIncomingSms(
          ref.read(databaseProvider),
          body: pending.body,
          timestampMillis: pending.timestampMillis,
          profileId: ref.read(activeProfileIdProvider),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt != null &&
        DateTime.now().difference(pausedAt) > _resetHomeAfter) {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
      if (_index != 0) setState(() => _index = 0);
    }

    final refreshState = ref.read(priceRefreshControllerProvider);
    final lastRefreshedAt = refreshState.lastRefreshedAt;
    final isStale =
        lastRefreshedAt == null ||
        DateTime.now().difference(lastRefreshedAt) > _staleAfter;
    if (!refreshState.isRefreshing && isStale) {
      ref.read(priceRefreshControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(homeWidgetSyncProvider);
    ref.watch(widgetCounterpartiesSyncProvider);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          LedgerHomeScreen(),
          StatisticsScreen(),
          CalculatorScreen(),
          RecurringPaymentsScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/debug/debug_log.dart';
import 'core/navigation/app_navigator.dart';
import 'core/security/app_lock_exemption.dart';
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
  Timer? _liveDataRefreshTimer;

  /// How often to re-query the ledger/calculator/recurring streams while
  /// the app sits open. `didChangeAppLifecycleState`'s own resume-time
  /// refresh (below) only fires on an actual pause->resume transition, but
  /// SMS auto-detect runs in its own background engine/isolate regardless
  /// of whether this app is foreground or backgrounded (see
  /// database.dart's `_openConnection` for why its writes can't push into
  /// this engine's already-open watch streams live) -- so a charge that
  /// arrives and gets auto-applied while the user is already sitting on,
  /// say, the Dashboard never triggers a pause/resume at all, and the
  /// ledger they open next shows stale data until they background and
  /// foreground the app themselves. Polling this cheaply and
  /// unconditionally while the app is open covers that case too, not just
  /// the backgrounded one.
  static const _liveDataRefreshInterval = Duration(seconds: 5);

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
    _liveDataRefreshTimer = Timer.periodic(
      _liveDataRefreshInterval,
      (_) => _refreshLiveData(),
    );
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
  /// from that very tap (see [_initSmsRuleNotificationHandling]). A single
  /// body tap does either job, decided by the payload's `quickAddFailed`
  /// flag (see [showSmsChargeReviewNotification]'s own doc comment): false
  /// commits headlessly via [commitSmsQuickAdd], true re-runs
  /// [processIncomingSms] instead, which re-matches the same SMS and
  /// pushes [SmsReviewScreen] for real -- both re-derive everything from
  /// the raw body/timestamp in the payload rather than trusting anything
  /// precomputed, the same "re-run the tested logic, don't thread a result
  /// through" choice [commitSmsAutoDetect] itself makes.
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      '_onNotificationResponse: actionId=${response.actionId} id=${response.id}',
    );
    final payload = response.payload;
    if (payload == null) {
      debugPrint('_onNotificationResponse: payload is null');
      return;
    }
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('_onNotificationResponse: jsonDecode failed: $e');
      return;
    }
    final body = decoded['body'] as String?;
    final timestampMillis = decoded['timestampMillis'] as int?;
    if (body == null || timestampMillis == null) {
      debugPrint('_onNotificationResponse: body or timestampMillis missing');
      return;
    }

    // See showSmsChargeReviewNotification's own doc comment: there's no
    // more separate "Quick add" action to check response.actionId against
    // -- a single body tap now does either job, decided by whether this
    // exact notification is a first-ever one (try Quick Add) or a repost
    // from Quick Add having already failed to resolve a ledger (open the
    // review screen's picker instead).
    if (decoded['quickAddFailed'] == true) {
      unawaited(
        processIncomingSms(
          ref.read(databaseProvider),
          body: body,
          timestampMillis: timestampMillis,
          profileId: ref.read(activeProfileIdProvider),
        ),
      );
      return;
    }

    unawaited(
      commitSmsQuickAdd(
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
    listenForNewSms(
      (sms) {
        processIncomingSms(
          ref.read(databaseProvider),
          body: sms.body,
          timestampMillis: sms.timestampMillis,
          profileId: ref.read(activeProfileIdProvider),
        );
      },
      onNativeNewIntent: (action) {
        // Always fires, for every onNewIntent -- see MainActivity.kt's own
        // comment on why this exists. Once this appears in a real device's
        // debug log, whether or not _onNotificationResponse ever does,
        // tells apart "onNewIntent itself never ran" from "it ran but
        // flutter_local_notifications' own delivery of it failed".
        debugPrint('_initSmsCapture: native onNewIntent fired, action=$action');
      },
      onNotificationBodyTapped: (payload) {
        // See MainActivity.kt's own onNewIntent override: an independent
        // fallback for a plain notification-body tap, parallel to (not
        // dependent on) flutter_local_notifications' own onDidReceive
        // NotificationResponse delivery -- a real on-device report showed
        // that path never reaching Dart at all while the app was already
        // open, with no other evidence of why. This re-derives everything
        // from the same raw payload _onNotificationResponse itself would
        // have received, the same "re-run the tested logic" choice
        // processIncomingSms's other callers already make.
        debugPrint(
          '_initSmsCapture: native onNotificationBodyTapped fallback fired, payload=$payload',
        );
        Map<String, dynamic> decoded;
        try {
          decoded = jsonDecode(payload) as Map<String, dynamic>;
        } catch (e) {
          debugPrint(
            '_initSmsCapture: onNotificationBodyTapped jsonDecode failed: $e',
          );
          return;
        }
        final body = decoded['body'] as String?;
        final timestampMillis = decoded['timestampMillis'] as int?;
        if (body == null || timestampMillis == null) {
          debugPrint(
            '_initSmsCapture: onNotificationBodyTapped missing body/timestampMillis in $decoded',
          );
          return;
        }
        // Same quickAddFailed dispatch as _onNotificationResponse -- see
        // that function's own comment on it.
        if (decoded['quickAddFailed'] == true) {
          unawaited(
            processIncomingSms(
              ref.read(databaseProvider),
              body: body,
              timestampMillis: timestampMillis,
              profileId: ref.read(activeProfileIdProvider),
            ),
          );
        } else {
          unawaited(
            commitSmsQuickAdd(
              ref.read(databaseProvider),
              body: body,
              timestampMillis: timestampMillis,
              profileId: ref.read(activeProfileIdProvider),
            ),
          );
        }
      },
    );
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
    _liveDataRefreshTimer?.cancel();
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  /// Re-queries (not re-fetches over any network) the streams a
  /// background-engine SMS write could have changed underneath this
  /// engine's own connection -- see [_liveDataRefreshInterval]'s own doc
  /// comment for why this can't just rely on a live cross-isolate push.
  ///
  /// Deliberately calls drift's own [GeneratedDatabase.markTablesUpdated]
  /// directly rather than `ref.invalidate`-ing the repository providers:
  /// invalidating a provider disposes its already-open `.watch()` streams
  /// and opens brand new ones, which for anything rendered with
  /// `AsyncValue.when` means a real (if brief) `loading` state -- every
  /// screen reading one of these blanks out and redraws every single tick,
  /// reported as the ledger screen "flashing" every few seconds.
  /// `markTablesUpdated` instead tells drift's *existing* stream queries
  /// "something touched these tables, re-run yourselves" -- the same
  /// subscription just emits a fresh value, with nothing to ever show a
  /// `loading` state for.
  void _refreshLiveData() {
    final db = ref.read(databaseProvider);
    db.markTablesUpdated([
      db.counterparties,
      db.ledgerTransactions,
      db.creditCards,
      db.bankAccounts,
      db.manualInputs,
      db.expectedTransactions,
      db.calculatorSnapshots,
      db.recurringPayments,
    ]);
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
      unawaited(_resetToHomeUnlessQuickAddLaunching());
    }

    final refreshState = ref.read(priceRefreshControllerProvider);
    final lastRefreshedAt = refreshState.lastRefreshedAt;
    final isStale =
        lastRefreshedAt == null ||
        DateTime.now().difference(lastRefreshedAt) > _staleAfter;
    if (!refreshState.isRefreshing && isStale) {
      ref.read(priceRefreshControllerProvider.notifier).refresh();
    }

    // A background WorkManager isolate or ActionBroadcastReceiver's own
    // headless engine (an SMS Rule balance/ledger update, a recurring
    // payment reminder's "Done" action, Quick Add, ...) may have written to
    // the very same database file while this app sat backgrounded -- each
    // holds its own separate connection (see database.dart's
    // `_openConnection` doc comment for why), so nothing pushes that write
    // into this engine's already-open watch streams on its own. Resuming
    // is the one moment guaranteed to matter most (the user is about to
    // look at the screen right now), so refresh immediately here rather
    // than waiting for `_liveDataRefreshTimer`'s own next tick.
    _refreshLiveData();
  }

  /// Resets the nav stack/tab back to Dashboard after a long background --
  /// except when this very resume is actually the "Add Payment" home-
  /// screen widget/shortcut being tapped (`handleQuickAddLaunch`,
  /// quick_add_launch.dart), which is also a resume as far as
  /// [didChangeAppLifecycleState] is concerned. That launch claims
  /// [QuickActionExemption] synchronously the instant it sees the tap, but
  /// doesn't actually push [AddTransactionScreen] until a Navigator/
  /// database round-trip finishes a moment later -- Android delivers the
  /// new Intent (which is what feeds that launch) before resuming the
  /// Activity, so the claim should already be in place by the time this
  /// runs, but platform-channel delivery order isn't a documented
  /// guarantee to lean on for something this visible. Racing a
  /// `popUntil` against that pending push either yanks the just-opened
  /// quick-add form straight back to Dashboard or discards it before it
  /// ever appears -- either way surfacing as the reported "the add-
  /// payment icon sometimes just opens the home/last page instead, and
  /// only works on a second tap". A short poll (mirroring
  /// `_awaitNavigator`'s own "wait briefly rather than assume" shape)
  /// gives a same-moment claim a little extra room to show up before this
  /// concludes there isn't one; skipping the reset when there is one costs
  /// nothing -- the next resume that isn't racing a launch does it instead.
  Future<void> _resetToHomeUnlessQuickAddLaunching() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      if (QuickActionExemption.isActive) return;
      await Future.delayed(const Duration(milliseconds: 40));
    }
    if (!mounted || QuickActionExemption.isActive) return;
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (_index != 0) setState(() => _index = 0);
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

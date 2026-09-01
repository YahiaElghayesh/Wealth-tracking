import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'core/navigation/app_navigator.dart';
import 'core/security/app_lock_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_bottom_nav.dart';
import 'data/sms/native_sms_channel.dart';
import 'data/sms/sms_ledger_processor.dart';
import 'features/calculator/providers/known_cards_sync.dart';
import 'features/calculator/providers/known_vendor_patterns_sync.dart';
import 'features/calculator/screens/calculator_screen.dart';
import 'features/ledger/providers/quick_add_launch.dart';
import 'features/ledger/providers/widget_counterparties_sync.dart';
import 'features/ledger/screens/ledger_home_screen.dart';
import 'features/ledger/screens/statistics_screen.dart';
import 'features/networth/providers/asset_providers.dart' show databaseProvider;
import 'features/networth/providers/home_widget_providers.dart';
import 'features/networth/providers/pricing_providers.dart';
import 'features/networth/screens/dashboard_screen.dart';
import 'features/settings/providers/settings_providers.dart';
import 'features/settings/providers/vendor_rule_providers.dart';

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
      HomeWidget.initiallyLaunchedFromHomeWidget().then(
        (uri) => handleQuickAddLaunch(uri, ref),
      );
    });
    if (Platform.isAndroid) _initSmsCapture();
  }

  /// Bank SMS detection never uses a background Dart isolate or a
  /// third-party SMS-reading plugin (a previous attempt at this broke the
  /// Android build outright — see native_sms_channel.dart) — a plain,
  /// manifest-registered Kotlin BroadcastReceiver posts a system
  /// notification on its own, and this only ever runs once the user has
  /// tapped that notification and the app is in the foreground. Covers
  /// both a cold start (`takePendingSms`, checked once after the first
  /// frame like the widget-tap launch above) and an already-running app
  /// brought forward by the tap (`listenForNewSms`).
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
    if (state != AppLifecycleState.resumed) return;
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
    ref.watch(knownCardsSyncProvider);
    ref.watch(knownVendorPatternsSyncProvider);
    ref.watch(vendorRuleSeedProvider);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          LedgerHomeScreen(),
          StatisticsScreen(),
          CalculatorScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

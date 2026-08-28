import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'data/sms/notification_action_handler.dart';
import 'features/calculator/screens/calculator_screen.dart';
import 'features/ledger/providers/quick_add_launch.dart';
import 'features/ledger/providers/sms_review_launch.dart';
import 'features/ledger/providers/widget_counterparties_sync.dart';
import 'features/ledger/screens/ledger_home_screen.dart';
import 'features/ledger/screens/statistics_screen.dart';
import 'features/networth/providers/home_widget_providers.dart';
import 'features/networth/providers/pricing_providers.dart';
import 'features/networth/screens/dashboard_screen.dart';

class WealthTrackerApp extends StatelessWidget {
  const WealthTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Wealth Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: const _RootShell(),
    );
  }
}

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell> with WidgetsBindingObserver {
  int _index = 0;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  static const _staleAfter = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetClickSubscription = HomeWidget.widgetClicked.listen((uri) => handleQuickAddLaunch(uri, ref));
    // Deferred to after the first frame: called this early, navigatorKey's
    // Navigator isn't mounted yet, so the cold-start deep link would
    // silently drop (this was the "sometimes it just opens the app"
    // report — a timing race, not a deterministic failure).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) => handleQuickAddLaunch(uri, ref));
    });
    if (Platform.isAndroid) _initNotifications();
  }

  /// Registers the notification response callbacks (must happen once,
  /// early — this is also where the top-level background handler for the
  /// "Add"/"Ignore" quick actions gets wired up) and checks whether this
  /// app start was itself triggered by tapping a bank-charge notification.
  Future<void> _initNotifications() async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) => handleNotificationResponse(response, ref),
      onDidReceiveBackgroundNotificationResponse: bankChargeNotificationBackgroundHandler,
    );
    final launchDetails = await plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      await handleNotificationResponse(launchDetails!.notificationResponse, ref);
    }
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
    final isStale = lastRefreshedAt == null || DateTime.now().difference(lastRefreshedAt) > _staleAfter;
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
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Net Worth'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Ledger'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Statistics'),
          NavigationDestination(icon: Icon(Icons.calculate), label: 'Calculator'),
        ],
      ),
    );
  }
}

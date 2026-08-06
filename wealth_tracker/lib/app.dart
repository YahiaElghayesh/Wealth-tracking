import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/ledger/screens/ledger_home_screen.dart';
import 'features/networth/providers/home_widget_providers.dart';
import 'features/networth/screens/dashboard_screen.dart';

class WealthTrackerApp extends StatelessWidget {
  const WealthTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

class _RootShellState extends ConsumerState<_RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(homeWidgetSyncProvider);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [DashboardScreen(), LedgerHomeScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Net Worth'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Ledger'),
        ],
      ),
    );
  }
}

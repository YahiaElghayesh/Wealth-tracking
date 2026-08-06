import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
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
      home: const DashboardScreen(),
    );
  }
}

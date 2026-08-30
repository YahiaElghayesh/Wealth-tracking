import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'data/pricing/background_refresh.dart';
import 'data/repositories/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  if (Platform.isAndroid) {
    // Fire-and-forget: registration talks to the OS's job scheduler, no
    // need to hold up first frame for it, and a failure here shouldn't
    // block the app from starting.
    final hours = SettingsRepository(prefs).priceRefreshIntervalHours;
    unawaited(registerBackgroundPriceRefresh(frequency: Duration(hours: hours)));
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const WealthTrackerApp(),
    ),
  );
}

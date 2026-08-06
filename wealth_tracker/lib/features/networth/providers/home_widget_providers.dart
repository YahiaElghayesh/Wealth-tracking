import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/widget/home_widget_service.dart';
import 'asset_providers.dart';

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) => HomeWidgetService());

/// Pushes the latest net worth summary to the Android home-screen widget
/// whenever it changes. Watch this once near the app root to keep the
/// widget in sync for as long as the app is running; failures (e.g. no
/// widget support on this platform) are non-fatal and swallowed.
final homeWidgetSyncProvider = Provider<void>((ref) {
  final netWorth = ref.watch(netWorthResultProvider);
  final usdToEgpRate = ref.watch(usdToEgpRateProvider);
  final service = ref.watch(homeWidgetServiceProvider);
  unawaited(
    service
        .updateNetWorthWidget(summary: netWorth.summary, usdToEgpRate: usdToEgpRate)
        .catchError((_) {}),
  );
});

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../db/database.dart';
import '../net_worth/net_worth_calculator.dart';
import '../repositories/price_cache_repository.dart';
import '../repositories/settings_repository.dart';
import '../widget/home_widget_service.dart';
import 'coingecko_price_provider.dart';
import 'fx_price_provider.dart';
import 'metals_price_provider.dart';
import 'price_refresh_orchestrator.dart';
import 'price_refresh_service.dart';

const backgroundPriceRefreshUniqueName = 'wealth_tracker_price_refresh';
const backgroundPriceRefreshTaskName = 'priceRefresh';

/// Runs 6 times a day (roughly — WorkManager batches for battery, so exact
/// timing isn't guaranteed) so the dashboard and the home-screen widget
/// have reasonably fresh prices even if the app isn't opened that often.
const backgroundPriceRefreshFrequency = Duration(hours: 4);

/// Entry point Android/WorkManager invokes in a headless Dart isolate —
/// there's no ProviderScope or widget tree here, so everything is built
/// directly rather than read from Riverpod.
@pragma('vm:entry-point')
void priceRefreshCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backgroundPriceRefreshTaskName) return true;
    try {
      await runBackgroundPriceRefresh();
      return true;
    } catch (_) {
      // Swallow — WorkManager would otherwise reschedule aggressively, and
      // the next periodic run (or the next app open) will just try again.
      return true;
    }
  });
}

Future<void> runBackgroundPriceRefresh() async {
  final db = AppDatabase();
  try {
    final assets = await db.select(db.assets).get();
    if (assets.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsRepository(prefs);
    final service = PriceRefreshService(
      cryptoProvider: CoinGeckoPriceProvider(),
      fxProvider: FxPriceProvider(),
      metalsProvider: MetalsPriceProvider(apiKey: settings.metalsApiKey),
    );

    final outcome = await refreshAndPersistPrices(
      assets: assets,
      service: service,
      cacheRepo: PriceCacheRepository(db),
    );

    final netWorth = calculateNetWorth(assets, outcome.allPrices);
    await HomeWidgetService().updateNetWorthWidget(
      summary: netWorth.summary,
      usdToEgpRate: outcome.usdToEgpRate,
    );
  } finally {
    await db.close();
  }
}

/// Registers the periodic background task. Call once from `main()`, Android
/// only — there's no equivalent always-on background execution model to
/// hook into on Windows, and the widget this feeds doesn't exist there
/// either.
Future<void> registerBackgroundPriceRefresh() async {
  await Workmanager().initialize(priceRefreshCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    backgroundPriceRefreshUniqueName,
    backgroundPriceRefreshTaskName,
    frequency: backgroundPriceRefreshFrequency,
    constraints: Constraints(networkType: NetworkType.connected),
    // Re-applies the current frequency/constraints on every app start
    // without cancelling an in-flight run — matters if this frequency ever
    // changes in a future update.
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

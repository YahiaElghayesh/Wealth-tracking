import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../db/database.dart';
import '../net_worth/net_worth_calculator.dart';
import '../repositories/price_cache_repository.dart';
import '../repositories/settings_repository.dart';
import '../sms/sms_ledger_processor.dart';
import '../widget/home_widget_service.dart';
import 'coingecko_price_provider.dart';
import 'fallback_price_provider.dart';
import 'fx_price_provider.dart';
import 'gold_api_com_price_provider.dart';
import 'metals_price_provider.dart';
import 'price_refresh_orchestrator.dart';
import 'price_refresh_service.dart';
import 'yahoo_finance_price_provider.dart';

const backgroundPriceRefreshUniqueName = 'wealth_tracker_price_refresh';
const backgroundPriceRefreshTaskName = 'priceRefresh';

/// WorkManager's own documented floor for a periodic task -- registering
/// anything shorter is silently clamped up to this by Android itself, so
/// the Settings picker never offers less.
const minPriceRefreshInterval = Duration(minutes: 15);

/// Entry point Android/WorkManager invokes in a headless Dart isolate —
/// there's no ProviderScope or widget tree here, so everything is built
/// directly rather than read from Riverpod. Handles every background task
/// this app enqueues through WorkManager, not just the periodic price
/// refresh it was originally written for -- also the one-off task a bank-
/// SMS notification's "Quick add" action enqueues natively from
/// SmsQuickAddActionReceiver.kt (see [smsQuickAddTaskName]), and the
/// one-off task SmsReceiver.kt enqueues automatically (no notification
/// involved at all) for a recognized card payment/refund alert (see
/// [smsAutoUpdateTaskName]) -- all the same headless-isolate mechanism,
/// just triggered on demand instead of on a timer.
@pragma('vm:entry-point')
void priceRefreshCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == backgroundPriceRefreshTaskName) {
        await runBackgroundPriceRefresh();
      } else if (task == smsQuickAddTaskName) {
        await runSmsQuickAddTask(inputData ?? const {});
      } else if (task == smsAutoUpdateTaskName) {
        await runSmsAutoUpdateTask(inputData ?? const {});
      }
      return true;
    } catch (_) {
      // Swallow — WorkManager would otherwise reschedule aggressively, and
      // the next periodic run (or the next incoming SMS / app open) will
      // just try again.
      return true;
    }
  });
}

/// Reads the `body`/`timestampMillis` a "Quick add" notification action
/// passed through WorkManager's input data and commits the charge via
/// [commitSmsQuickAdd], scoped to whichever profile is currently active on
/// this device — same [SettingsRepository]-backed lookup the foreground app
/// uses, so a quick-added entry lands in the same profile the user would
/// see it in if they'd opened the app instead.
Future<void> runSmsQuickAddTask(Map<String, dynamic> inputData) async {
  final body = inputData['body'] as String?;
  final timestampMillis = inputData['timestampMillis'] as int?;
  if (body == null || timestampMillis == null) return;

  final db = AppDatabase();
  try {
    final prefs = await SharedPreferences.getInstance();
    final profileId = SettingsRepository(prefs).activeProfileId;
    await commitSmsQuickAdd(db, body: body, timestampMillis: timestampMillis, profileId: profileId);
  } finally {
    await db.close();
  }
}

/// Reads the `body`/`timestampMillis` SmsReceiver.kt passed through
/// WorkManager's input data when it recognized an incoming SMS as a card
/// payment/settlement or refund alert, and applies it via
/// [commitSmsAutoUpdate] -- no notification, no ledger entry, scoped to
/// whichever profile is currently active on this device, same as
/// [runSmsQuickAddTask].
Future<void> runSmsAutoUpdateTask(Map<String, dynamic> inputData) async {
  final body = inputData['body'] as String?;
  final timestampMillis = inputData['timestampMillis'] as int?;
  if (body == null || timestampMillis == null) return;

  final db = AppDatabase();
  try {
    final prefs = await SharedPreferences.getInstance();
    final profileId = SettingsRepository(prefs).activeProfileId;
    await commitSmsAutoUpdate(db, body: body, timestampMillis: timestampMillis, profileId: profileId);
  } finally {
    await db.close();
  }
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
      metalsProvider: FallbackPriceProvider(
        primary: MetalsPriceProvider(apiKey: settings.metalsApiKey),
        secondary: GoldApiComPriceProvider(),
      ),
      stockProvider: YahooFinancePriceProvider(),
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

/// Registers the periodic background task, at [frequency] -- called once
/// from `main()` (Android only; there's no equivalent always-on background
/// execution model on Windows, and the widget this feeds doesn't exist
/// there either) with whatever interval Settings has saved, and again
/// whenever the user changes that interval from the Live Prices screen.
Future<void> registerBackgroundPriceRefresh({required Duration frequency}) async {
  await Workmanager().initialize(priceRefreshCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    backgroundPriceRefreshUniqueName,
    backgroundPriceRefreshTaskName,
    frequency: frequency,
    constraints: Constraints(networkType: NetworkType.connected),
    // Re-applies the current frequency/constraints without cancelling an
    // in-flight run -- matters both on every app start and whenever the
    // user picks a different interval.
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

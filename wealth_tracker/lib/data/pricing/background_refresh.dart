import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/security/secure_settings_store.dart';
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
import 'stockanalysis_price_provider.dart';
import 'yahoo_finance_price_provider.dart';
import 'yahoo_metals_price_provider.dart';

const backgroundPriceRefreshUniqueName = 'wealth_tracker_price_refresh';
const backgroundPriceRefreshTaskName = 'priceRefresh';

/// The WorkManager task name RecurringPaymentReminderDoneActionReceiver.kt
/// enqueues when the user taps "Done" on a manual recurring payment's
/// reminder notification -- must match the string switched on below.
const recurringPaymentMarkPaidTaskName = 'recurringPaymentMarkPaid';

/// WorkManager's own documented floor for a periodic task -- registering
/// anything shorter is silently clamped up to this by Android itself, so
/// the Settings picker never offers less.
const minPriceRefreshInterval = Duration(minutes: 15);

/// Entry point Android/WorkManager invokes in a headless Dart isolate —
/// there's no ProviderScope or widget tree here, so everything is built
/// directly rather than read from Riverpod. Handles every background task
/// this app enqueues through WorkManager, not just the periodic price
/// refresh it was originally written for -- also the one-off task a bank-
/// SMS charge-review notification's "Quick add" action enqueues (see
/// [smsQuickAddTaskName]), and the one-off task SmsReceiver.kt enqueues
/// unconditionally for every incoming SMS (see [smsAutoDetectTaskName]) --
/// all the same headless-isolate mechanism, just triggered on demand
/// instead of on a timer.
@pragma('vm:entry-point')
void priceRefreshCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == backgroundPriceRefreshTaskName) {
        await runBackgroundPriceRefresh();
      } else if (task == smsQuickAddTaskName) {
        await runSmsQuickAddTask(inputData ?? const {});
      } else if (task == smsAutoDetectTaskName) {
        await runSmsAutoDetectTask(inputData ?? const {});
      } else if (task == recurringPaymentMarkPaidTaskName) {
        await runRecurringPaymentMarkPaidTask(inputData ?? const {});
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

/// Reads the `body`/`timestampMillis` SmsReceiver.kt passed through
/// WorkManager's input data for *every* incoming SMS, unconditionally, and
/// runs the real SMS Rule matching via [commitSmsAutoDetect] -- no profile
/// lookup needed, since a balance rule searches across every profile's
/// cards/accounts and a ledger-payment rule resolves its own target
/// counterparty's profile itself.
Future<void> runSmsAutoDetectTask(Map<String, dynamic> inputData) async {
  final body = inputData['body'] as String?;
  final timestampMillis = inputData['timestampMillis'] as int?;
  if (body == null || timestampMillis == null) return;

  final db = AppDatabase();
  try {
    await commitSmsAutoDetect(db, body: body, timestampMillis: timestampMillis);
  } finally {
    await db.close();
  }
}

/// Reads the `paymentId` RecurringPaymentReminderDoneActionReceiver.kt
/// passed through WorkManager's input data when the user tapped "Done" on
/// a manual recurring payment's reminder notification, and marks that
/// payment paid for its current cycle -- the same `lastPaidAt` write the
/// in-app paid toggle makes (see RecurringPaymentRepository.setPaid), so
/// both paths converge on one place. No profile lookup needed: a payment
/// id is unique regardless of which profile it belongs to.
Future<void> runRecurringPaymentMarkPaidTask(
  Map<String, dynamic> inputData,
) async {
  final paymentId = inputData['paymentId'] as String?;
  if (paymentId == null) return;

  final db = AppDatabase();
  try {
    await (db.update(db.recurringPayments)
          ..where((t) => t.id.equals(paymentId)))
        .write(RecurringPaymentsCompanion(lastPaidAt: Value(DateTime.now())));
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
    final secureSettings = await SecureSettingsStore.load(prefs);
    final settings = SettingsRepository(prefs, secureSettings);
    final service = PriceRefreshService(
      cryptoProvider: CoinGeckoPriceProvider(),
      fxProvider: FxPriceProvider(),
      metalsProvider: FallbackPriceProvider(
        primary: FallbackPriceProvider(
          primary: MetalsPriceProvider(apiKey: settings.metalsApiKey),
          secondary: GoldApiComPriceProvider(),
        ),
        secondary: YahooMetalsPriceProvider(),
      ),
      stockProvider: FallbackPriceProvider(
        primary: YahooFinancePriceProvider(),
        secondary: StockAnalysisPriceProvider(),
      ),
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
Future<void> registerBackgroundPriceRefresh({
  required Duration frequency,
}) async {
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

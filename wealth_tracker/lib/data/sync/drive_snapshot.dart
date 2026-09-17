import 'package:flutter/material.dart' show ThemeMode;

import '../../core/models/asset_category.dart';
import '../db/database.dart';
import '../repositories/settings_repository.dart';

const _snapshotVersion = 2;

/// Everything that gets synced across devices, so deleting and reinstalling
/// the app and signing back in restores it exactly: every profile, assets,
/// the debt ledger and tabs, credit cards, bank accounts, manual calculator
/// inputs and its saved snapshot history, expected transactions, ledger
/// categories, recurring payments and their history, SMS-detection rules
/// (and the banks they belong to), vendor-matching rules, and tracked
/// returns -- plus the handful of non-secret app settings listed in
/// [_exportSettings]. Deliberately excludes `price_cache` (re-fetched from
/// live APIs anyway), `sync_meta` (this device's own SMS-dedupe bookkeeping,
/// meaningless on another device/reinstall), and every genuinely secret
/// setting (API keys, OAuth client secrets, live Drive tokens) -- those
/// stay in this device's own secure storage rather than a JSON file sitting
/// in Drive, same reasoning as [SettingsRepository]'s own doc comment on
/// why they're split from the plain prefs it also holds.
Future<Map<String, dynamic>> exportSnapshot(
  AppDatabase db, {
  required DateTime modifiedAt,
  SettingsRepository? settings,
}) async {
  final profiles = await db.select(db.profiles).get();
  final assets = await db.select(db.assets).get();
  final counterparties = await db.select(db.counterparties).get();
  final transactions = await db.select(db.ledgerTransactions).get();
  final calculatorInputs = await db.select(db.calculatorInputs).get();
  final vendorRules = await db.select(db.vendorRules).get();
  final calculatorSnapshots = await db.select(db.calculatorSnapshots).get();
  final creditCards = await db.select(db.creditCards).get();
  final bankAccounts = await db.select(db.bankAccounts).get();
  final manualInputs = await db.select(db.manualInputs).get();
  final expectedTransactions = await db.select(db.expectedTransactions).get();
  final ledgerCategories = await db.select(db.ledgerCategories).get();
  final recurringPayments = await db.select(db.recurringPayments).get();
  final recurringPaymentHistory = await db
      .select(db.recurringPaymentHistory)
      .get();
  final banks = await db.select(db.banks).get();
  final smsRules = await db.select(db.smsRules).get();
  final returns = await db.select(db.returns).get();

  return {
    'version': _snapshotVersion,
    'modifiedAt': modifiedAt.toUtc().toIso8601String(),
    'profiles': profiles.map((p) => p.toJson()).toList(),
    'assets': assets.map((a) => a.toJson()).toList(),
    'counterparties': counterparties.map((c) => c.toJson()).toList(),
    'ledgerTransactions': transactions.map((t) => t.toJson()).toList(),
    'calculatorInputs': calculatorInputs.map((c) => c.toJson()).toList(),
    'vendorRules': vendorRules.map((v) => v.toJson()).toList(),
    'calculatorSnapshots': calculatorSnapshots.map((s) => s.toJson()).toList(),
    'creditCards': creditCards.map((c) => c.toJson()).toList(),
    'bankAccounts': bankAccounts.map((b) => b.toJson()).toList(),
    'manualInputs': manualInputs.map((m) => m.toJson()).toList(),
    'expectedTransactions': expectedTransactions
        .map((e) => e.toJson())
        .toList(),
    'ledgerCategories': ledgerCategories.map((l) => l.toJson()).toList(),
    'recurringPayments': recurringPayments.map((r) => r.toJson()).toList(),
    'recurringPaymentHistory': recurringPaymentHistory
        .map((r) => r.toJson())
        .toList(),
    'banks': banks.map((b) => b.toJson()).toList(),
    'smsRules': smsRules.map((s) => s.toJson()).toList(),
    'returns': returns.map((r) => r.toJson()).toList(),
    if (settings != null) 'settings': _exportSettings(settings),
  };
}

/// Every [SettingsRepository] value that's plain app configuration rather
/// than a per-device secret -- see this file's own top comment for why
/// secrets (API keys, OAuth client secrets, live Drive tokens) never end up
/// here. `lastBiometricUnlockAt` is deliberately left out too: it's a
/// device-local cache the lock screen re-derives on its own, not a setting.
Map<String, dynamic> _exportSettings(SettingsRepository settings) {
  return {
    'themeMode': settings.themeMode.name,
    'hideValuesByDefault': settings.hideValuesByDefault,
    'activeProfileId': settings.activeProfileId,
    'defaultLedgerCounterpartyId': settings.defaultLedgerCounterpartyId,
    'smsNotificationsSilent': settings.smsNotificationsSilent,
    'smsCaptureEnabled': settings.smsCaptureEnabled,
    'priceRefreshIntervalHours': settings.priceRefreshIntervalHours,
    'biometricLockEnabled': settings.biometricLockEnabled,
    'biometricGraceMinutes': settings.biometricGraceMinutes,
    'allowScreenshots': settings.allowScreenshots,
    // Client IDs (unlike client secrets/tokens) aren't meaningfully
    // confidential -- Google's own guidance -- and restoring them saves
    // redoing the Google Cloud Console setup on every new device.
    'androidServerClientId': settings.androidServerClientId,
    'desktopClientId': settings.desktopClientId,
    for (final category in AssetCategory.values)
      'assetClassOverride_${category.name}':
          settings.assetClassOverrides[category]?.name,
  };
}

Future<void> _importSettings(
  SettingsRepository settings,
  Map<String, dynamic> json,
) async {
  final mode = json['themeMode'] as String?;
  if (mode == 'light') {
    await settings.setThemeMode(ThemeMode.light);
  } else if (mode == 'dark') {
    await settings.setThemeMode(ThemeMode.dark);
  } else if (mode == 'system') {
    await settings.setThemeMode(ThemeMode.system);
  }
  if (json['hideValuesByDefault'] is bool) {
    await settings.setHideValuesByDefault(json['hideValuesByDefault'] as bool);
  }
  if (json['activeProfileId'] is String) {
    await settings.setActiveProfileId(json['activeProfileId'] as String);
  }
  await settings.setDefaultLedgerCounterpartyId(
    json['defaultLedgerCounterpartyId'] as String?,
  );
  if (json['smsNotificationsSilent'] is bool) {
    await settings.setSmsNotificationsSilent(
      json['smsNotificationsSilent'] as bool,
    );
  }
  if (json['smsCaptureEnabled'] is bool) {
    await settings.setSmsCaptureEnabled(json['smsCaptureEnabled'] as bool);
  }
  if (json['priceRefreshIntervalHours'] is int) {
    await settings.setPriceRefreshIntervalHours(
      json['priceRefreshIntervalHours'] as int,
    );
  }
  if (json['biometricLockEnabled'] is bool) {
    await settings.setBiometricLockEnabled(
      json['biometricLockEnabled'] as bool,
    );
  }
  if (json['biometricGraceMinutes'] is int) {
    await settings.setBiometricGraceMinutes(
      json['biometricGraceMinutes'] as int,
    );
  }
  if (json['allowScreenshots'] is bool) {
    await settings.setAllowScreenshots(json['allowScreenshots'] as bool);
  }
  final androidServerClientId = json['androidServerClientId'];
  if (androidServerClientId is String) {
    await settings.setAndroidServerClientId(androidServerClientId);
  }
  final desktopClientId = json['desktopClientId'];
  if (desktopClientId is String) {
    await settings.setDesktopOAuthClient(
      clientId: desktopClientId,
      clientSecret: settings.desktopClientSecret,
    );
  }
  for (final category in AssetCategory.values) {
    final raw = json['assetClassOverride_${category.name}'];
    if (raw == AssetClass.liquid.name) {
      await settings.setAssetClassOverride(category, AssetClass.liquid);
    } else if (raw == AssetClass.nonLiquid.name) {
      await settings.setAssetClassOverride(category, AssetClass.nonLiquid);
    }
  }
}

DateTime? snapshotModifiedAt(Map<String, dynamic> json) {
  final raw = json['modifiedAt'];
  return raw is String ? DateTime.tryParse(raw) : null;
}

List<T> _decode<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  return (json[key] as List? ?? []).cast<Map<String, dynamic>>().map(fromJson).toList();
}

/// Replaces every synced table's contents with [json], then applies
/// [settings] if it was included (an older, version-1 snapshot -- or one
/// downloaded before this device had a [SettingsRepository] to pass --
/// simply won't have a `'settings'` key, so existing local settings are
/// left untouched rather than cleared). Runs in a single transaction so a
/// failure partway through doesn't leave the local database half-overwritten.
Future<void> importSnapshot(
  AppDatabase db,
  Map<String, dynamic> json, {
  SettingsRepository? settings,
}) async {
  final profiles = _decode(json, 'profiles', Profile.fromJson);
  final assets = _decode(json, 'assets', Asset.fromJson);
  final counterparties = _decode(json, 'counterparties', Counterparty.fromJson);
  final transactions = _decode(
    json,
    'ledgerTransactions',
    LedgerTransaction.fromJson,
  );
  final calculatorInputs = _decode(
    json,
    'calculatorInputs',
    CalculatorInput.fromJson,
  );
  final vendorRules = _decode(json, 'vendorRules', VendorRule.fromJson);
  final calculatorSnapshots = _decode(
    json,
    'calculatorSnapshots',
    CalculatorSnapshot.fromJson,
  );
  final creditCards = _decode(json, 'creditCards', CreditCard.fromJson);
  final bankAccounts = _decode(json, 'bankAccounts', BankAccount.fromJson);
  final manualInputs = _decode(json, 'manualInputs', ManualInput.fromJson);
  final expectedTransactions = _decode(
    json,
    'expectedTransactions',
    ExpectedTransaction.fromJson,
  );
  final ledgerCategories = _decode(
    json,
    'ledgerCategories',
    LedgerCategory.fromJson,
  );
  final recurringPayments = _decode(
    json,
    'recurringPayments',
    RecurringPayment.fromJson,
  );
  final recurringPaymentHistory = _decode(
    json,
    'recurringPaymentHistory',
    RecurringPaymentHistoryData.fromJson,
  );
  final banks = _decode(json, 'banks', Bank.fromJson);
  final smsRules = _decode(json, 'smsRules', SmsRule.fromJson);
  final returns = _decode(json, 'returns', Return.fromJson);

  await db.transaction(() async {
    // Children before parents -- harmless either way since this app never
    // turns SQLite foreign-key enforcement on, but keeping the habit means
    // nothing breaks if that ever changes.
    await db.delete(db.ledgerTransactions).go();
    await db.delete(db.vendorRules).go();
    await db.delete(db.smsRules).go();
    await db.delete(db.recurringPaymentHistory).go();
    await db.delete(db.recurringPayments).go();
    await db.delete(db.expectedTransactions).go();
    await db.delete(db.manualInputs).go();
    await db.delete(db.creditCards).go();
    await db.delete(db.bankAccounts).go();
    await db.delete(db.returns).go();
    await db.delete(db.ledgerCategories).go();
    await db.delete(db.calculatorSnapshots).go();
    await db.delete(db.calculatorInputs).go();
    await db.delete(db.counterparties).go();
    await db.delete(db.banks).go();
    await db.delete(db.assets).go();
    await db.delete(db.profiles).go();

    await db.batch((batch) {
      batch.insertAll(db.profiles, profiles.map((p) => p.toCompanion(true)));
      batch.insertAll(db.assets, assets.map((a) => a.toCompanion(true)));
      batch.insertAll(db.banks, banks.map((b) => b.toCompanion(true)));
      batch.insertAll(
        db.counterparties,
        counterparties.map((c) => c.toCompanion(true)),
      );
      batch.insertAll(
        db.calculatorInputs,
        calculatorInputs.map((c) => c.toCompanion(true)),
      );
      batch.insertAll(
        db.calculatorSnapshots,
        calculatorSnapshots.map((s) => s.toCompanion(true)),
      );
      batch.insertAll(
        db.ledgerCategories,
        ledgerCategories.map((l) => l.toCompanion(true)),
      );
      batch.insertAll(db.returns, returns.map((r) => r.toCompanion(true)));
      batch.insertAll(
        db.bankAccounts,
        bankAccounts.map((b) => b.toCompanion(true)),
      );
      batch.insertAll(
        db.creditCards,
        creditCards.map((c) => c.toCompanion(true)),
      );
      batch.insertAll(
        db.manualInputs,
        manualInputs.map((m) => m.toCompanion(true)),
      );
      batch.insertAll(
        db.expectedTransactions,
        expectedTransactions.map((e) => e.toCompanion(true)),
      );
      batch.insertAll(
        db.recurringPayments,
        recurringPayments.map((r) => r.toCompanion(true)),
      );
      batch.insertAll(
        db.recurringPaymentHistory,
        recurringPaymentHistory.map((r) => r.toCompanion(true)),
      );
      batch.insertAll(db.smsRules, smsRules.map((s) => s.toCompanion(true)));
      batch.insertAll(
        db.vendorRules,
        vendorRules.map((v) => v.toCompanion(true)),
      );
      batch.insertAll(
        db.ledgerTransactions,
        transactions.map((t) => t.toCompanion(true)),
      );
    });
  });

  final settingsJson = json['settings'];
  if (settings != null && settingsJson is Map<String, dynamic>) {
    await _importSettings(settings, settingsJson);
  }
}

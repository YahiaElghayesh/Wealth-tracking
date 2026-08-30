import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';

/// Re-read after every write so widgets watching this rebuild with the
/// latest value — `SettingsRepository` itself is a thin synchronous wrapper
/// around `SharedPreferences` with no change notifications of its own.
final metalsApiKeyProvider = StateProvider<String?>((ref) {
  return ref.watch(settingsRepositoryProvider).metalsApiKey;
});

/// Drives `MaterialApp.themeMode` — same seeded-then-optimistically-updated
/// pattern as [metalsApiKeyProvider]. Write via
/// `ref.read(settingsRepositoryProvider).setThemeMode(mode)` then
/// `ref.read(themeModeProvider.notifier).state = mode`.
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ref.watch(settingsRepositoryProvider).themeMode;
});

/// Which profile every profile-scoped repository provider filters/stamps
/// its queries with -- same seeded-then-optimistically-updated pattern as
/// [themeModeProvider]. Write via
/// `ref.read(settingsRepositoryProvider).setActiveProfileId(id)` then
/// `ref.read(activeProfileIdProvider.notifier).state = id`.
final activeProfileIdProvider = StateProvider<String>((ref) {
  return ref.watch(settingsRepositoryProvider).activeProfileId;
});

/// The ledger the "Confirm payment" review screen pre-selects when no
/// Vendor Rule already matches -- same seeded-then-optimistically-updated
/// pattern as [themeModeProvider]. Write via
/// `ref.read(settingsRepositoryProvider).setDefaultLedgerCounterpartyId(id)`
/// then `ref.read(defaultLedgerCounterpartyIdProvider.notifier).state = id`.
final defaultLedgerCounterpartyIdProvider = StateProvider<String?>((ref) {
  return ref.watch(settingsRepositoryProvider).defaultLedgerCounterpartyId;
});

/// How often the background price refresh runs -- same
/// seeded-then-optimistically-updated pattern as [themeModeProvider]. Write
/// via `ref.read(settingsRepositoryProvider).setPriceRefreshIntervalHours(h)`
/// then `ref.read(priceRefreshIntervalHoursProvider.notifier).state = h`, and
/// re-call `registerBackgroundPriceRefresh(frequency: ...)` so WorkManager
/// picks up the new interval immediately instead of at the next app start.
final priceRefreshIntervalHoursProvider = StateProvider<int>((ref) {
  return ref.watch(settingsRepositoryProvider).priceRefreshIntervalHours;
});

/// Whether the app-open biometric lock is turned on -- same
/// seeded-then-optimistically-updated pattern as [themeModeProvider]. Write
/// via `ref.read(settingsRepositoryProvider).setBiometricLockEnabled(v)`
/// then `ref.read(biometricLockEnabledProvider.notifier).state = v`.
final biometricLockEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(settingsRepositoryProvider).biometricLockEnabled;
});

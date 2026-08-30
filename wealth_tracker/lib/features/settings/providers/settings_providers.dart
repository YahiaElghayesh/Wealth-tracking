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

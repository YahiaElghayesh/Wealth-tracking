import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/settings_repository.dart';
import '../security/secure_settings_store.dart';

/// Overridden in `main()` with the awaited `SharedPreferences` instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
});

/// Overridden in `main()` with the awaited `SecureSettingsStore` instance.
final secureSettingsStoreProvider = Provider<SecureSettingsStore>((ref) {
  throw UnimplementedError(
    'secureSettingsStoreProvider must be overridden in main()',
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    ref.watch(sharedPreferencesProvider),
    ref.watch(secureSettingsStoreProvider),
  );
});

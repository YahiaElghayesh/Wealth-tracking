import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';

/// Re-read after every write so widgets watching this rebuild with the
/// latest value — `SettingsRepository` itself is a thin synchronous wrapper
/// around `SharedPreferences` with no change notifications of its own.
final metalsApiKeyProvider = StateProvider<String?>((ref) {
  return ref.watch(settingsRepositoryProvider).metalsApiKey;
});

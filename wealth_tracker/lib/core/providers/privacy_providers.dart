import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';

/// Whether monetary values are currently masked app-wide — toggled from the
/// Dashboard's app bar so the user can hand their phone to someone without
/// showing every balance. The in-memory toggle state itself doesn't
/// persist across a restart, but its *starting* value on each fresh launch
/// follows Settings -> "Hide values by default" (see
/// `SettingsRepository.hideValuesByDefault`).
final hideValuesProvider = StateProvider<bool>((ref) {
  return ref.watch(settingsRepositoryProvider).hideValuesByDefault;
});

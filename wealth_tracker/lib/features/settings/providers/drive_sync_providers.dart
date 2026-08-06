import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/sync/drive_sync_service.dart';

final driveSyncServiceProvider = Provider<DriveSyncService>((ref) {
  return DriveSyncService(ref.watch(settingsRepositoryProvider));
});

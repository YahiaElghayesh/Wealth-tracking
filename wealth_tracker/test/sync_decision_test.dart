import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_tracker/data/sync/sync_decision.dart';

void main() {
  group('decideSyncAction', () {
    final t0 = DateTime(2026, 1, 1);
    final t1 = DateTime(2026, 1, 2);
    final t2 = DateTime(2026, 1, 3);

    test('uploads immediately when no remote snapshot exists yet', () {
      final action = decideSyncAction(
        remoteExists: false,
        remoteModifiedAt: null,
        localModifiedAt: t1,
        lastSyncedAt: null,
      );
      expect(action, SyncAction.uploadFirstTime);
    });

    test('downloads when only the remote changed since the last sync', () {
      final action = decideSyncAction(
        remoteExists: true,
        remoteModifiedAt: t2,
        localModifiedAt: t0,
        lastSyncedAt: t1,
      );
      expect(action, SyncAction.download);
    });

    test('uploads when only the local device changed since the last sync', () {
      final action = decideSyncAction(
        remoteExists: true,
        remoteModifiedAt: t0,
        localModifiedAt: t2,
        lastSyncedAt: t1,
      );
      expect(action, SyncAction.upload);
    });

    test('flags a conflict when both sides changed since the last sync', () {
      final action = decideSyncAction(
        remoteExists: true,
        remoteModifiedAt: t2,
        localModifiedAt: t2,
        lastSyncedAt: t1,
      );
      expect(action, SyncAction.conflict);
    });

    test('treats a never-synced device with existing remote data as a conflict', () {
      final action = decideSyncAction(
        remoteExists: true,
        remoteModifiedAt: t1,
        localModifiedAt: t1,
        lastSyncedAt: null,
      );
      expect(action, SyncAction.conflict);
    });
  });
}

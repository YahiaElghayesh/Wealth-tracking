enum SyncAction { uploadFirstTime, upload, download, conflict }

/// Pure decision logic for last-writer-wins sync: given what's known about
/// the remote snapshot, the local data, and when this device last
/// successfully synced, decides whether to push, pull, or flag a genuine
/// conflict (both sides changed since the last sync). Kept separate from
/// [DriveSyncService] so it's testable without a real Drive/HTTP client.
SyncAction decideSyncAction({
  required bool remoteExists,
  required DateTime? remoteModifiedAt,
  required DateTime localModifiedAt,
  required DateTime? lastSyncedAt,
}) {
  if (!remoteExists) return SyncAction.uploadFirstTime;

  final remoteChanged =
      remoteModifiedAt != null && (lastSyncedAt == null || remoteModifiedAt.isAfter(lastSyncedAt));
  final localChanged = lastSyncedAt == null || localModifiedAt.isAfter(lastSyncedAt);

  if (remoteChanged && localChanged) return SyncAction.conflict;
  if (remoteChanged) return SyncAction.download;
  return SyncAction.upload;
}

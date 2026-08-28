import 'dart:convert';
import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;

import '../db/database.dart';
import '../repositories/settings_repository.dart';
import 'android_drive_auth.dart';
import 'desktop_drive_auth.dart';
import 'drive_auth.dart';
import 'drive_snapshot.dart';
import 'sync_decision.dart';

const _snapshotFileName = 'wealth_tracker_snapshot.json';

enum SyncOutcome { uploaded, downloaded, conflict, notSignedIn, error }

class DriveSyncResult {
  const DriveSyncResult(this.outcome, {this.message, this.remoteSnapshot});

  final SyncOutcome outcome;
  final String? message;

  /// Populated only when [outcome] is [SyncOutcome.conflict], so the UI can
  /// let the user pick a side without a second round-trip to Drive.
  final Map<String, dynamic>? remoteSnapshot;
}

/// Syncs the local database with a single JSON snapshot file kept in the
/// user's Drive `appDataFolder` (hidden from their normal Drive view).
///
/// Sync model is last-writer-wins on the whole snapshot: whichever side has
/// a newer `modifiedAt` since the last successful sync wins outright. If
/// *both* sides changed since the last sync, that's a genuine conflict —
/// reported back rather than guessed at, so [resolveConflict] can apply
/// whichever the user picks.
class DriveSyncService {
  DriveSyncService(this._settings) : _auth = _authProviderFor(_settings);

  final SettingsRepository _settings;
  final DriveAuthProvider _auth;
  gapis.AuthClient? _client;

  static DriveAuthProvider _authProviderFor(SettingsRepository settings) {
    if (Platform.isAndroid) return AndroidDriveAuthProvider(settings);
    return DesktopDriveAuthProvider(settings);
  }

  Future<bool> get isSignedIn async {
    if (_client != null) return true;
    _client = await _auth.signInSilently();
    return _client != null;
  }

  Future<void> signIn() async {
    _client = await _auth.signIn();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _client = null;
  }

  Future<DateTime> _localModifiedAt(AppDatabase db) async {
    final assets = await db.select(db.assets).get();
    final transactions = await db.select(db.ledgerTransactions).get();
    var latest = DateTime.fromMillisecondsSinceEpoch(0);
    for (final a in assets) {
      if (a.updatedAt.isAfter(latest)) latest = a.updatedAt;
    }
    for (final t in transactions) {
      if (t.createdAt.isAfter(latest)) latest = t.createdAt;
    }
    return latest;
  }

  Future<drive.File?> _findSnapshotFile(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_snapshotFileName'",
      $fields: 'files(id, name)',
    );
    return list.files?.isEmpty ?? true ? null : list.files!.first;
  }

  Future<Map<String, dynamic>> _downloadSnapshot(drive.DriveApi api, String fileId) async {
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final content = await media.stream.transform(utf8.decoder).join();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<void> _uploadSnapshot(
    drive.DriveApi api,
    AppDatabase db, {
    required drive.File? existing,
    required DateTime modifiedAt,
  }) async {
    final snapshot = await exportSnapshot(db, modifiedAt: modifiedAt);
    final bytes = utf8.encode(jsonEncode(snapshot));
    final media = drive.Media(Stream.value(bytes), bytes.length);

    if (existing != null) {
      await api.files.update(drive.File(), existing.id!, uploadMedia: media);
    } else {
      await api.files.create(
        drive.File(name: _snapshotFileName, parents: ['appDataFolder']),
        uploadMedia: media,
      );
    }
    await _settings.setLastSyncedAt(modifiedAt);
  }

  Future<DriveSyncResult> syncNow(AppDatabase db) async {
    if (!await isSignedIn) {
      return const DriveSyncResult(SyncOutcome.notSignedIn, message: 'Sign in to Google Drive first.');
    }

    try {
      final api = drive.DriveApi(_client!);
      final existing = await _findSnapshotFile(api);
      final now = DateTime.now();

      Map<String, dynamic>? remoteJson;
      DateTime? remoteModifiedAt;
      if (existing != null) {
        remoteJson = await _downloadSnapshot(api, existing.id!);
        remoteModifiedAt = snapshotModifiedAt(remoteJson);
      }
      final localModifiedAt = await _localModifiedAt(db);

      final action = decideSyncAction(
        remoteExists: existing != null,
        remoteModifiedAt: remoteModifiedAt,
        localModifiedAt: localModifiedAt,
        lastSyncedAt: _settings.lastSyncedAt,
      );

      switch (action) {
        case SyncAction.uploadFirstTime:
          await _uploadSnapshot(api, db, existing: null, modifiedAt: now);
          return const DriveSyncResult(SyncOutcome.uploaded, message: 'First sync — uploaded local data.');
        case SyncAction.conflict:
          return DriveSyncResult(
            SyncOutcome.conflict,
            message: 'Both this device and Google Drive changed since the last sync.',
            remoteSnapshot: remoteJson,
          );
        case SyncAction.download:
          await importSnapshot(db, remoteJson!);
          await _settings.setLastSyncedAt(remoteModifiedAt!);
          return const DriveSyncResult(SyncOutcome.downloaded, message: 'Applied newer data from Google Drive.');
        case SyncAction.upload:
          await _uploadSnapshot(api, db, existing: existing, modifiedAt: now);
          return const DriveSyncResult(SyncOutcome.uploaded, message: 'Uploaded local changes to Google Drive.');
      }
    } catch (e) {
      return DriveSyncResult(SyncOutcome.error, message: e.toString());
    }
  }

  /// Applies the user's choice after a [SyncOutcome.conflict]: `keepLocal`
  /// uploads the local database (overwriting Drive), otherwise downloads
  /// and applies [remoteSnapshot] (overwriting local data).
  Future<DriveSyncResult> resolveConflict(
    AppDatabase db, {
    required bool keepLocal,
    required Map<String, dynamic> remoteSnapshot,
  }) async {
    try {
      if (keepLocal) {
        final api = drive.DriveApi(_client!);
        final existing = await _findSnapshotFile(api);
        final now = DateTime.now();
        await _uploadSnapshot(api, db, existing: existing, modifiedAt: now);
        return const DriveSyncResult(SyncOutcome.uploaded, message: 'Kept this device\'s data.');
      } else {
        await importSnapshot(db, remoteSnapshot);
        final remoteModifiedAt = snapshotModifiedAt(remoteSnapshot) ?? DateTime.now();
        await _settings.setLastSyncedAt(remoteModifiedAt);
        return const DriveSyncResult(SyncOutcome.downloaded, message: 'Kept Google Drive\'s data.');
      }
    } catch (e) {
      return DriveSyncResult(SyncOutcome.error, message: e.toString());
    }
  }
}

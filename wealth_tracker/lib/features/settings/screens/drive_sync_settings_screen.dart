import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/sync/drive_sync_service.dart';
import '../../networth/providers/asset_providers.dart';
import '../providers/drive_sync_providers.dart';

class DriveSyncSettingsScreen extends ConsumerStatefulWidget {
  const DriveSyncSettingsScreen({super.key});

  @override
  ConsumerState<DriveSyncSettingsScreen> createState() => _DriveSyncSettingsScreenState();
}

class _DriveSyncSettingsScreenState extends ConsumerState<DriveSyncSettingsScreen> {
  late final TextEditingController _desktopClientIdController;
  late final TextEditingController _desktopClientSecretController;
  late final TextEditingController _androidServerClientIdController;

  bool? _driveSignedIn;
  bool _syncing = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider);
    _desktopClientIdController = TextEditingController(text: settings.desktopClientId ?? '');
    _desktopClientSecretController = TextEditingController(text: settings.desktopClientSecret ?? '');
    _androidServerClientIdController = TextEditingController(text: settings.androidServerClientId ?? '');
    _checkDriveSignInStatus();
  }

  @override
  void dispose() {
    _desktopClientIdController.dispose();
    _desktopClientSecretController.dispose();
    _androidServerClientIdController.dispose();
    super.dispose();
  }

  Future<void> _checkDriveSignInStatus() async {
    final signedIn = await ref.read(driveSyncServiceProvider).isSignedIn;
    if (mounted) setState(() => _driveSignedIn = signedIn);
  }

  Future<void> _saveDesktopClient() async {
    await ref.read(settingsRepositoryProvider).setDesktopOAuthClient(
          clientId: _desktopClientIdController.text.trim(),
          clientSecret: _desktopClientSecretController.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  Future<void> _saveAndroidServerClientId() async {
    await ref
        .read(settingsRepositoryProvider)
        .setAndroidServerClientId(_androidServerClientIdController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  Future<void> _signInToDrive() async {
    try {
      await ref.read(driveSyncServiceProvider).signIn();
      if (mounted) setState(() => _driveSignedIn = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
      }
    }
  }

  Future<void> _signOutOfDrive() async {
    await ref.read(driveSyncServiceProvider).signOut();
    if (mounted) setState(() => _driveSignedIn = false);
  }

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _syncMessage = null;
    });

    final service = ref.read(driveSyncServiceProvider);
    final db = ref.read(databaseProvider);
    var result = await service.syncNow(db);

    if (result.outcome == SyncOutcome.conflict && mounted) {
      final keepLocal = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Sync conflict'),
          content: const Text(
            'This device and Google Drive both have changes since the last sync. '
            'Which version should be kept? The other one will be overwritten.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Google Drive'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keep this device'),
            ),
          ],
        ),
      );
      if (keepLocal != null) {
        result = await service.resolveConflict(
          db,
          keepLocal: keepLocal,
          remoteSnapshot: result.remoteSnapshot!,
        );
      }
    }

    if (mounted) {
      setState(() {
        _syncing = false;
        _syncMessage = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.read(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Google Drive sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Keeps your phone and Windows app in sync via a hidden file in your own '
            'Google Drive. Requires a one-time OAuth setup — see the README.',
          ),
          const SizedBox(height: 16),
          if (Platform.isAndroid) ...[
            TextField(
              controller: _androidServerClientIdController,
              decoration: InputDecoration(
                labelText: 'Google Web Client ID',
                helperText: 'A "Web application" OAuth client from the same Google Cloud project as '
                    'your Android client — required by Google Sign-In even on Android. '
                    'Without it: "server client ID must be provided on Android".',
                suffixIcon: IconButton(icon: const Icon(Icons.save), onPressed: _saveAndroidServerClientId),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!Platform.isAndroid) ...[
            TextField(
              controller: _desktopClientIdController,
              decoration: const InputDecoration(labelText: 'Desktop OAuth Client ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desktopClientSecretController,
              decoration: const InputDecoration(labelText: 'Desktop OAuth Client Secret'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save OAuth client'),
              onPressed: _saveDesktopClient,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _driveSignedIn == true
                    ? OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
                        onPressed: _signOutOfDrive,
                      )
                    : FilledButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in to Google'),
                        onPressed: _signInToDrive,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: _syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: const Text('Sync now'),
                  onPressed: _syncing || _driveSignedIn != true ? null : _syncNow,
                ),
              ),
            ],
          ),
          if (settings.lastSyncedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Last synced: ${settings.lastSyncedAt}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (_syncMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_syncMessage!),
            ),
        ],
      ),
    );
  }
}

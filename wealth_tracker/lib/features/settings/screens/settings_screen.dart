import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/sync/drive_sync_service.dart';
import '../../networth/providers/asset_providers.dart';
import '../../networth/providers/pricing_providers.dart';
import '../providers/drive_sync_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _metalsKeyController;
  late final TextEditingController _desktopClientIdController;
  late final TextEditingController _desktopClientSecretController;

  bool? _driveSignedIn;
  bool _syncing = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _metalsKeyController = TextEditingController(text: ref.read(metalsApiKeyProvider) ?? '');
    final settings = ref.read(settingsRepositoryProvider);
    _desktopClientIdController = TextEditingController(text: settings.desktopClientId ?? '');
    _desktopClientSecretController = TextEditingController(text: settings.desktopClientSecret ?? '');
    _checkDriveSignInStatus();
  }

  @override
  void dispose() {
    _metalsKeyController.dispose();
    _desktopClientIdController.dispose();
    _desktopClientSecretController.dispose();
    super.dispose();
  }

  Future<void> _checkDriveSignInStatus() async {
    final signedIn = await ref.read(driveSyncServiceProvider).isSignedIn;
    if (mounted) setState(() => _driveSignedIn = signedIn);
  }

  Future<void> _saveMetalsKey() async {
    final key = _metalsKeyController.text.trim();
    await ref.read(settingsRepositoryProvider).setMetalsApiKey(key.isEmpty ? null : key);
    ref.read(metalsApiKeyProvider.notifier).state = key.isEmpty ? null : key;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    }
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
    final refreshState = ref.watch(priceRefreshControllerProvider);
    final settings = ref.read(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Live prices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Crypto (CoinGecko) and FX rates (open.er-api.com) work out of the box. '
            'Gold and silver need a free goldapi.io API key.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _metalsKeyController,
            decoration: InputDecoration(
              labelText: 'goldapi.io API key',
              suffixIcon: IconButton(icon: const Icon(Icons.save), onPressed: _saveMetalsKey),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: refreshState.isRefreshing
                ? null
                : () => ref.read(priceRefreshControllerProvider.notifier).refresh(),
            icon: refreshState.isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Refresh prices now'),
          ),
          if (refreshState.lastRefreshedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Last refreshed: ${refreshState.lastRefreshedAt}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (refreshState.errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: refreshState.errors
                    .map((e) => Text(e, style: const TextStyle(color: Colors.red)))
                    .toList(),
              ),
            ),
          const Divider(height: 40),
          Text('Google Drive sync', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Keeps your phone and Windows app in sync via a hidden file in your own '
            'Google Drive. Requires a one-time OAuth setup — see the README.',
          ),
          const SizedBox(height: 16),
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

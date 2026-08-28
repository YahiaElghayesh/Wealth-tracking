import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/calculator_card.dart';
import '../../../core/providers/core_providers.dart';
import '../../../data/sync/drive_sync_service.dart';
import '../../../data/widget/home_widget_service.dart';
import '../../calculator/providers/calculator_providers.dart';
import '../../networth/providers/asset_providers.dart';
import '../../networth/providers/home_widget_providers.dart';
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
  String _widgetBackgroundPreset = 'default';

  @override
  void initState() {
    super.initState();
    _metalsKeyController = TextEditingController(text: ref.read(metalsApiKeyProvider) ?? '');
    final settings = ref.read(settingsRepositoryProvider);
    _desktopClientIdController = TextEditingController(text: settings.desktopClientId ?? '');
    _desktopClientSecretController = TextEditingController(text: settings.desktopClientSecret ?? '');
    _checkDriveSignInStatus();
    _loadWidgetBackgroundPreset();
  }

  Future<void> _loadWidgetBackgroundPreset() async {
    final preset = await ref.read(homeWidgetServiceProvider).loadBackgroundPreset();
    if (mounted) setState(() => _widgetBackgroundPreset = preset);
  }

  Future<void> _setWidgetBackgroundPreset(String preset) async {
    setState(() => _widgetBackgroundPreset = preset);
    await ref.read(homeWidgetServiceProvider).setBackgroundPreset(preset);
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
          const SizedBox(height: 8),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse('https://www.goldapi.io/register'),
              mode: LaunchMode.externalApplication,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get a free API key at goldapi.io',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.open_in_new, size: 14, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _metalsKeyController,
            decoration: InputDecoration(
              labelText: 'goldapi.io API key',
              helperText: 'Paste the key from your goldapi.io dashboard, then tap save.',
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
          const Divider(height: 40),
          const _CardLimitsSection(),
          if (Platform.isAndroid) ...[
            const Divider(height: 40),
            _buildWidgetColorSection(context),
          ],
        ],
      ),
    );
  }

  static const _widgetPresetColors = {
    'default': Color(0xFF2E7D6B),
    'blue': Color(0xFF1565C0),
    'purple': Color(0xFF6A1B9A),
    'amber': Color(0xFFFF8F00),
    'charcoal': Color(0xFF263238),
  };

  Widget _buildWidgetColorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Widget color', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('Applies to both home-screen widgets.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: HomeWidgetService.backgroundPresets.map((preset) {
            final selected = preset == _widgetBackgroundPreset;
            return InkWell(
              onTap: () => _setWidgetBackgroundPreset(preset),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _widgetPresetColors[preset],
                  border: Border.all(
                    color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Credit card limits, editable here so changing one doesn't require an
/// app update — the Calculator tab reads these to work out what's owed on
/// each card from the available-balance figure the user types in there.
class _CardLimitsSection extends ConsumerStatefulWidget {
  const _CardLimitsSection();

  @override
  ConsumerState<_CardLimitsSection> createState() => _CardLimitsSectionState();
}

class _CardLimitsSectionState extends ConsumerState<_CardLimitsSection> {
  final _controllers = {for (final card in CalculatorCard.values) card: TextEditingController()};
  bool _seeded = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _formatValue(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  Future<void> _save(CalculatorCard card) async {
    final value = double.tryParse(_controllers[card]!.text.trim());
    if (value == null) return;
    await ref.read(calculatorRepositoryProvider).setCardLimit(card, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final limitsAsync = ref.watch(cardLimitsStreamProvider);

    return limitsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => Text('Error: $e'),
      data: (limits) {
        if (!_seeded) {
          for (final card in CalculatorCard.values) {
            _controllers[card]!.text = _formatValue(limits[card] ?? card.defaultLimit);
          }
          _seeded = true;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Credit card limits', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Used by the Calculator tab to work out what you owe on each card.'),
            const SizedBox(height: 16),
            for (final card in CalculatorCard.values) ...[
              TextField(
                controller: _controllers[card]!,
                decoration: InputDecoration(
                  labelText: card.label,
                  suffixIcon: IconButton(icon: const Icon(Icons.save), onPressed: () => _save(card)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

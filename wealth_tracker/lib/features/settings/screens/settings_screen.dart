import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/ledger_category.dart';
import '../../../core/providers/core_providers.dart';
import '../../../data/db/database.dart';
import '../../../data/sync/drive_sync_service.dart';
import '../../../data/widget/home_widget_service.dart';
import '../../ledger/providers/ledger_providers.dart';
import '../../networth/providers/asset_providers.dart';
import '../../networth/providers/home_widget_providers.dart';
import '../../networth/providers/pricing_providers.dart';
import '../providers/drive_sync_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/sms_capture_providers.dart';
import '../providers/vendor_rule_providers.dart';

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
  final _vendorPatternController = TextEditingController();
  late bool _smsCaptureEnabled;
  String _widgetBackgroundPreset = 'default';

  @override
  void initState() {
    super.initState();
    _metalsKeyController = TextEditingController(text: ref.read(metalsApiKeyProvider) ?? '');
    final settings = ref.read(settingsRepositoryProvider);
    _desktopClientIdController = TextEditingController(text: settings.desktopClientId ?? '');
    _desktopClientSecretController = TextEditingController(text: settings.desktopClientSecret ?? '');
    _smsCaptureEnabled = settings.smsCaptureEnabled;
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
    _vendorPatternController.dispose();
    super.dispose();
  }

  Future<void> _toggleSmsCapture(bool enable) async {
    if (!enable) {
      await ref.read(settingsRepositoryProvider).setSmsCaptureEnabled(false);
      setState(() => _smsCaptureEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turned off. Takes effect next time the app opens.')),
        );
      }
      return;
    }

    final granted = await requestSmsPermission();
    ref.read(smsPermissionGrantedProvider.notifier).state = granted;
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permission was not granted.')),
        );
      }
      return;
    }

    await ref.read(settingsRepositoryProvider).setSmsCaptureEnabled(true);
    startSmsListener(ref);
    setState(() => _smsCaptureEnabled = true);
  }

  Future<void> _showAddVendorRuleDialog(List<Counterparty> counterparties) async {
    _vendorPatternController.clear();
    String? counterpartyId = counterparties.isNotEmpty ? counterparties.first.id : null;
    String category = ledgerExpenseCategories.first;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add vendor rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _vendorPatternController,
                decoration: const InputDecoration(
                  labelText: 'Vendor name (as it appears in the SMS)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: counterpartyId,
                decoration: const InputDecoration(labelText: 'Ledger'),
                items: counterparties
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setDialogState(() => counterpartyId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ledgerExpenseCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => category = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: counterpartyId == null || _vendorPatternController.text.trim().isEmpty
                  ? null
                  : () async {
                      await ref.read(vendorRuleRepositoryProvider).addRule(
                            vendorPattern: _vendorPatternController.text.trim(),
                            counterpartyId: counterpartyId!,
                            category: category,
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
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
          if (Platform.isAndroid) ...[
            const Divider(height: 40),
            _buildWidgetColorSection(context),
            const Divider(height: 40),
            _buildSmsCaptureSection(context),
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

  Widget _buildSmsCaptureSection(BuildContext context) {
    final counterparties = ref.watch(counterpartiesStreamProvider).valueOrNull ?? const [];
    final rulesAsync = ref.watch(vendorRulesStreamProvider);
    final counterpartyNames = {for (final c in counterparties) c.id: c.name};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank SMS detection', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'When your bank texts you about a charge, shows a notification to add it to a '
          'ledger — nothing is recorded without you tapping to confirm. If the vendor matches '
          'a rule below, the notification offers one-tap Add/Ignore; otherwise tap it to pick '
          'where it goes. Reads incoming SMS in the background, so it needs a sensitive '
          'Android permission — only grant it if you\'re comfortable with that.',
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enabled'),
          value: _smsCaptureEnabled,
          onChanged: _toggleSmsCapture,
        ),
        if (_smsCaptureEnabled) ...[
          const SizedBox(height: 8),
          rulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
            data: (rules) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final rule in rules)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(rule.vendorPattern),
                    subtitle: Text(
                      '${counterpartyNames[rule.counterpartyId] ?? 'Unknown'} · ${rule.category}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref.read(vendorRuleRepositoryProvider).deleteRule(rule.id),
                    ),
                  ),
                if (rules.isEmpty) const Text('No vendor rules yet.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add vendor rule'),
            onPressed: counterparties.isEmpty ? null : () => _showAddVendorRuleDialog(counterparties),
          ),
        ],
      ],
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/security/screenshot_channel.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/settings_providers.dart';
import 'app_updates_settings_screen.dart';
import 'asset_classification_settings_screen.dart';
import 'bank_accounts_settings_screen.dart';
import 'bank_sms_settings_screen.dart';
import 'credit_cards_settings_screen.dart';
import 'drive_sync_settings_screen.dart';
import 'ledger_categories_settings_screen.dart';
import 'live_prices_settings_screen.dart';
import 'manual_inputs_settings_screen.dart';
import 'profiles_settings_screen.dart';
import 'widget_appearance_settings_screen.dart';

/// Top-level menu of settings sub-pages, grouped into the sections from the
/// approved redesign mockup (Appearance / Privacy / Ledger / SMS capture /
/// Assets / Backup) — kept short and un-scrolled on purpose so it doesn't
/// turn back into one long undifferentiated list; each destination owns
/// its own scrolling content.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final hideValuesByDefault = ref
        .watch(settingsRepositoryProvider)
        .hideValuesByDefault;
    final biometricLockEnabled = ref.watch(biometricLockEnabledProvider);
    final biometricGraceMinutes = ref.watch(biometricGraceMinutesProvider);
    final allowScreenshots = ref.watch(allowScreenshotsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SectionLabel('Profiles'),
          _SettingsTile(
            icon: Icons.people_alt_outlined,
            title: 'Profiles',
            subtitle: 'Separate, isolated data spaces — add, rename, switch',
            builder: (_) => const ProfilesSettingsScreen(),
          ),
          const SizedBox(height: 10),
          const _SectionLabel('Appearance'),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: _rowDecoration(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconChip(Icons.palette_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) {
                          final mode = selection.first;
                          ref
                              .read(settingsRepositoryProvider)
                              .setThemeMode(mode);
                          ref.read(themeModeProvider.notifier).state = mode;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const _SectionLabel('Privacy'),
          Container(
            decoration: _rowDecoration(context),
            child: SwitchListTile(
              secondary: _IconChip(Icons.visibility_off_outlined),
              title: const Text('Hide values by default'),
              subtitle: const Text('Also hides names, descriptions & icons'),
              value: hideValuesByDefault,
              onChanged: (enabled) {
                ref
                    .read(settingsRepositoryProvider)
                    .setHideValuesByDefault(enabled);
                ref.invalidate(settingsRepositoryProvider);
              },
            ),
          ),
          const SizedBox(height: 10),
          const _SectionLabel('Security'),
          Container(
            decoration: _rowDecoration(context),
            child: SwitchListTile(
              secondary: _IconChip(Icons.fingerprint),
              title: const Text('App lock'),
              subtitle: const Text(
                'Require fingerprint or Face ID to open the app',
              ),
              value: biometricLockEnabled,
              onChanged: (enabled) => _setBiometricLock(context, ref, enabled),
            ),
          ),
          if (biometricLockEnabled) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: _rowDecoration(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconChip(Icons.timer_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay unlocked for',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 9),
                        DropdownButtonFormField<int>(
                          initialValue: biometricGraceMinutes,
                          decoration: const InputDecoration(isDense: true),
                          items: [
                            for (final minutes in _biometricGraceMinuteOptions)
                              DropdownMenuItem(
                                value: minutes,
                                child: Text(_graceMinutesLabel(minutes)),
                              ),
                          ],
                          onChanged: (minutes) {
                            if (minutes != null) {
                              _setBiometricGraceMinutes(ref, minutes);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (Platform.isAndroid) ...[
            const SizedBox(height: 10),
            Container(
              decoration: _rowDecoration(context),
              child: SwitchListTile(
                secondary: _IconChip(Icons.screenshot_monitor_outlined),
                title: const Text('Allow screenshots'),
                subtitle: const Text(
                  'Off blocks screenshots, screen recording, and the '
                  'recent-apps preview',
                ),
                value: allowScreenshots,
                onChanged: (allowed) => _setAllowScreenshots(ref, allowed),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const _SectionLabel('Ledger'),
          _SettingsTile(
            icon: Icons.label,
            title: 'Categories & icons',
            subtitle: 'Manage the quick-pick categories for payments',
            builder: (_) => const LedgerCategoriesSettingsScreen(),
          ),
          _SettingsTile(
            icon: Icons.account_balance,
            title: 'Bank accounts',
            subtitle: 'Add, edit, or remove accounts used by the Calculator tab',
            builder: (_) => const BankAccountsSettingsScreen(),
          ),
          _SettingsTile(
            icon: Icons.credit_card,
            title: 'Credit cards',
            subtitle: 'Add, edit, or remove cards used by the Calculator tab',
            builder: (_) => const CreditCardsSettingsScreen(),
          ),
          _SettingsTile(
            icon: Icons.tune,
            title: 'Manual inputs',
            subtitle: 'Custom +/- amounts used by the Calculator tab',
            builder: (_) => const ManualInputsSettingsScreen(),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 10),
            const _SectionLabel('SMS capture'),
            _SettingsTile(
              icon: Icons.sms_outlined,
              title: 'Bank SMS detection',
              subtitle: 'Detect card charges/payments, and vendor rules',
              builder: (_) => const BankSmsSettingsScreen(),
            ),
          ],
          const SizedBox(height: 10),
          const _SectionLabel('Assets'),
          _SettingsTile(
            icon: Icons.water_drop_outlined,
            title: 'Liquid / non-liquid',
            subtitle: 'Which asset categories count as liquid',
            builder: (_) => const AssetClassificationSettingsScreen(),
          ),
          _SettingsTile(
            icon: Icons.trending_up,
            title: 'Live prices',
            subtitle: 'Crypto, FX, gold, silver and stock price sources',
            builder: (_) => const LivePricesSettingsScreen(),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 10),
            const _SectionLabel('Widgets'),
            _SettingsTile(
              icon: Icons.widgets,
              title: 'Widget appearance',
              subtitle: 'Color and opacity of the home-screen widgets',
              builder: (_) => const WidgetAppearanceSettingsScreen(),
            ),
            const SizedBox(height: 10),
            const _SectionLabel('Updates'),
            _SettingsTile(
              icon: Icons.system_update,
              title: 'App updates',
              subtitle: 'Check for and install the latest build',
              builder: (_) => const AppUpdatesSettingsScreen(),
            ),
          ],
          const SizedBox(height: 10),
          const _SectionLabel('Backup'),
          _SettingsTile(
            icon: Icons.cloud_sync,
            title: 'Google Drive sync',
            subtitle: 'Keep your phone and Windows app in sync',
            builder: (_) => const DriveSyncSettingsScreen(),
          ),
        ],
      ),
    );
  }
}

/// Turning the toggle off never needs to prove anything -- but turning it
/// on runs one real authentication first, so the user can't lock
/// themselves out of the app with a setting that turns out not to work
/// (no fingerprint/face/PIN enrolled, hardware unavailable, etc.).
Future<void> _setBiometricLock(
  BuildContext context,
  WidgetRef ref,
  bool enabled,
) async {
  final messenger = ScaffoldMessenger.of(context);

  if (!enabled) {
    await ref.read(settingsRepositoryProvider).setBiometricLockEnabled(false);
    ref.read(biometricLockEnabledProvider.notifier).state = false;
    return;
  }

  final localAuth = LocalAuthentication();
  try {
    if (!await localAuth.isDeviceSupported()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No fingerprint, face, or PIN lock is set up on this device.',
          ),
        ),
      );
      return;
    }
    final confirmed = await localAuth.authenticate(
      localizedReason: 'Confirm to turn on app lock',
      persistAcrossBackgrounding: true,
    );
    if (!confirmed) return;
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Could not verify fingerprint/Face ID. App lock not enabled.',
        ),
      ),
    );
    return;
  }

  await ref.read(settingsRepositoryProvider).setBiometricLockEnabled(true);
  ref.read(biometricLockEnabledProvider.notifier).state = true;
}

/// Options offered by the "Stay unlocked for" picker -- 0 keeps this app's
/// original "every time" behavior as the default so nobody who doesn't
/// touch this setting notices any change.
const _biometricGraceMinuteOptions = [0, 1, 5, 15, 30, 60];

String _graceMinutesLabel(int minutes) {
  if (minutes == 0) return 'Every time';
  if (minutes < 60) return '$minutes minute${minutes == 1 ? '' : 's'}';
  return '1 hour';
}

void _setBiometricGraceMinutes(WidgetRef ref, int minutes) {
  ref.read(settingsRepositoryProvider).setBiometricGraceMinutes(minutes);
  ref.read(biometricGraceMinutesProvider.notifier).state = minutes;
}

/// Applied to the live window immediately via [applyScreenshotsAllowed] --
/// `MainActivity.kt`'s own `onCreate` read only covers the next cold start,
/// which would otherwise leave whatever this session started with in effect
/// until the app is fully restarted.
void _setAllowScreenshots(WidgetRef ref, bool allowed) {
  ref.read(settingsRepositoryProvider).setAllowScreenshots(allowed);
  ref.read(allowScreenshotsProvider.notifier).state = allowed;
  applyScreenshotsAllowed(allowed);
}

BoxDecoration _rowDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: context.appColors.border),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.appColors.textDim,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: context.appColors.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _rowDecoration(context),
      child: ListTile(
        leading: _IconChip(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: builder)),
      ),
    );
  }
}

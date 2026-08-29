import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/settings_providers.dart';
import 'asset_classification_settings_screen.dart';
import 'bank_sms_settings_screen.dart';
import 'credit_cards_settings_screen.dart';
import 'drive_sync_settings_screen.dart';
import 'ledger_categories_settings_screen.dart';
import 'live_prices_settings_screen.dart';
import 'manual_inputs_settings_screen.dart';
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
    final hideValuesByDefault = ref.watch(settingsRepositoryProvider).hideValuesByDefault;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
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
                      Text('Theme', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 9),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                          ButtonSegment(value: ThemeMode.system, label: Text('System')),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) {
                          final mode = selection.first;
                          ref.read(settingsRepositoryProvider).setThemeMode(mode);
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
                ref.read(settingsRepositoryProvider).setHideValuesByDefault(enabled);
                ref.invalidate(settingsRepositoryProvider);
              },
            ),
          ),
          const SizedBox(height: 10),
          const _SectionLabel('Ledger'),
          _SettingsTile(
            icon: Icons.label,
            title: 'Categories & icons',
            subtitle: 'Manage the quick-pick categories for payments',
            builder: (_) => const LedgerCategoriesSettingsScreen(),
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
            subtitle: 'Crypto, FX, gold and silver price sources',
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
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: builder)),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

import 'asset_classification_settings_screen.dart';
import 'bank_sms_settings_screen.dart';
import 'credit_cards_settings_screen.dart';
import 'drive_sync_settings_screen.dart';
import 'ledger_categories_settings_screen.dart';
import 'live_prices_settings_screen.dart';
import 'widget_appearance_settings_screen.dart';

/// Top-level menu of settings sub-pages — kept short and un-scrolled on
/// purpose so it doesn't turn back into one long list; each destination
/// owns its own scrolling content.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SettingsTile(
            icon: Icons.trending_up,
            title: 'Live prices',
            subtitle: 'Crypto, FX, gold and silver price sources',
            builder: (_) => const LivePricesSettingsScreen(),
          ),
          _SettingsTile(
            icon: Icons.cloud_sync,
            title: 'Google Drive sync',
            subtitle: 'Keep your phone and Windows app in sync',
            builder: (_) => const DriveSyncSettingsScreen(),
          ),
          _SettingsTile(
            icon: Icons.credit_card,
            title: 'Credit cards',
            subtitle: 'Add, edit, or remove cards used by the Calculator tab',
            builder: (_) => const CreditCardsSettingsScreen(),
          ),
          _SettingsTile(
            icon: Icons.label,
            title: 'Ledger categories',
            subtitle: 'Manage the quick-pick categories for payments',
            builder: (_) => const LedgerCategoriesSettingsScreen(),
          ),
          if (Platform.isAndroid)
            _SettingsTile(
              icon: Icons.sms_outlined,
              title: 'Bank SMS detection',
              subtitle: 'Detect card charges/payments, and vendor rules',
              builder: (_) => const BankSmsSettingsScreen(),
            ),
          _SettingsTile(
            icon: Icons.water_drop_outlined,
            title: 'Liquid / non-liquid',
            subtitle: 'Which asset categories count as liquid',
            builder: (_) => const AssetClassificationSettingsScreen(),
          ),
          if (Platform.isAndroid)
            _SettingsTile(
              icon: Icons.widgets,
              title: 'Widget appearance',
              subtitle: 'Color and opacity of the home-screen widgets',
              builder: (_) => const WidgetAppearanceSettingsScreen(),
            ),
        ],
      ),
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
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: builder)),
    );
  }
}

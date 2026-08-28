import 'dart:io';

import 'package:flutter/material.dart';

import 'card_limits_settings_screen.dart';
import 'drive_sync_settings_screen.dart';
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
            title: 'Credit card limits',
            subtitle: 'Used by the Calculator tab',
            builder: (_) => const CardLimitsSettingsScreen(),
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

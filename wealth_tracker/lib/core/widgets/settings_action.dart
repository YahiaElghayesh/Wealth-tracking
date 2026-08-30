import 'package:flutter/material.dart';

import '../../features/settings/screens/settings_screen.dart';

/// The settings gear icon — originally only on the Net Worth tab's app bar,
/// now on every tab's, since Settings holds things relevant well beyond Net
/// Worth (SMS capture, categories, profiles...) and there's no reason
/// reaching it should require switching tabs first.
class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    );
  }
}

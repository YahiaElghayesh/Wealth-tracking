import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../networth/providers/pricing_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _metalsKeyController;

  @override
  void initState() {
    super.initState();
    _metalsKeyController = TextEditingController(text: ref.read(metalsApiKeyProvider) ?? '');
  }

  @override
  void dispose() {
    _metalsKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveMetalsKey() async {
    final key = _metalsKeyController.text.trim();
    await ref.read(settingsRepositoryProvider).setMetalsApiKey(key.isEmpty ? null : key);
    ref.read(metalsApiKeyProvider.notifier).state = key.isEmpty ? null : key;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final refreshState = ref.watch(priceRefreshControllerProvider);

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
        ],
      ),
    );
  }
}

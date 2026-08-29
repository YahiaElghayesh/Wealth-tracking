import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/core_providers.dart';
import '../../networth/providers/pricing_providers.dart';
import '../providers/settings_providers.dart';

class LivePricesSettingsScreen extends ConsumerStatefulWidget {
  const LivePricesSettingsScreen({super.key});

  @override
  ConsumerState<LivePricesSettingsScreen> createState() => _LivePricesSettingsScreenState();
}

class _LivePricesSettingsScreenState extends ConsumerState<LivePricesSettingsScreen> {
  late final TextEditingController _metalsKeyController;
  late final TextEditingController _stocksKeyController;

  @override
  void initState() {
    super.initState();
    _metalsKeyController = TextEditingController(text: ref.read(metalsApiKeyProvider) ?? '');
    _stocksKeyController = TextEditingController(text: ref.read(stocksApiKeyProvider) ?? '');
  }

  @override
  void dispose() {
    _metalsKeyController.dispose();
    _stocksKeyController.dispose();
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

  Future<void> _saveStocksKey() async {
    final key = _stocksKeyController.text.trim();
    await ref.read(settingsRepositoryProvider).setStocksApiKey(key.isEmpty ? null : key);
    ref.read(stocksApiKeyProvider.notifier).state = key.isEmpty ? null : key;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final refreshState = ref.watch(priceRefreshControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live prices')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crypto (CoinGecko) and FX rates (open.er-api.com) work out of the box. '
                    'Gold and silver need a free goldapi.io API key.',
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => launchUrl(
                      // Not /register — goldapi.io has no such page (loads
                      // blank). The real "get free API key" button is on
                      // the homepage itself.
                      Uri.parse('https://www.goldapi.io/'),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stocks (US exchanges and the Egyptian Exchange) need a free Twelve Data API key.',
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse('https://twelvedata.com/pricing'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get a free API key at twelvedata.com',
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
                    controller: _stocksKeyController,
                    decoration: InputDecoration(
                      labelText: 'Twelve Data API key',
                      helperText: 'Free tier: 800 requests/day. Paste the key, then tap save.',
                      suffixIcon: IconButton(icon: const Icon(Icons.save), onPressed: _saveStocksKey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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

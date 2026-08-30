import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/pricing/background_refresh.dart';
import '../../networth/providers/pricing_providers.dart';
import '../providers/settings_providers.dart';

/// Options offered by the refresh-interval picker below, in hours. Every
/// value here comfortably clears WorkManager's 15-minute floor
/// ([minPriceRefreshInterval]) -- these are spacing choices for the user to
/// reduce how often the free metals APIs get hit, not an attempt to offer
/// anything near that floor.
const _refreshIntervalOptionsHours = [1, 2, 4, 6, 12, 24];

class LivePricesSettingsScreen extends ConsumerStatefulWidget {
  const LivePricesSettingsScreen({super.key});

  @override
  ConsumerState<LivePricesSettingsScreen> createState() => _LivePricesSettingsScreenState();
}

class _LivePricesSettingsScreenState extends ConsumerState<LivePricesSettingsScreen> {
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

  Future<void> _setRefreshInterval(int hours) async {
    await ref.read(settingsRepositoryProvider).setPriceRefreshIntervalHours(hours);
    ref.read(priceRefreshIntervalHoursProvider.notifier).state = hours;
    if (Platform.isAndroid) {
      // Re-register with the new frequency now, rather than waiting for the
      // next app start to pick it up.
      await registerBackgroundPriceRefresh(frequency: Duration(hours: hours));
    }
  }

  @override
  Widget build(BuildContext context) {
    final refreshState = ref.watch(priceRefreshControllerProvider);
    final refreshIntervalHours = ref.watch(priceRefreshIntervalHoursProvider);

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
                    'Gold and silver price via a free goldapi.io API key when one is set below; '
                    'gold-api.com (no signup needed) automatically fills in whatever goldapi.io '
                    "couldn't -- a missing key or its monthly quota running out -- so metals still "
                    'price even without one.',
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
                    'How often prices refresh in the background. A longer interval means fewer '
                    'calls to the free gold/silver APIs, which helps avoid their rate limits — '
                    "you can always tap \"Refresh prices now\" below for an on-demand update.",
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: refreshIntervalHours,
                    decoration: const InputDecoration(labelText: 'Refresh every'),
                    items: [
                      for (final hours in _refreshIntervalOptionsHours)
                        DropdownMenuItem(
                          value: hours,
                          child: Text(hours == 1 ? 'Every hour' : 'Every $hours hours'),
                        ),
                    ],
                    onChanged: (hours) {
                      if (hours != null) _setRefreshInterval(hours);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Stocks (US exchanges and the Egyptian Exchange) price via Yahoo Finance — works out of the box, no API key needed.',
                style: Theme.of(context).textTheme.bodyMedium,
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

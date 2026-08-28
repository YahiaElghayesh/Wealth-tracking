import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/asset_category.dart';
import '../../../data/db/database.dart';
import '../../../data/net_worth/net_worth_calculator.dart';
import '../../settings/screens/settings_screen.dart';
import '../providers/asset_providers.dart';
import '../providers/pricing_providers.dart';
import '../widgets/net_worth_summary_card.dart';
import 'add_edit_asset_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cachedPricesLoaderProvider);
    final assetsAsync = ref.watch(assetsStreamProvider);
    final netWorth = ref.watch(netWorthResultProvider);
    final usdToEgpRate = ref.watch(usdToEgpRateProvider);
    final refreshState = ref.watch(priceRefreshControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
        actions: [
          IconButton(
            icon: refreshState.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: refreshState.isRefreshing
                ? null
                : () => ref.read(priceRefreshControllerProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: assetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (assets) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              NetWorthSummaryCard(summary: netWorth.summary, usdToEgpRate: usdToEgpRate),
              if (netWorth.unpricedAssets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${netWorth.unpricedAssets.length} asset(s) missing a live price — '
                    'excluded from the totals above. Pull to refresh prices from Settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange),
                  ),
                ),
              const SizedBox(height: 24),
              Text('Assets', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (assets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No assets yet. Tap + to add one.')),
                )
              else
                ...assets.map((asset) => _AssetTile(asset: asset)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditAssetScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AssetTile extends ConsumerWidget {
  const _AssetTile({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = AssetCategory.values.byName(asset.category);
    final prices = ref.watch(pricesUsdPerUnitProvider);
    final value = valueUsdForAsset(asset, prices);

    return Dismissible(
      key: ValueKey(asset.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete),
      ),
      onDismissed: (_) => ref.read(assetRepositoryProvider).delete(asset.id),
      child: Card(
        child: ListTile(
          title: Text(asset.name),
          subtitle: Text(
            '${category.label} · ${category.defaultClass == AssetClass.liquid ? "Liquid" : "Non-liquid"}',
          ),
          trailing: Text(value == null ? '—' : formatUsd(value)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddEditAssetScreen(existing: asset)),
          ),
        ),
      ),
    );
  }
}

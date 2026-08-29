import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/asset_category.dart';
import '../../../core/models/gold_karat.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
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
    ref.watch(autoRefreshOnLaunchProvider);
    final assetsAsync = ref.watch(assetsStreamProvider);
    final netWorth = ref.watch(netWorthResultProvider);
    final usdToEgpRate = ref.watch(usdToEgpRateProvider);
    final refreshState = ref.watch(priceRefreshControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
        actions: [
          const HideValuesAction(),
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
                    'excluded from the totals above. Tap refresh above, or check Settings for errors.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange),
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
    final usdToEgpRate = ref.watch(usdToEgpRateProvider);
    final hideValues = ref.watch(hideValuesProvider);
    final classOverrides = ref.watch(assetClassOverridesProvider);
    final assetClass = classOverrides[category] ?? category.defaultClass;
    final value = valueUsdForAsset(asset, prices);
    final egpValue = value == null || usdToEgpRate == null ? null : value * usdToEgpRate;
    final karat = category == AssetCategory.gold
        ? GoldKarat.fromPriceSymbol(asset.symbolOrCurrency)
        : null;
    final categoryLabel = karat == null ? category.label : '${category.label} (${karat.label})';

    final theme = Theme.of(context);
    final colors = context.appColors;
    final (icon, tint) = _iconFor(category, asset.symbolOrCurrency, asset.vehicleType, colors);

    return Dismissible(
      key: ValueKey(asset.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete),
      ),
      onDismissed: (_) => ref.read(assetRepositoryProvider).delete(asset.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddEditAssetScreen(existing: asset)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: hideValues ? Icon(Icons.lock_outline, size: 16, color: colors.textDim) : icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hideValues ? '••••••' : asset.name,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hideValues
                          ? '••••••'
                          : '$categoryLabel · ${assetClass == AssetClass.liquid ? "Liquid" : "Non-liquid"}',
                      style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim),
                    ),
                  ],
                ),
              ),
              if (value != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(
                      egpValue == null ? '—' : formatEgp(egpValue),
                      style: theme.textTheme.bodyMedium,
                    ),
                    MoneyText(
                      formatUsd(value),
                      style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim),
                    ),
                  ],
                )
              else
                const Text('—'),
            ],
          ),
        ),
      ),
    );
  }
}

(Widget, Color) _iconFor(AssetCategory category, String symbolOrCurrency, String? vehicleType, AppColors colors) {
  switch (category) {
    case AssetCategory.crypto:
      final isBtc = symbolOrCurrency.toLowerCase() == 'bitcoin';
      return isBtc
          ? (AppIcon.btc(size: 20), colors.btc.withValues(alpha: 0.12))
          : (Icon(Icons.currency_exchange, size: 18, color: colors.textDim), colors.surface2);
    case AssetCategory.gold:
      return (AppIcon.goldBar(size: 20), colors.gold.withValues(alpha: 0.13));
    case AssetCategory.silver:
      return (AppIcon.silverBar(size: 20), colors.silver.withValues(alpha: 0.16));
    case AssetCategory.cash:
      return (AppIcon.cash(size: 18, color: colors.good), colors.good.withValues(alpha: 0.13));
    case AssetCategory.vehicle:
      final vehicleIcon = switch (vehicleType) {
        'motorcycle' => AppIcon.motorcycle(size: 18, color: colors.bad),
        'scooter' => AppIcon.scooter(size: 18, color: colors.bad),
        _ => AppIcon.car(size: 18, color: colors.bad, holeColor: colors.surface2),
      };
      return (vehicleIcon, colors.bad.withValues(alpha: 0.1));
    case AssetCategory.realEstate:
      return (Icon(Icons.home_work_outlined, size: 18, color: colors.textDim), colors.surface2);
    case AssetCategory.other:
      return (Icon(Icons.inventory_2_outlined, size: 18, color: colors.textDim), colors.surface2);
  }
}

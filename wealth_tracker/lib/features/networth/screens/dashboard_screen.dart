import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/asset_category.dart';
import '../../../core/models/gold_karat.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/settings_action.dart';
import '../../../data/db/database.dart';
import '../../../data/net_worth/net_worth_calculator.dart';
import '../../settings/providers/settings_providers.dart';
import '../../settings/screens/profiles_settings_screen.dart';
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
    final hideValues = ref.watch(hideValuesProvider);

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
          const _ProfileSwitcherAction(),
          const SettingsAction(),
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
              const SizedBox(height: 8),
              Text('Assets', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (assets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No assets yet. Tap + to add one.')),
                )
              else
                ..._groupedByCategory(assets).expand(
                      (section) => [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                          child: Text(
                            hideValues ? '••••••' : section.label.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: context.appColors.textDim,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                        _CategorySummaryCard(label: section.label, isMetals: section.isMetals, assets: section.assets),
                        ...section.assets.map((asset) => _AssetTile(asset: asset)),
                      ],
                    ),
              // Clears the FAB, which otherwise sits directly over the
              // last row's value -- the FAB floats at a fixed screen
              // position, not accounted for by the ListView's own layout.
              const SizedBox(height: 80),
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

/// One rendered group in the dashboard's asset list: a header, the assets
/// under it, and whether it's the combined Gold+Silver "Metals" group
/// (which gets the karat/weight breakdown card instead of a plain total).
class _AssetSection {
  const _AssetSection({required this.label, required this.assets, required this.isMetals});

  final String label;
  final List<Asset> assets;
  final bool isMetals;
}

/// Groups [assets] by category, in [AssetCategory.values] order, dropping
/// any category with nothing in it — so the list reads as sections
/// (Crypto, Metals, Cash, ...) instead of one long undifferentiated stack.
/// Gold and Silver — two separate [AssetCategory] values, since they price
/// differently and stay separate in the data model — are combined into one
/// "Metals" section here, purely a display grouping: a user thinking about
/// their precious-metals holdings doesn't want them split into two section
/// headers on screen.
List<_AssetSection> _groupedByCategory(List<Asset> assets) {
  final byCategory = <AssetCategory, List<Asset>>{};
  for (final category in AssetCategory.values) {
    final matches = assets.where((a) => a.category == category.name).toList();
    if (matches.isNotEmpty) byCategory[category] = matches;
  }

  final sections = <_AssetSection>[];
  var metalsAdded = false;
  for (final category in AssetCategory.values) {
    if (category == AssetCategory.gold || category == AssetCategory.silver) {
      if (metalsAdded) continue;
      metalsAdded = true;
      final combined = [...?byCategory[AssetCategory.gold], ...?byCategory[AssetCategory.silver]];
      if (combined.isNotEmpty) {
        sections.add(_AssetSection(label: 'Metals', assets: combined, isMetals: true));
      }
      continue;
    }
    final matches = byCategory[category];
    if (matches != null) {
      sections.add(_AssetSection(label: category.label, assets: matches, isMetals: false));
    }
  }
  return sections;
}

/// Formats a held quantity without trailing zeros -- "0.5", not
/// "0.500000", but still "12" rather than "12.0" for a whole number.
String _trimmedQuantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  var s = value.toStringAsFixed(6);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return s;
}

/// A short "how much is held" label shown alongside the category on each
/// asset row -- grams for metals, share count for stocks, raw quantity for
/// crypto (the asset's name already carries the coin, so no unit suffix is
/// needed there). Currency-valued assets (cash, vehicles, real estate,
/// certificates) have no separate "quantity" concept worth showing; the
/// value itself already *is* the amount.
String? _quantityLabel(Asset asset) {
  switch (ValuationMode.values.byName(asset.valuationMode)) {
    case ValuationMode.metal:
      return '${_trimmedQuantity(asset.quantity)}g';
    case ValuationMode.stock:
      return '${_trimmedQuantity(asset.quantity)} sh';
    case ValuationMode.crypto:
      return _trimmedQuantity(asset.quantity);
    case ValuationMode.currency:
      return null;
  }
}

/// Sits above every asset-category group, right below its header — a
/// metals weight breakdown for the combined Gold+Silver "Metals" section
/// (since "total value" alone loses the karat detail that matters there),
/// or a plain total-value roll-up for every other category. Styled
/// distinctly from the plain [_AssetTile] cards below it (tinted
/// background, colored border) so a summary reads as a summary at a
/// glance rather than blending in as just another row. All numeric content
/// goes through [MoneyText] so it masks itself automatically when
/// hide-values is on.
class _CategorySummaryCard extends ConsumerWidget {
  const _CategorySummaryCard({required this.label, required this.isMetals, required this.assets});

  final String label;
  final bool isMetals;
  final List<Asset> assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMetals) {
      return _MetalsSummaryCard(assets: assets);
    }

    final prices = ref.watch(pricesUsdPerUnitProvider);
    final usdToEgpRate = ref.watch(usdToEgpRateProvider);
    final hideValues = ref.watch(hideValuesProvider);
    var totalUsd = 0.0;
    var pricedCount = 0;
    for (final asset in assets) {
      final v = valueUsdForAsset(asset, prices);
      if (v != null) {
        totalUsd += v;
        pricedCount++;
      }
    }
    if (pricedCount == 0) return const SizedBox.shrink();
    final totalEgp = usdToEgpRate == null ? null : totalUsd * usdToEgpRate;

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _summaryCardDecoration(theme),
      child: Row(
        children: [
          Icon(Icons.summarize_outlined, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hideValues ? '••••••' : '$label total',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(
                totalEgp == null ? '—' : formatEgpWhole(totalEgp),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                maskLength: 8,
              ),
              MoneyText(
                formatUsdWhole(totalUsd),
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                maskLength: 6,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shared look for every category-summary card — a primary-tinted
/// background and border, distinct from [_AssetTile]'s plain surface card,
/// so summaries are visually unmistakable from the individual assets below
/// them.
BoxDecoration _summaryCardDecoration(ThemeData theme) {
  return BoxDecoration(
    color: theme.colorScheme.primary.withValues(alpha: 0.07),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.28)),
  );
}

/// Aggregate gold/silver holdings across the combined Metals section --
/// gold broken down by karat, since a 21K gram and a 24K gram aren't the
/// same amount of pure gold -- plus a total-value and total-cost line in
/// the same style as [_CategorySummaryCard]'s generic total, so Metals
/// isn't the one section missing a value roll-up.
class _MetalsSummaryCard extends ConsumerWidget {
  const _MetalsSummaryCard({required this.assets});

  final List<Asset> assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goldByKarat = <GoldKarat, double>{};
    var silverTotal = 0.0;
    for (final asset in assets) {
      final category = AssetCategory.values.byName(asset.category);
      if (category == AssetCategory.gold) {
        final karat = GoldKarat.fromPriceSymbol(asset.symbolOrCurrency);
        if (karat != null) {
          goldByKarat[karat] = (goldByKarat[karat] ?? 0) + asset.quantity;
        }
      } else if (category == AssetCategory.silver) {
        silverTotal += asset.quantity;
      }
    }
    if (goldByKarat.isEmpty && silverTotal <= 0) return const SizedBox.shrink();

    final prices = ref.watch(pricesUsdPerUnitProvider);
    final usdToEgpRate = ref.watch(usdToEgpRateProvider);
    final hideValues = ref.watch(hideValuesProvider);
    var totalValueUsd = 0.0;
    var totalCostUsd = 0.0;
    var hasCost = false;
    for (final asset in assets) {
      final v = valueUsdForAsset(asset, prices);
      if (v != null) totalValueUsd += v;
      final purchasePrice = asset.purchasePrice;
      final purchaseCurrency = asset.purchaseCurrency;
      if (purchasePrice != null && purchaseCurrency != null && purchasePrice > 0) {
        final purchasePriceUsd = prices[purchaseCurrency];
        if (purchasePriceUsd != null) {
          totalCostUsd += purchasePrice * purchasePriceUsd;
          hasCost = true;
        }
      }
    }
    final totalValueEgp = usdToEgpRate == null ? null : totalValueUsd * usdToEgpRate;
    final totalCostEgp = usdToEgpRate == null ? null : totalCostUsd * usdToEgpRate;

    final goldTotal = goldByKarat.values.fold(0.0, (a, b) => a + b);
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: _summaryCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hideValues ? '••••••' : 'Metals total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    totalValueEgp == null ? '—' : formatEgpWhole(totalValueEgp),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    maskLength: 8,
                  ),
                  MoneyText(
                    formatUsdWhole(totalValueUsd),
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                    maskLength: 6,
                  ),
                ],
              ),
            ],
          ),
          if (hasCost) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Spacer(),
                Text(
                  'Cost: ',
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim),
                ),
                MoneyText(
                  totalCostEgp == null ? '—' : formatEgpWhole(totalCostEgp),
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim, fontWeight: FontWeight.w700),
                  maskLength: 8,
                ),
                Text(
                  ' · ',
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim),
                ),
                MoneyText(
                  formatUsdWhole(totalCostUsd),
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim),
                  maskLength: 6,
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(height: 1, color: theme.colorScheme.primary.withValues(alpha: 0.15)),
          const SizedBox(height: 10),
          if (goldByKarat.isNotEmpty) ...[
            Row(
              children: [
                AppIcon.goldBar(size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: MoneyText(
                    'Gold — total ${_trimmedQuantity(goldTotal)}g',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maskLength: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (goldByKarat.entries.toList()..sort((a, b) => b.key.purityFraction.compareTo(a.key.purityFraction)))
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(8)),
                      child: MoneyText(
                        '${e.key.label}: ${_trimmedQuantity(e.value)}g',
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.textDim, fontWeight: FontWeight.w600),
                        maskLength: 10,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (goldByKarat.isNotEmpty && silverTotal > 0) const SizedBox(height: 10),
          if (silverTotal > 0)
            Row(
              children: [
                AppIcon.silverBar(size: 18),
                const SizedBox(width: 8),
                MoneyText(
                  'Silver — total ${_trimmedQuantity(silverTotal)}g',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maskLength: 16,
                ),
              ],
            ),
        ],
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
    final quantityLabel = _quantityLabel(asset);

    final theme = Theme.of(context);
    final colors = context.appColors;
    final (icon, tint) = _iconFor(category, asset.symbolOrCurrency, asset.vehicleType, colors);

    double? gainLossUsd;
    double? gainLossEgp;
    double? gainLossPct;
    final purchasePrice = asset.purchasePrice;
    final purchaseCurrency = asset.purchaseCurrency;
    if (value != null && purchasePrice != null && purchaseCurrency != null) {
      final purchasePriceUsd = prices[purchaseCurrency];
      if (purchasePriceUsd != null && purchasePrice > 0) {
        final purchaseTotalUsd = purchasePrice * purchasePriceUsd;
        gainLossUsd = value - purchaseTotalUsd;
        gainLossPct = gainLossUsd / purchaseTotalUsd * 100;
        gainLossEgp = usdToEgpRate == null ? null : gainLossUsd * usdToEgpRate;
      }
    }

    return Dismissible(
      key: ValueKey(asset.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDeleteAsset(context, asset),
      onDismissed: (_) => ref.read(assetRepositoryProvider).delete(asset.id),
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete),
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: hideValues ? Icon(Icons.lock_outline, size: 16, color: colors.textDim) : icon,
                  ),
                  const SizedBox(width: 12),
                  // Both sides are flex-constrained (rather than the
                  // trailing side sizing to its own unbounded natural
                  // width) so a long name can never be starved down to
                  // near-zero by the value column next to it.
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hideValues ? '••••••' : asset.name,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hideValues
                              ? '••••••'
                              : '$categoryLabel · ${assetClass == AssetClass.liquid ? "Liquid" : "Non-liquid"}',
                          style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (quantityLabel != null && !hideValues) ...[
                          const SizedBox(height: 3),
                          MoneyText(
                            quantityLabel,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.textBody),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (value != null)
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          MoneyText(
                            egpValue == null ? '—' : formatEgpWhole(egpValue),
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          MoneyText(
                            formatUsdWhole(value),
                            style: theme.textTheme.labelSmall?.copyWith(color: colors.textDim),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )
                  else
                    const Text('—'),
                ],
              ),
              // Gain/loss gets its own full-width row instead of squeezing
              // into the narrow trailing value column above -- that column
              // is only ~40% of the card's width, nowhere near enough for
              // a string like "-17.5% · -EGP 30,240 · -EGP 602", so it was
              // silently ellipsis-truncated to "-17.5% · -EGP…" and
              // effectively unreadable. Full card width is enough for this
              // to render on one line in the overwhelming majority of
              // cases; on the rare string that's still too long, it wraps
              // to a second line instead of ever truncating, since a
              // number that's cut off is worse than one that takes two
              // lines.
              if (gainLossUsd != null && gainLossPct != null && !hideValues) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: MoneyText(
                    '${gainLossUsd >= 0 ? '+' : ''}${gainLossPct.toStringAsFixed(1)}%'
                    '${gainLossEgp == null ? '' : ' · ${gainLossUsd >= 0 ? '+' : ''}${formatEgpWhole(gainLossEgp)}'}'
                    ' · ${gainLossUsd >= 0 ? '+' : ''}${formatUsdWhole(gainLossUsd)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: gainLossUsd >= 0 ? colors.good : colors.bad,
                      fontWeight: FontWeight.w700,
                    ),
                    maskLength: 10,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDeleteAsset(BuildContext context, Asset asset) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete asset?'),
          content: Text('This removes "${asset.name}" from your net worth. This can\'t be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
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
    case AssetCategory.certificate:
      return (Icon(Icons.workspace_premium_outlined, size: 18, color: colors.gold), colors.gold.withValues(alpha: 0.13));
    case AssetCategory.stock:
      return (Icon(Icons.show_chart, size: 18, color: colors.good), colors.good.withValues(alpha: 0.1));
  }
}

/// Opens a bottom sheet listing every profile (checkmark on the active one)
/// to switch between them, plus shortcuts to add one or manage the list —
/// sits beside the Settings gear since switching profiles is a much more
/// frequent action than editing them.
class _ProfileSwitcherAction extends ConsumerWidget {
  const _ProfileSwitcherAction();

  Future<void> _switchTo(BuildContext context, WidgetRef ref, String id) async {
    await ref.read(settingsRepositoryProvider).setActiveProfileId(id);
    ref.read(activeProfileIdProvider.notifier).state = id;
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _showSwitcher(BuildContext context, WidgetRef ref) async {
    final profiles = await ref.read(profilesStreamProvider.future);
    final activeId = ref.read(activeProfileIdProvider);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(alignment: Alignment.centerLeft, child: Text('Switch profile')),
            ),
            for (final profile in profiles)
              ListTile(
                leading: CircleAvatar(child: Text(profile.name.isEmpty ? '?' : profile.name[0].toUpperCase())),
                title: Text(profile.name),
                trailing: profile.id == activeId ? const Icon(Icons.check) : null,
                onTap: () => _switchTo(sheetContext, ref, profile.id),
              ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Manage profiles'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilesSettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.people_alt_outlined),
      tooltip: 'Switch profile',
      onPressed: () => _showSwitcher(context, ref),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/asset_category.dart';
import '../../../core/providers/core_providers.dart';
import '../../networth/providers/asset_providers.dart';

/// Which [AssetClass] each asset category counts as for the Net Worth
/// tab's liquid/non-liquid split — editable instead of permanently fixed
/// to each category's own built-in default (e.g. a paid-off car someone
/// considers as good as cash).
class AssetClassificationSettingsScreen extends ConsumerWidget {
  const AssetClassificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overrides = ref.watch(assetClassOverridesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Liquid / non-liquid')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Controls which assets count toward "Liquid" vs "Non-liquid" in the Net Worth tab.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                for (final category in AssetCategory.values) ...[
                  if (category != AssetCategory.values.first) const Divider(height: 1),
                  ListTile(
                    title: Text(category.label),
                    trailing: SegmentedButton<AssetClass>(
                      segments: const [
                        ButtonSegment(value: AssetClass.liquid, label: Text('Liquid')),
                        ButtonSegment(value: AssetClass.nonLiquid, label: Text('Non-liquid')),
                      ],
                      selected: {overrides[category] ?? category.defaultClass},
                      onSelectionChanged: (selection) async {
                        await ref
                            .read(settingsRepositoryProvider)
                            .setAssetClassOverride(category, selection.first);
                        ref.invalidate(assetClassOverridesProvider);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

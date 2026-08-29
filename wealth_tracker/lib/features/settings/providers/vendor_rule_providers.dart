import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/vendor_rule_repository.dart';
import '../../ledger/providers/ledger_providers.dart';
import '../../networth/providers/asset_providers.dart' show databaseProvider;
import 'settings_providers.dart' show activeProfileIdProvider;

final vendorRuleRepositoryProvider = Provider<VendorRuleRepository>((ref) {
  return VendorRuleRepository(ref.watch(databaseProvider), ref.watch(activeProfileIdProvider));
});

final vendorRulesStreamProvider = StreamProvider<List<VendorRule>>((ref) {
  return ref.watch(vendorRuleRepositoryProvider).watchAll();
});

/// One-time bootstrap for the vendor rule the user already told us about
/// directly ("Breadfast is recorded in dad ledger"): if no rules exist yet
/// and a counterparty whose name contains "dad" exists, seed that mapping
/// automatically so SMS capture works without a manual setup step. Runs
/// once per app launch; watched from the root shell like the other
/// launch-time providers.
final vendorRuleSeedProvider = FutureProvider<void>((ref) async {
  final rules = await ref.read(vendorRulesStreamProvider.future);
  if (rules.isNotEmpty) return;

  final counterparties = await ref.read(counterpartiesStreamProvider.future);
  Counterparty? dad;
  for (final c in counterparties) {
    if (c.name.toLowerCase().contains('dad')) {
      dad = c;
      break;
    }
  }
  if (dad == null) return;

  await ref.read(vendorRuleRepositoryProvider).addRule(
        vendorPattern: 'Breadfast',
        counterpartyId: dad.id,
        category: 'Breadfast',
      );
});

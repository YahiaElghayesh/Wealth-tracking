import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/bank_repository.dart';
import '../../../data/repositories/sms_rule_repository.dart';
import '../../networth/providers/asset_providers.dart' show databaseProvider;
import 'settings_providers.dart' show activeProfileIdProvider;

final bankRepositoryProvider = Provider<BankRepository>((ref) {
  return BankRepository(
    ref.watch(databaseProvider),
    ref.watch(activeProfileIdProvider),
  );
});

final banksStreamProvider = StreamProvider<List<Bank>>((ref) {
  return ref.watch(bankRepositoryProvider).watchAll();
});

final smsRuleRepositoryProvider = Provider<SmsRuleRepository>((ref) {
  return SmsRuleRepository(
    ref.watch(databaseProvider),
    ref.watch(activeProfileIdProvider),
  );
});

final smsRulesStreamProvider = StreamProvider<List<SmsRule>>((ref) {
  return ref.watch(smsRuleRepositoryProvider).watchAll();
});

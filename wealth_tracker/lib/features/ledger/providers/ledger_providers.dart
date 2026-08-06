import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/ledger_repository.dart';
import '../../networth/providers/asset_providers.dart' show databaseProvider;

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(ref.watch(databaseProvider));
});

final counterpartiesStreamProvider = StreamProvider<List<Counterparty>>((ref) {
  return ref.watch(ledgerRepositoryProvider).watchCounterparties();
});

final transactionsStreamProvider =
    StreamProvider.family<List<LedgerTransaction>, String>((ref, counterpartyId) {
  return ref.watch(ledgerRepositoryProvider).watchTransactions(counterpartyId);
});

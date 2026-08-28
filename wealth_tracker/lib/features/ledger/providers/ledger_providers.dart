import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/ledger_category_repository.dart';
import '../../../data/repositories/ledger_repository.dart';
import '../../networth/providers/asset_providers.dart' show databaseProvider;

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(ref.watch(databaseProvider));
});

final ledgerCategoryRepositoryProvider = Provider<LedgerCategoryRepository>((ref) {
  return LedgerCategoryRepository(ref.watch(databaseProvider));
});

final ledgerCategoriesStreamProvider = StreamProvider<List<LedgerCategory>>((ref) {
  return ref.watch(ledgerCategoryRepositoryProvider).watchAll();
});

final counterpartiesStreamProvider = StreamProvider<List<Counterparty>>((ref) {
  return ref.watch(ledgerRepositoryProvider).watchCounterparties();
});

final transactionsStreamProvider =
    StreamProvider.family<List<LedgerTransaction>, String>((ref, counterpartyId) {
  return ref.watch(ledgerRepositoryProvider).watchTransactions(counterpartyId);
});

/// Every ledger transaction across every counterparty — feeds the
/// calculator's "sum of all ledgers" figure.
final allTransactionsStreamProvider = StreamProvider<List<LedgerTransaction>>((ref) {
  return ref.watch(ledgerRepositoryProvider).watchAllTransactions();
});

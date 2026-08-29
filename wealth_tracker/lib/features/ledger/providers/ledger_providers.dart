import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/ledger_category_repository.dart';
import '../../../data/repositories/ledger_repository.dart';
import '../../networth/providers/asset_providers.dart' show databaseProvider;
import '../../settings/providers/settings_providers.dart' show activeProfileIdProvider;

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(ref.watch(databaseProvider), ref.watch(activeProfileIdProvider));
});

final ledgerCategoryRepositoryProvider = Provider<LedgerCategoryRepository>((ref) {
  return LedgerCategoryRepository(ref.watch(databaseProvider), ref.watch(activeProfileIdProvider));
});

final ledgerCategoriesStreamProvider = StreamProvider<List<LedgerCategory>>((ref) {
  return ref.watch(ledgerCategoryRepositoryProvider).watchAll();
});

final counterpartiesStreamProvider = StreamProvider<List<Counterparty>>((ref) {
  return ref.watch(ledgerRepositoryProvider).watchCounterparties();
});

/// Ledgers opted into Statistics -- a derived filter rather than changing
/// [counterpartiesStreamProvider] itself, since that stream is also
/// consumed unfiltered by the Ledger tab's own list, SMS vendor rules, and
/// widget sync, all of which must keep seeing every ledger regardless of
/// this flag.
final statisticsCounterpartiesProvider = Provider<AsyncValue<List<Counterparty>>>((ref) {
  return ref.watch(counterpartiesStreamProvider).whenData(
        (list) => list.where((c) => c.includeInStatistics).toList(),
      );
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/returns_repository.dart';
import '../../networth/providers/asset_providers.dart' show databaseProvider;
import '../../settings/providers/settings_providers.dart'
    show activeProfileIdProvider;

final returnsRepositoryProvider = Provider<ReturnsRepository>((ref) {
  return ReturnsRepository(
    ref.watch(databaseProvider),
    ref.watch(activeProfileIdProvider),
  );
});

final returnsStreamProvider = StreamProvider<List<Return>>((ref) {
  return ref.watch(returnsRepositoryProvider).watchAll();
});

/// [returnsStreamProvider] filtered to what's still pending -- everything
/// with no [Return.receivedAt] yet, oldest return first (the one waiting
/// longest is the one most worth following up on).
final pendingReturnsProvider = Provider<AsyncValue<List<Return>>>((ref) {
  return ref
      .watch(returnsStreamProvider)
      .whenData(
        (list) =>
            list.where((r) => r.receivedAt == null).toList()
              ..sort((a, b) => a.returnDate.compareTo(b.returnDate)),
      );
});

/// [returnsStreamProvider] filtered to what's already been received, most
/// recently received first.
final returnsHistoryProvider = Provider<AsyncValue<List<Return>>>((ref) {
  return ref
      .watch(returnsStreamProvider)
      .whenData(
        (list) =>
            list.where((r) => r.receivedAt != null).toList()
              ..sort((a, b) => b.receivedAt!.compareTo(a.receivedAt!)),
      );
});

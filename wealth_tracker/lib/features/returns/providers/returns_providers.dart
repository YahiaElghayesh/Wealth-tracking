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
/// with no [Return.receivedAt] yet, oldest first (the one waiting longest
/// is the one most worth following up on). "Oldest" falls back to
/// [Return.createdAt] when [Return.requestedAt] isn't set -- both are
/// optional now, but createdAt never is.
final pendingReturnsProvider = Provider<AsyncValue<List<Return>>>((ref) {
  return ref
      .watch(returnsStreamProvider)
      .whenData(
        (list) =>
            list.where((r) => r.receivedAt == null).toList()..sort(
              (a, b) => (a.requestedAt ?? a.createdAt).compareTo(
                b.requestedAt ?? b.createdAt,
              ),
            ),
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

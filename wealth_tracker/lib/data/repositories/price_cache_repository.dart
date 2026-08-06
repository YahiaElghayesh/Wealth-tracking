import '../db/database.dart';

class PriceCacheRepository {
  PriceCacheRepository(this._db);

  final AppDatabase _db;

  Future<Map<String, double>> loadAll() async {
    final rows = await _db.select(_db.priceCache).get();
    return {for (final row in rows) row.symbol: row.priceUsd};
  }

  Future<void> upsertAll(Map<String, double> pricesUsd) async {
    if (pricesUsd.isEmpty) return;
    final now = DateTime.now();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.priceCache,
        [
          for (final entry in pricesUsd.entries)
            PriceCacheCompanion.insert(
              symbol: entry.key,
              priceUsd: entry.value,
              fetchedAt: now,
            ),
        ],
      );
    });
  }
}

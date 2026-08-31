import 'stockanalysis_price_provider.dart';
import 'yahoo_finance_price_provider.dart';

/// Merges stock search results from every configured source rather than
/// leaning on a single one -- Yahoo Finance and stockanalysis.com each
/// carry names the other doesn't (see [StockAnalysisPriceProvider]'s doc
/// comment for why), so combining and ranking both together, instead of
/// picking one as "the" source, is what actually surfaces the exact match
/// a user typing a normal ticker (e.g. "COMI", "TMGH") expects to see
/// first.
class StockSearchAggregator {
  StockSearchAggregator({required this.yahoo, required this.stockAnalysis});

  final YahooFinancePriceProvider yahoo;
  final StockAnalysisPriceProvider stockAnalysis;

  Future<List<StockSearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final results = await Future.wait([yahoo.searchStocks(trimmed), stockAnalysis.searchStocks(trimmed)]);
    return _rankedForQuery([...results[0], ...results[1]], trimmed);
  }

  /// Same relevance ordering [YahooFinancePriceProvider] applies to its own
  /// results, just extended to a symbol shape that can carry an
  /// exchange/ticker prefix (`SA:sy:egx/comi`) as well as Yahoo's plain
  /// suffix form (`COMI.CA`).
  List<StockSearchResult> _rankedForQuery(List<StockSearchResult> results, String query) {
    final normalizedQuery = query.toUpperCase().replaceAll(' ', '');
    int rank(StockSearchResult r) {
      final bareSymbol = _bareSymbol(r.symbol);
      if (bareSymbol == normalizedQuery) return 0;
      if (bareSymbol.startsWith(normalizedQuery)) return 1;
      if (normalizedQuery.length >= 3 && r.name.toUpperCase().replaceAll(' ', '').contains(normalizedQuery)) {
        return 2;
      }
      return 3;
    }

    final indexed = results.asMap().entries.toList()
      ..sort((a, b) {
        final rankCompare = rank(a.value).compareTo(rank(b.value));
        return rankCompare != 0 ? rankCompare : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }

  String _bareSymbol(String symbol) {
    final noCaret = symbol.replaceAll('^', '');
    final afterColon = noCaret.split(':').last;
    final afterSlash = afterColon.split('/').last;
    return afterSlash.split('.').first.toUpperCase();
  }
}

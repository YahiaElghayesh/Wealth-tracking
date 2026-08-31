import 'stockanalysis_price_provider.dart';
import 'yahoo_finance_price_provider.dart';

/// Merges stock search results from every configured source rather than
/// leaning on a single one -- Yahoo Finance and stockanalysis.com each
/// carry names the other doesn't (see [StockAnalysisPriceProvider]'s doc
/// comment for why), so combining and ranking both together, instead of
/// picking one as "the" source, is what actually surfaces the exact match
/// a user typing a normal ticker (e.g. "COMI", "TMGH") expects to see
/// first.
///
/// stockanalysis.com's search turned out, once tested against real
/// queries, not to be a real relevance search at all -- querying "EGX30"
/// returned dozens of unrelated EGX-listed companies (and even an
/// unrelated Singapore-listed one whose own ticker happens to be "EGX"),
/// apparently matching on any substring hit anywhere in its internal
/// symbol rather than ranking by actual relevance. Its results are only
/// trustworthy as *exact or prefix ticker matches* -- [search] filters
/// out everything looser before merging, so a stockanalysis.com result
/// only ever appears when it's a real answer to what was typed, not noise
/// padding out the list.
class StockSearchAggregator {
  StockSearchAggregator({required this.yahoo, required this.stockAnalysis});

  final YahooFinancePriceProvider yahoo;
  final StockAnalysisPriceProvider stockAnalysis;

  /// Results beyond this are dropped after ranking -- a long tail of
  /// low-relevance matches is worse than useless in a dropdown; it buries
  /// the answer the user actually wants under names they don't recognize.
  static const _maxResults = 10;

  Future<List<StockSearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final results = await Future.wait([yahoo.searchStocks(trimmed), stockAnalysis.searchStocks(trimmed)]);
    final yahooResults = results[0];
    final trustedStockAnalysisResults = results[1].where((r) => _rank(r, trimmed) <= 1).toList();

    final combined = _rankedForQuery([...yahooResults, ...trustedStockAnalysisResults], trimmed);
    return combined.take(_maxResults).toList();
  }

  /// Same relevance ordering [YahooFinancePriceProvider] applies to its own
  /// results, just extended to a symbol shape that can carry an
  /// exchange/ticker prefix (`SA:sy:egx/comi`) as well as Yahoo's plain
  /// suffix form (`COMI.CA`).
  List<StockSearchResult> _rankedForQuery(List<StockSearchResult> results, String query) {
    final indexed = results.asMap().entries.toList()
      ..sort((a, b) {
        final rankCompare = _rank(a.value, query).compareTo(_rank(b.value, query));
        return rankCompare != 0 ? rankCompare : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }

  int _rank(StockSearchResult r, String query) {
    final normalizedQuery = query.toUpperCase().replaceAll(' ', '');
    final bareSymbol = _bareSymbol(r.symbol);
    if (bareSymbol == normalizedQuery) return 0;
    if (bareSymbol.startsWith(normalizedQuery)) return 1;
    if (normalizedQuery.length >= 3 && r.name.toUpperCase().replaceAll(' ', '').contains(normalizedQuery)) {
      return 2;
    }
    return 3;
  }

  String _bareSymbol(String symbol) {
    final noCaret = symbol.replaceAll('^', '');
    final afterColon = noCaret.split(':').last;
    final afterSlash = afterColon.split('/').last;
    return afterSlash.split('.').first.toUpperCase();
  }
}

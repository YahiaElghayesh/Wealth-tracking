import 'package:home_widget/home_widget.dart';

import '../../core/format/money_formatter.dart';
import '../net_worth/net_worth_calculator.dart';

/// Pushes the current net worth summary to the Android home-screen widget.
/// A no-op on platforms without a widget implementation (e.g. Windows) —
/// `home_widget` simply returns false/null there rather than throwing.
class HomeWidgetService {
  static const _providerClassName = 'NetWorthWidgetProvider';

  Future<void> updateNetWorthWidget({
    required NetWorthSummary summary,
    required double? usdToEgpRate,
  }) async {
    await HomeWidget.saveWidgetData<String>('net_worth_total_usd', formatUsd(summary.totalUsd));
    await HomeWidget.saveWidgetData<String>('net_worth_liquid_usd', formatUsd(summary.liquidUsd));
    await HomeWidget.saveWidgetData<String>(
      'net_worth_nonliquid_usd',
      formatUsd(summary.nonLiquidUsd),
    );
    await HomeWidget.saveWidgetData<String>(
      'net_worth_total_egp',
      usdToEgpRate == null ? '' : formatEgp(summary.totalUsd * usdToEgpRate),
    );
    await HomeWidget.saveWidgetData<String>(
      'net_worth_updated_at',
      'Updated ${_formatTimestamp(DateTime.now())}',
    );
    await HomeWidget.updateWidget(androidName: _providerClassName);
  }

  String _formatTimestamp(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
  }
}

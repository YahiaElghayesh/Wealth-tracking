import 'package:home_widget/home_widget.dart';

import '../../core/format/money_formatter.dart';
import '../net_worth/net_worth_calculator.dart';

/// Pushes the current net worth summary to the Android home-screen widget.
/// A no-op on platforms without a widget implementation (e.g. Windows) —
/// `home_widget` simply returns false/null there rather than throwing.
class HomeWidgetService {
  static const _providerClassName = 'NetWorthWidgetProvider';
  static const _quickAddProviderClassName = 'QuickAddLedgerWidgetProvider';

  /// Keys understood by `WidgetBackground.kt` on the native side — keep in
  /// sync with that file.
  static const backgroundPresets = ['default', 'blue', 'purple', 'amber', 'charcoal'];

  Future<String> loadBackgroundPreset() async {
    final preset = await HomeWidget.getWidgetData<String>('widget_background_preset');
    return backgroundPresets.contains(preset) ? preset! : 'default';
  }

  Future<void> setBackgroundPreset(String preset) async {
    await HomeWidget.saveWidgetData<String>('widget_background_preset', preset);
    await HomeWidget.updateWidget(androidName: _providerClassName);
    await HomeWidget.updateWidget(androidName: _quickAddProviderClassName);
  }

  /// Percent, 0 (fully transparent) to 100 (fully opaque). Keep in sync
  /// with `WidgetBackground.kt`'s `DEFAULT_OPACITY_PERCENT`.
  static const defaultBackgroundOpacity = 12;

  Future<int> loadBackgroundOpacity() async {
    final opacity = await HomeWidget.getWidgetData<int>('widget_background_opacity');
    return opacity == null ? defaultBackgroundOpacity : opacity.clamp(0, 100);
  }

  Future<void> setBackgroundOpacity(int percent) async {
    await HomeWidget.saveWidgetData<int>('widget_background_opacity', percent.clamp(0, 100));
    await HomeWidget.updateWidget(androidName: _providerClassName);
    await HomeWidget.updateWidget(androidName: _quickAddProviderClassName);
  }

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

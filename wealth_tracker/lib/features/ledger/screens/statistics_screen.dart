import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/money_formatter.dart';
import '../../../core/models/currency.dart';
import '../../../core/providers/privacy_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hide_values_action.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/settings_action.dart';
import '../../../data/ledger/ledger_calculator.dart';
import '../../networth/providers/asset_providers.dart' show pricesUsdPerUnitProvider;
import '../providers/ledger_providers.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String? _selectedCounterpartyId;

  @override
  Widget build(BuildContext context) {
    final counterpartiesAsync = ref.watch(statisticsCounterpartiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger Statistics'),
        actions: const [HideValuesAction(), SettingsAction()],
      ),
      body: counterpartiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (counterparties) {
          if (counterparties.isEmpty) {
            return const Center(
              child: Text('Add a ledger in the Ledger tab to see statistics.'),
            );
          }

          final selected = counterparties.any((c) => c.id == _selectedCounterpartyId)
              ? _selectedCounterpartyId!
              : counterparties.first.id;

          return Column(
            children: [
              if (counterparties.length > 1)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selected,
                    decoration: const InputDecoration(labelText: 'Ledger'),
                    items: counterparties
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (id) => setState(() => _selectedCounterpartyId = id),
                  ),
                ),
              Expanded(child: _StatisticsBody(counterpartyId: selected)),
            ],
          );
        },
      ),
    );
  }
}

class _StatisticsBody extends ConsumerStatefulWidget {
  const _StatisticsBody({required this.counterpartyId});

  final String counterpartyId;

  @override
  ConsumerState<_StatisticsBody> createState() => _StatisticsBodyState();
}

class _StatisticsBodyState extends ConsumerState<_StatisticsBody> {
  /// The last 12 months, sorted by calendar position (January through
  /// December) rather than by when they actually occurred -- confirmed via
  /// screenshot that a chronological rolling window (oldest of the trailing
  /// 12 first) still read as "out of order" to the user, who wants a plain
  /// Jan-through-Dec reading regardless of which of those months belongs to
  /// this year versus last. This is a picker for "which month(s) to look
  /// at," not a timeline, so re-sorting it away from real time order is
  /// fine here -- unlike the trend chart below, which stays chronological.
  static List<DateTime> _recentMonths() {
    final now = DateTime.now();
    final months = [for (var i = 11; i >= 0; i--) DateTime(now.year, now.month - i)];
    months.sort((a, b) => a.month.compareTo(b.month));
    return months;
  }

  late Set<DateTime> _selectedMonths = {DateTime(DateTime.now().year, DateTime.now().month)};

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider(widget.counterpartyId));
    final prices = ref.watch(pricesUsdPerUnitProvider);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(child: Text('No entries yet.'));
        }

        final trend = monthlySpendTrend(transactions, prices, months: 12);
        final categoryTotals = categoryTotalsForMonths(transactions, _selectedMonths, prices);
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spend by month', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(height: 260, child: _MonthlyTrendChart(trend: trend)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('By category', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recentMonths().map((month) {
                        final selected = _selectedMonths.any(
                          (m) => m.year == month.year && m.month == month.month,
                        );
                        return FilterChip(
                          label: Text(DateFormat.MMM().format(month)),
                          selected: selected,
                          onSelected: (isSelected) {
                            setState(() {
                              if (isSelected) {
                                _selectedMonths = {..._selectedMonths, month};
                              } else {
                                _selectedMonths = _selectedMonths
                                    .where((m) => !(m.year == month.year && m.month == month.month))
                                    .toSet();
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (sortedCategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No expenses in the selected month(s).'),
                      )
                    else
                      _CategoryPieChart(categories: sortedCategories),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Compact number label rendered inside a bar -- a shortened form (e.g.
/// "1.2K") for larger values, and a bare whole number (no currency code, no
/// decimals) below 1,000, so the label needs as little vertical room as
/// possible once rotated into the bar.
String _shortMoney(double value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 1000000) return '$sign${(abs / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(1)}K';
  return '$sign${abs.round()}';
}

/// A permanently-visible label above a bar, using the same tooltip
/// machinery fl_chart uses for touch — [BarChartGroupData.showingTooltipIndicators]
/// keeps it displayed without requiring a tap.
/// The value label used to sit horizontally above each bar -- fine for one
/// bar in isolation, but with 12 months side by side at only 12dp wide each,
/// horizontal text either overlapped its neighbors or forced them apart.
/// Rotating it 90° and pulling it down (negative margin) into the bar's own
/// column lets it read bottom-to-top inside the space the bar already owns.
BarTouchTooltipData _permanentLabelTooltip(Color onBarTextColor, {required bool hideValues}) {
  return BarTouchTooltipData(
    getTooltipColor: (_) => Colors.transparent,
    tooltipPadding: EdgeInsets.zero,
    tooltipMargin: -8,
    rotateAngle: -90,
    fitInsideVertically: true,
    getTooltipItem: (group, groupIndex, rod, rodIndex) {
      return BarTooltipItem(
        hideValues ? '•••' : _shortMoney(rod.toY),
        TextStyle(color: onBarTextColor, fontWeight: FontWeight.bold, fontSize: 8),
      );
    },
  );
}

class _MonthlyTrendChart extends ConsumerWidget {
  const _MonthlyTrendChart({required this.trend});

  final List<MonthlySpend> trend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideValues = ref.watch(hideValuesProvider);
    final color = Theme.of(context).colorScheme.primary;
    final colors = context.appColors;
    final maxY = trend.map((m) => m.amount).fold(0.0, (a, b) => a > b ? a : b);
    // Less headroom above the tallest bar than before (1.3x -> 1.15x) so
    // the one bar carrying a label actually occupies more of the chart's
    // height, giving the rotated label more real room to sit inside it
    // instead of needing to spill into the empty space above.
    final track = maxY == 0 ? 1.0 : maxY * 1.15;
    // Only the current (last, right-most) month gets a permanent value
    // label -- every month still shows a visible track slot underneath its
    // bar so future/empty months don't read as literal gaps in the chart.
    final currentIndex = trend.length - 1;

    return BarChart(
      BarChartData(
        maxY: track,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat.MMM().format(trend[index].month),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textDim),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(touchTooltipData: _permanentLabelTooltip(Colors.white, hideValues: hideValues)),
        barGroups: [
          for (var i = 0; i < trend.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: trend[i].amount,
                  color: i == currentIndex ? color : color.withValues(alpha: 0.3),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: track,
                    color: colors.surface2,
                  ),
                ),
              ],
              showingTooltipIndicators: i == currentIndex && trend[i].amount > 0 ? [0] : [],
            ),
        ],
      ),
    );
  }
}

/// Category breakdown as a pie chart with a colored legend underneath —
/// the legend carries the readable category name + amount since slice
/// labels alone get illegible once there are more than a few categories.
class _CategoryPieChart extends ConsumerStatefulWidget {
  const _CategoryPieChart({required this.categories});

  final List<MapEntry<String, double>> categories;

  @override
  ConsumerState<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<_CategoryPieChart> {
  static const _palette = [
    Color(0xFF2E7D6B),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFFF8F00),
    Color(0xFFC62828),
    Color(0xFF00838F),
    Color(0xFF9E9D24),
    Color(0xFF4527A0),
    Color(0xFFAD1457),
    Color(0xFF37474F),
  ];

  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final hideValues = ref.watch(hideValuesProvider);
    final categories = widget.categories;
    final total = categories.fold(0.0, (sum, e) => sum + e.value);

    return Column(
      children: [
        // AspectRatio(1) forces a true circle -- PieChart otherwise fills
        // whatever box it's given, which renders as an oval whenever the
        // available width and height don't happen to match. Percentage
        // labels are drawn *outside* the ring by _PieOutsideLabelsPainter
        // rather than as fl_chart's own in-slice `title` -- a label inside
        // a thin, small slice has nowhere to go but stack on top of its
        // neighbors once several categories are small; a label anchored to
        // its own radial position outside the ring stays legible no matter
        // how thin the slice behind it gets.
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions || response?.touchedSection == null) {
                          _touchedIndex = null;
                        } else {
                          _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                        }
                      });
                    },
                  ),
                  sections: [
                    for (var i = 0; i < categories.length; i++)
                      PieChartSectionData(
                        value: categories[i].value,
                        color: _palette[i % _palette.length],
                        radius: i == _touchedIndex ? 58 : 52,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              if (total > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PieOutsideLabelsPainter(
                        categories: categories,
                        total: total,
                        palette: _palette,
                        hideValues: hideValues,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (var i = 0; i < categories.length; i++)
              _LegendEntry(
                color: _palette[i % _palette.length],
                label: categories[i].key,
                amount: categories[i].value,
                percent: total == 0 ? 0 : categories[i].value / total,
                highlighted: i == _touchedIndex,
              ),
          ],
        ),
      ],
    );
  }
}

/// Draws each slice's percentage outside the pie ring, on a short leader
/// line the same color as its slice -- replaces fl_chart's own in-slice
/// `title`, which becomes illegible (labels overlapping each other) once
/// several categories are small. Angle math mirrors fl_chart's own
/// `PieChartPainter` (sections start at 0° = 3 o'clock and sweep clockwise
/// in the same order as [categories], with the same 40px `centerSpaceRadius`
/// and up-to-58px section radius the chart itself uses), so each leader
/// line starts exactly at its slice's outer edge rather than an
/// approximation.
class _PieOutsideLabelsPainter extends CustomPainter {
  _PieOutsideLabelsPainter({
    required this.categories,
    required this.total,
    required this.palette,
    required this.hideValues,
  });

  final List<MapEntry<String, double>> categories;
  final double total;
  final List<Color> palette;
  final bool hideValues;

  static const _ringOuterRadius = 40.0 + 58.0;
  static const _leaderLength = 14.0;
  static const _labelGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    var startAngleDeg = 0.0;

    for (var i = 0; i < categories.length; i++) {
      final fraction = categories[i].value / total;
      final sweepDeg = fraction * 360;
      final midAngleRad = (startAngleDeg + sweepDeg / 2) * math.pi / 180;
      final direction = Offset(math.cos(midAngleRad), math.sin(midAngleRad));
      final color = palette[i % palette.length];

      final innerPoint = center + direction * _ringOuterRadius;
      final outerPoint = center + direction * (_ringOuterRadius + _leaderLength);

      canvas.drawLine(
        innerPoint,
        outerPoint,
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(innerPoint, 2.2, Paint()..color = color);

      final label = hideValues ? '••' : '${fraction * 100 < 1 && fraction > 0 ? '<1' : (fraction * 100).round()}%';
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final onRightHalf = direction.dx >= 0;
      final labelOrigin = onRightHalf
          ? Offset(outerPoint.dx + _labelGap, outerPoint.dy - textPainter.height / 2)
          : Offset(outerPoint.dx - _labelGap - textPainter.width, outerPoint.dy - textPainter.height / 2);
      textPainter.paint(canvas, labelOrigin);

      startAngleDeg += sweepDeg;
    }
  }

  @override
  bool shouldRepaint(covariant _PieOutsideLabelsPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.total != total ||
        oldDelegate.hideValues != hideValues;
  }
}

class _LegendEntry extends ConsumerWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.amount,
    required this.percent,
    required this.highlighted,
  });

  final Color color;
  final String label;
  final double amount;
  final double percent;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideValues = ref.watch(hideValuesProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(hideValues ? '••••••  ' : '$label  ', style: Theme.of(context).textTheme.bodyMedium),
          MoneyText(
            '${formatMoney(amount, defaultCurrency)} (${(percent * 100).toStringAsFixed(0)}%)',
            style: Theme.of(context).textTheme.bodySmall,
            maskLength: 8,
          ),
        ],
      ),
    );
  }
}

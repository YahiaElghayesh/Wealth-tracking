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
import '../../networth/providers/asset_providers.dart'
    show pricesUsdPerUnitProvider;
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

          final selected =
              counterparties.any((c) => c.id == _selectedCounterpartyId)
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
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (id) =>
                        setState(() => _selectedCounterpartyId = id),
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
    final months = [
      for (var i = 11; i >= 0; i--) DateTime(now.year, now.month - i),
    ];
    months.sort((a, b) => a.month.compareTo(b.month));
    return months;
  }

  late Set<DateTime> _selectedMonths = {
    DateTime(DateTime.now().year, DateTime.now().month),
  };

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
      transactionsStreamProvider(widget.counterpartyId),
    );
    final prices = ref.watch(pricesUsdPerUnitProvider);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(child: Text('No entries yet.'));
        }

        final trend = monthlySpendTrend(transactions, prices, months: 12);
        final categoryTotals = categoryTotalsForMonths(
          transactions,
          _selectedMonths,
          prices,
        );
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
                    Text(
                      'Spend by month',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _MonthlyTrendChart(trend: trend),
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
                    Text(
                      'By category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                                    .where(
                                      (m) =>
                                          !(m.year == month.year &&
                                              m.month == month.month),
                                    )
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

/// Plain Flutter bars instead of fl_chart -- an fl_chart `BarChart` only
/// offers a value label via its touch-tooltip machinery, which renders as
/// its own separately-decorated bubble rather than actual paint inside the
/// bar's own rectangle; pinning that bubble in place with negative margins
/// and rotation (the previous approach here) could get it to visually
/// overlap the bar but never to genuinely BE the bar's own fill the way a
/// real inside-the-rectangle label needs to. Building the bars directly
/// sidesteps that entirely: the label is a literal child of the same
/// `Container` that IS the bar, clipped to it, so it can never be anything
/// other than inside.
class _MonthlyTrendChart extends ConsumerWidget {
  const _MonthlyTrendChart({required this.trend});

  final List<MonthlySpend> trend;

  static const _barAreaHeight = 170.0;
  static const _barWidth = 22.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideValues = ref.watch(hideValuesProvider);
    final color = Theme.of(context).colorScheme.primary;
    final colors = context.appColors;
    final maxValue = trend
        .map((m) => m.amount)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _barAreaHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < trend.length; i++)
                Expanded(
                  child: Center(
                    child: _MonthBar(
                      value: trend[i].amount,
                      maxValue: maxValue,
                      areaHeight: _barAreaHeight,
                      width: _barWidth,
                      // Every month with a real value gets the same full
                      // -strength bar color and its own value label, not
                      // just the current (right-most) one -- a muted color
                      // and a hidden number on every past month read as
                      // "no data" even though the bar itself was clearly
                      // tall.
                      barColor: color,
                      trackColor: colors.surface2,
                      hideValues: hideValues,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < trend.length; i++)
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat.MMM().format(trend[i].month),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: colors.textDim),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.value,
    required this.maxValue,
    required this.areaHeight,
    required this.width,
    required this.barColor,
    required this.trackColor,
    required this.hideValues,
  });

  final double value;
  final double maxValue;
  final double areaHeight;
  final double width;
  final Color barColor;
  final Color trackColor;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final rawHeight = maxValue <= 0 ? 0.0 : (value / maxValue) * areaHeight;
    final hasValue = value > 0;
    // Every bar that carries a real value gets a taller floor (44 vs 4) --
    // every one of them paints a label inside itself now, and the label
    // needs real room to sit in regardless of how small its own value
    // happens to be relative to the rest of the trend.
    final showsLabel = hasValue && !hideValues;
    final barHeight =
        (hasValue
                ? rawHeight.clamp(44.0, areaHeight)
                : rawHeight.clamp(4.0, areaHeight))
            .toDouble();

    return SizedBox(
      width: width,
      height: areaHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            child: Container(
              height: barHeight,
              color: barColor,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 4),
              child: showsLabel
                  ? RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        _shortMoney(value),
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    )
                  : (hasValue && hideValues)
                  ? const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        '•••',
                        style: TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    )
                  : null,
            ),
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
                        if (!event.isInterestedForInteractions ||
                            response?.touchedSection == null) {
                          _touchedIndex = null;
                        } else {
                          _touchedIndex =
                              response!.touchedSection!.touchedSectionIndex;
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
  static const _leaderLength = 22.0;
  static const _labelGap = 4.0;

  /// Minimum vertical space kept between two labels' centers on the same
  /// side of the ring -- roughly one label's line-height plus a little
  /// breathing room, so two close-angle slices never print their numbers
  /// on top of each other.
  static const _minLabelGap = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    var startAngleDeg = 0.0;
    final placements = <_PieLabelPlacement>[];

    for (var i = 0; i < categories.length; i++) {
      final fraction = categories[i].value / total;
      final sweepDeg = fraction * 360;
      final midAngleRad = (startAngleDeg + sweepDeg / 2) * math.pi / 180;
      final direction = Offset(math.cos(midAngleRad), math.sin(midAngleRad));
      final color = palette[i % palette.length];

      final innerPoint = center + direction * _ringOuterRadius;
      final elbow = center + direction * (_ringOuterRadius + _leaderLength);

      final label = hideValues
          ? '••'
          : '${fraction * 100 < 1 && fraction > 0 ? '<1' : (fraction * 100).round()}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      placements.add(
        _PieLabelPlacement(
          innerPoint: innerPoint,
          color: color,
          textPainter: textPainter,
          onRightHalf: direction.dx >= 0,
          anchorX: elbow.dx,
          anchorY: elbow.dy,
        ),
      );

      startAngleDeg += sweepDeg;
    }

    // Decluttered independently per side of the ring -- a label's *x*
    // never moves (it stays on its own slice's radial line), only *y*
    // shifts when two close-angle slices on the same side would otherwise
    // stack their numbers on top of each other. The leader line drawn
    // below then naturally runs longer for whichever labels got pushed,
    // instead of every leader staying a fixed, sometimes-colliding length.
    _declutter(placements.where((p) => p.onRightHalf).toList());
    _declutter(placements.where((p) => !p.onRightHalf).toList());

    for (final p in placements) {
      final outerPoint = Offset(p.anchorX, p.anchorY);
      canvas.drawLine(
        p.innerPoint,
        outerPoint,
        Paint()
          ..color = p.color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(p.innerPoint, 2.2, Paint()..color = p.color);

      final labelOrigin = p.onRightHalf
          ? Offset(
              outerPoint.dx + _labelGap,
              outerPoint.dy - p.textPainter.height / 2,
            )
          : Offset(
              outerPoint.dx - _labelGap - p.textPainter.width,
              outerPoint.dy - p.textPainter.height / 2,
            );
      p.textPainter.paint(canvas, labelOrigin);
    }
  }

  /// Spreads out labels on one side of the ring just enough that no two
  /// sit within [_minLabelGap] of each other vertically -- a forward pass
  /// pushes later (lower) labels down, then a backward pass pulls earlier
  /// (upper) ones back up as far as the gap allows, so a tight cluster of
  /// small slices ends up centered on its natural position instead of
  /// drifting entirely downward.
  void _declutter(List<_PieLabelPlacement> side) {
    if (side.length < 2) return;
    side.sort((a, b) => a.anchorY.compareTo(b.anchorY));
    for (var i = 1; i < side.length; i++) {
      final minY = side[i - 1].anchorY + _minLabelGap;
      if (side[i].anchorY < minY) side[i].anchorY = minY;
    }
    for (var i = side.length - 2; i >= 0; i--) {
      final maxY = side[i + 1].anchorY - _minLabelGap;
      if (side[i].anchorY > maxY) side[i].anchorY = maxY;
    }
  }

  @override
  bool shouldRepaint(covariant _PieOutsideLabelsPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.total != total ||
        oldDelegate.hideValues != hideValues;
  }
}

/// One slice's resolved outside-label position -- [anchorX]/[anchorY] start
/// as the slice's own radial point but [anchorY] may be nudged by
/// [_PieOutsideLabelsPainter._declutter] to avoid overlapping a neighbor.
class _PieLabelPlacement {
  _PieLabelPlacement({
    required this.innerPoint,
    required this.color,
    required this.textPainter,
    required this.onRightHalf,
    required this.anchorX,
    required this.anchorY,
  });

  final Offset innerPoint;
  final Color color;
  final TextPainter textPainter;
  final bool onRightHalf;
  final double anchorX;
  double anchorY;
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
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            hideValues ? '••••••  ' : '$label  ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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

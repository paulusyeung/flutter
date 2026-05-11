import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_chart_series.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/dashboard/widgets/delta_chip.dart';

/// "Revenue" hero chart: line + gradient area, window segmented control,
/// togglable series legend. Matches the v2 mockup at `screens.jsx:240–266`.
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.vm, required this.formatter});

  final DashboardViewModel vm;
  final Formatter formatter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final series = vm.chart.data;
    final currencyKey = vm.filter.currencyId == kDashboardCurrencyAll
        ? null
        : vm.filter.currencyId.toString();
    final isMixed = currencyKey == null && (series?.byCurrency.length ?? 0) > 1;
    final byCurrency = _selectCurrency(series, currencyKey);

    final pointsBySeries = <ChartSeriesId, List<DashboardChartPoint>>{
      ChartSeriesId.invoices: byCurrency?.invoices ?? const [],
      ChartSeriesId.payments: byCurrency?.payments ?? const [],
      ChartSeriesId.outstanding: byCurrency?.outstanding ?? const [],
      ChartSeriesId.expenses: byCurrency?.expenses ?? const [],
    };
    final visibleEmpty = vm.visibleChartSeries.every(
      (id) => (pointsBySeries[id] ?? const []).isEmpty,
    );

    final periodTotal = _sumVisible(pointsBySeries, vm.visibleChartSeries);
    final heroValueText = formatter.money(periodTotal);

    return DashboardCardShell(
      padding: const EdgeInsets.symmetric(
        horizontal: InSpacing.lg,
        vertical: InSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, tokens),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                heroValueText,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: tokens.ink,
                  fontFamilyFallback: const ['Menlo', 'Consolas'],
                ),
              ),
              const SizedBox(width: 12),
              const DeltaChip(
                percent: null,
                goodDirection: GoodDirection.up,
                suffix: 'vs prior',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _legend(context, tokens),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 2.4,
            child: isMixed
                ? _disabledOverlay(tokens, 'Pick a currency to view the chart.')
                : (vm.chart.isLoading && series == null
                      ? _loadingSkeleton(tokens)
                      : (visibleEmpty
                            ? _disabledOverlay(
                                tokens,
                                'No data for this period.',
                              )
                            : _chart(context, tokens, pointsBySeries))),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, InTheme tokens) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Revenue',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink,
                ),
              ),
              Text(
                'Last ${vm.filter.chartWindow.label} · paid invoices only',
                style: TextStyle(fontSize: 11.5, color: tokens.ink3),
              ),
            ],
          ),
        ),
        _windowSegmented(tokens),
      ],
    );
  }

  Widget _windowSegmented(InTheme tokens) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final w in ChartWindow.values)
          GestureDetector(
            onTap: () => vm.setChartWindow(w),
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: w == vm.filter.chartWindow
                    ? tokens.surfaceAlt
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: w == vm.filter.chartWindow
                      ? tokens.border
                      : Colors.transparent,
                ),
              ),
              child: Text(
                w.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: w == vm.filter.chartWindow
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: w == vm.filter.chartWindow ? tokens.ink : tokens.ink3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _legend(BuildContext context, InTheme tokens) {
    final chips = <Widget>[
      _legendChip('Invoices', tokens.accent, ChartSeriesId.invoices),
      _legendChip('Payments', tokens.paid, ChartSeriesId.payments),
      _legendChip('Outstanding', tokens.overdue, ChartSeriesId.outstanding),
      _legendChip('Expenses', tokens.ink3, ChartSeriesId.expenses),
    ];
    return Wrap(spacing: 12, runSpacing: 4, children: chips);
  }

  Widget _legendChip(String label, Color color, ChartSeriesId id) {
    return Builder(
      builder: (context) {
        final tokens = context.inTheme;
        final active = vm.visibleChartSeries.contains(id);
        return GestureDetector(
          onTap: () => vm.toggleChartSeries(id),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? color : color.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: active ? tokens.ink2 : tokens.ink3,
                  decoration: active ? null : TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _loadingSkeleton(InTheme tokens) => Container(
    decoration: BoxDecoration(
      color: tokens.surfaceAlt,
      borderRadius: BorderRadius.circular(InRadii.r1),
    ),
  );

  Widget _disabledOverlay(InTheme tokens, String message) => Container(
    decoration: BoxDecoration(
      color: tokens.surfaceAlt,
      borderRadius: BorderRadius.circular(InRadii.r1),
    ),
    alignment: Alignment.center,
    child: Text(message, style: TextStyle(color: tokens.ink3, fontSize: 12)),
  );

  Widget _chart(
    BuildContext context,
    InTheme tokens,
    Map<ChartSeriesId, List<DashboardChartPoint>> pointsBySeries,
  ) {
    final visible = vm.visibleChartSeries;
    final bars = <LineChartBarData>[];
    double maxY = 0;
    for (final id in ChartSeriesId.values) {
      if (!visible.contains(id)) continue;
      final pts = pointsBySeries[id] ?? const [];
      if (pts.isEmpty) continue;
      final color = _colorFor(tokens, id);
      final spots = <FlSpot>[];
      for (var i = 0; i < pts.length; i++) {
        final v = pts[i].total.toDouble();
        if (v > maxY) maxY = v;
        spots.add(FlSpot(i.toDouble(), v));
      }
      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: id == _primaryVisible(visible)
              ? BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.18),
                      color.withValues(alpha: 0),
                    ],
                  ),
                )
              : null,
        ),
      );
    }
    if (bars.isEmpty) {
      return _disabledOverlay(tokens, 'No series selected.');
    }
    return LineChart(
      LineChartData(
        lineBarsData: bars,
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: tokens.border,
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                formatter.money(
                  Decimal.parse(value.toStringAsFixed(0)),
                  compact: true,
                ),
                style: TextStyle(fontSize: 10, color: tokens.ink3),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                final pts =
                    pointsBySeries[_primaryVisible(visible)] ?? const [];
                if (idx < 0 || idx >= pts.length) {
                  return const SizedBox.shrink();
                }
                final d = pts[idx].date;
                if (d == null) return const SizedBox.shrink();
                return Text(
                  '${d.month}/${d.day}',
                  style: TextStyle(fontSize: 10, color: tokens.ink3),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => tokens.ink,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  formatter.money(Decimal.parse(spot.y.toStringAsFixed(2))),
                  TextStyle(color: tokens.surface, fontSize: 11.5),
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
    );
  }

  Color _colorFor(InTheme tokens, ChartSeriesId id) {
    switch (id) {
      case ChartSeriesId.invoices:
        return tokens.accent;
      case ChartSeriesId.payments:
        return tokens.paid;
      case ChartSeriesId.outstanding:
        return tokens.overdue;
      case ChartSeriesId.expenses:
        return tokens.ink3;
    }
  }

  ChartSeriesId _primaryVisible(Set<ChartSeriesId> visible) {
    for (final id in ChartSeriesId.values) {
      if (visible.contains(id)) return id;
    }
    return ChartSeriesId.invoices;
  }

  DashboardCurrencyChart? _selectCurrency(
    DashboardChartSeries? series,
    String? key,
  ) {
    if (series == null || series.isEmpty) return null;
    if (key != null) return series.byCurrency[key];
    return series.byCurrency.values.first;
  }

  Decimal _sumVisible(
    Map<ChartSeriesId, List<DashboardChartPoint>> pointsBySeries,
    Set<ChartSeriesId> visible,
  ) {
    var total = Decimal.zero;
    for (final id in visible) {
      final pts = pointsBySeries[id] ?? const <DashboardChartPoint>[];
      for (final p in pts) {
        total += p.total;
      }
    }
    return total;
  }
}

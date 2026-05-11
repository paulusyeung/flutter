import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 80×22 bar sparkline. Bars use opacity-by-magnitude (0.25 base, 1.0 max),
/// matching the v2 mockup's `<Spark>` component. Pure visual indicator —
/// no axes, no labels, no per-bar tooltips.
class KpiSparkline extends StatelessWidget {
  const KpiSparkline({
    super.key,
    required this.values,
    required this.color,
    this.width = 80,
    this.height = 22,
  });

  final List<double> values;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(width: width, height: height);
    }
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1.0 : maxVal;
    return SizedBox(
      width: width,
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          maxY: safeMax,
          minY: 0,
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    color: color.withValues(
                      alpha: 0.25 + 0.75 * (values[i] / safeMax),
                    ),
                    width: 6,
                    borderRadius: const BorderRadius.all(Radius.circular(1)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

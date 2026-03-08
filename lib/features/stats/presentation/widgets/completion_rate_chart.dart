import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompletionRateChart extends StatelessWidget {
  const CompletionRateChart({
    super.key,
    required this.weeklyRates,
  });

  /// List of (weekStart, rate) tuples, oldest first.
  final List<({DateTime weekStart, double rate})> weeklyRates;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelColor = cs.onSurfaceVariant;

    final spots = weeklyRates.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.rate * 100);
    }).toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          clipData: const FlClipData.all(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  Theme.of(context).colorScheme.surfaceContainer,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toInt()}%',
                        TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ))
                  .toList(),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (weeklyRates.length / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= weeklyRates.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('MMM d')
                          .format(weeklyRates[idx].weekStart),
                      style:
                          TextStyle(fontSize: 9, color: labelColor),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 25,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${value.toInt()}%',
                    style: TextStyle(fontSize: 9, color: labelColor),
                  ),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: labelColor.withValues(alpha:0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: cs.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.primary.withValues(alpha:0.25),
                    cs.primary.withValues(alpha:0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

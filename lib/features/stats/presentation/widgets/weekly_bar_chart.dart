import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.completionsPerDay,
    required this.maxHabits,
  });

  /// 7 values: index 0 = 6 days ago, index 6 = today.
  final List<int> completionsPerDay;
  final int maxHabits;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
      child: BarChart(
        BarChartData(
          maxY: (maxHabits == 0 ? 1 : maxHabits).toDouble(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF2A2A3E) : Colors.white,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.toInt()} done',
                TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final dayIndex = value.toInt();
                  // 0 = 6 days ago … 6 = today
                  final weekdayOffset =
                      (DateTime.now().weekday - 1 - (6 - dayIndex)) % 7;
                  final label = AppConstants.dayLabels[
                      weekdayOffset.clamp(0, 6)];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 11, color: labelColor),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxHabits <= 4 ? 1 : (maxHabits / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 11, color: labelColor),
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
            horizontalInterval:
                maxHabits <= 4 ? 1 : (maxHabits / 4).ceilToDouble(),
            getDrawingHorizontalLine: (value) => FlLine(
              color: labelColor.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            final isToday = i == 6;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: completionsPerDay[i].toDouble(),
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: isToday
                        ? [AppColors.secondary, AppColors.primary]
                        : [
                            AppColors.primary.withOpacity(0.7),
                            AppColors.primary,
                          ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

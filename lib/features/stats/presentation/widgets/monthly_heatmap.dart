import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class MonthlyHeatmap extends StatelessWidget {
  const MonthlyHeatmap({
    super.key,
    required this.year,
    required this.month,
    required this.completionRatios,
    this.onDayTap,
  });

  final int year;
  final int month;
  final Map<DateTime, double> completionRatios;
  final void Function(DateTime date)? onDayTap;

  Color _cellColor(double? ratio, bool isDark) {
    if (ratio == null || ratio == 0) {
      return isDark ? AppColors.heatmapDark0 : AppColors.heatmap0;
    }
    if (ratio <= 0.25) return isDark ? AppColors.heatmapDark1 : AppColors.heatmap1;
    if (ratio <= 0.50) return isDark ? AppColors.heatmapDark2 : AppColors.heatmap2;
    if (ratio <= 0.75) return isDark ? AppColors.heatmapDark3 : AppColors.heatmap3;
    return isDark ? AppColors.heatmapDark4 : AppColors.heatmap4;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstDay = DateTime(year, month, 1);
    // 0=Mon…6=Sun offset (weekday 1=Mon in DateTime)
    final startOffset = firstDay.weekday - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month header
        Text(
          DateFormat('MMMM yyyy').format(firstDay),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // Day labels
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
            return Expanded(
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 10),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < startOffset) {
              return const SizedBox.shrink();
            }
            final dayNum = index - startOffset + 1;
            final date = DateTime(year, month, dayNum);
            final ratio = completionRatios[DateTime.utc(year, month, dayNum)];
            final isToday = _isToday(date);
            final isInFuture = date.isAfter(DateTime.now());

            return GestureDetector(
              onTap: isInFuture ? null : () => onDayTap?.call(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isInFuture
                      ? Colors.transparent
                      : _cellColor(ratio, isDark),
                  borderRadius: BorderRadius.circular(4),
                  border: isToday
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2)
                      : null,
                ),
                child: isInFuture
                    ? null
                    : Center(
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 9,
                            color: (ratio != null && ratio > 0.5)
                                ? Colors.white
                                : isDark
                                    ? Colors.white54
                                    : Colors.black54,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DailyProgressRing extends StatelessWidget {
  const DailyProgressRing({
    super.key,
    required this.completed,
    required this.total,
    this.size = 100,
    this.strokeWidth = 10,
  });

  final int completed;
  final int total;
  final double size;
  final double strokeWidth;

  double get _progress => total == 0 ? 0 : completed / total;

  @override
  Widget build(BuildContext context) {
    final isDone = total > 0 && completed >= total;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: _progress,
          trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          progressColor: isDone ? AppColors.success : AppColors.primary,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$completed',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isDone ? AppColors.success : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                ),
                Text(
                  'of $total',
                  style:
                      Theme.of(context).textTheme.labelSmall?.copyWith(height: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}

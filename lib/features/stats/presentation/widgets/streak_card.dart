import 'package:flutter/material.dart';

/// M3-styled streak card — uses primaryContainer for the tonal fill,
/// which automatically pairs with the app's M3 ColorScheme.
class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    this.habitName,
  });

  final int currentStreak;
  final int bestStreak;
  final String? habitName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (habitName != null) ...[
            Text(
              habitName!,
              style: tt.labelMedium?.copyWith(
                color: cs.onPrimaryContainer.withValues(alpha: 0.75),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          IntrinsicHeight(
            child: Row(
              children: [
                _StreakStat(
                  icon: '🔥',
                  label: 'Current streak',
                  value: currentStreak,
                  fgColor: cs.onPrimaryContainer,
                  tt: tt,
                ),
                const SizedBox(width: 8),
                VerticalDivider(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.2),
                  thickness: 1,
                  width: 16,
                ),
                const SizedBox(width: 8),
                _StreakStat(
                  icon: '🏆',
                  label: 'Best streak',
                  value: bestStreak,
                  fgColor: cs.onPrimaryContainer,
                  tt: tt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.fgColor,
    required this.tt,
  });

  final String icon;
  final String label;
  final int value;
  final Color fgColor;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            '$value ${value == 1 ? 'day' : 'days'}',
            style: tt.headlineSmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: fgColor.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

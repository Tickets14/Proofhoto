import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (habitName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                habitName!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            children: [
              _StreakStat(
                icon: '🔥',
                label: 'Current streak',
                value: currentStreak,
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 60, color: Colors.white24),
              const SizedBox(width: 8),
              _StreakStat(
                icon: '🏆',
                label: 'Best streak',
                value: bestStreak,
              ),
            ],
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
  });

  final String icon;
  final String label;
  final int value;

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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

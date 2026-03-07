import '../../proof/data/models/proof_entry.dart';

/// Computed data for one Mon–Sun review window.
class WeeklyReviewData {
  const WeeklyReviewData({
    required this.weekStart,
    required this.weekEnd,
    required this.totalCompletions,
    required this.totalScheduled,
    required this.completionRate,
    required this.bestDayWeekday,
    required this.bestDayCount,
    required this.streaks,
    required this.highlights,
  });

  /// Monday of the reviewed week (local date, midnight).
  final DateTime weekStart;

  /// Sunday of the reviewed week.
  final DateTime weekEnd;

  /// Number of habit-completions recorded in the week.
  final int totalCompletions;

  /// Total habit-days scheduled across all habits for the week.
  final int totalScheduled;

  /// 0.0–1.0 completion ratio.
  final double completionRate;

  /// 1=Mon…7=Sun day with the most completions. 0 if no activity.
  final int bestDayWeekday;

  /// Number of completions on the best day.
  final int bestDayCount;

  /// Per-habit streak info, sorted by currentStreak descending.
  final List<HabitStreakInfo> streaks;

  /// Up to 5 highlighted proof entries (photos/videos with notes first).
  final List<WeeklyHighlight> highlights;

  bool get hasActivity => totalCompletions > 0;

  int get completionPct => (completionRate * 100).round();

  String get headerEmoji {
    if (completionRate > 0.80) return '🎉';
    if (completionRate >= 0.50) return '💪';
    return '🌱';
  }

  String get motivationalMessage {
    if (!hasActivity) {
      return "Looks like last week was quiet. No worries — today is day one. Let's go!";
    }
    final pct = completionPct;
    if (pct >= 90) {
      return "Unstoppable! You crushed it this week. Keep the momentum going.";
    }
    if (pct >= 70) {
      return "Great consistency! You're building real habits. Push for 100% next week.";
    }
    if (pct >= 50) {
      return "Solid effort! Every proof photo is a step forward. Let's level up.";
    }
    return "Every week is a fresh start. Pick your most important habit and focus there.";
  }
}

class HabitStreakInfo {
  const HabitStreakInfo({
    required this.habitName,
    required this.habitEmoji,
    required this.currentStreak,
    required this.milestoneThisWeek,
  });

  final String habitName;
  final String habitEmoji;

  /// Current streak as of the end of the review week.
  final int currentStreak;

  /// Non-null when a 7-day milestone was achieved during/at the end of this week.
  final int? milestoneThisWeek;
}

class WeeklyHighlight {
  const WeeklyHighlight({
    required this.entry,
    required this.habitEmoji,
    required this.habitName,
    required this.dayLabel,
  });

  final ProofEntry entry;
  final String habitEmoji;
  final String habitName;
  final String dayLabel; // e.g. "Mon", "Tue"
}

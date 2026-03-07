import '../data/models/achievement.dart';
import '../../habits/data/models/habit.dart';
import '../../proof/data/models/proof_entry.dart';
import '../../stats/domain/stats_service.dart';
import '../../../core/utils/app_date_utils.dart';

class AchievementService {
  /// Checks the current state against all badge conditions.
  /// Returns only the newly unlocked [Achievement]s (not yet in [existing]).
  static List<Achievement> checkAll({
    required List<Habit> habits,
    required List<ProofEntry> allEntries,
    required List<Achievement> existing,
    required List<String> usedFreezes,
  }) {
    final newOnes = <Achievement>[];
    final now = DateTime.now().toUtc();
    final activeHabits = habits.where((h) => !h.isArchived).toList();

    bool alreadyEarned(String badgeId, String habitId) =>
        existing.any((a) => a.id == badgeId && a.habitId == habitId);

    Achievement make(String badgeId, String habitId) => Achievement()
      ..id = badgeId
      ..habitId = habitId
      ..unlockedAt = now
      ..hasBeenSeen = false;

    // ── Global badges ──────────────────────────────────────────────────────

    if (allEntries.isNotEmpty && !alreadyEarned('first_proof', 'global')) {
      newOnes.add(make('first_proof', 'global'));
    }

    if (allEntries.length >= 50 && !alreadyEarned('photo_50', 'global')) {
      newOnes.add(make('photo_50', 'global'));
    }

    if (allEntries.length >= 500 && !alreadyEarned('photo_500', 'global')) {
      newOnes.add(make('photo_500', 'global'));
    }

    if (activeHabits.length >= 5 &&
        !alreadyEarned('five_habits', 'global')) {
      newOnes.add(make('five_habits', 'global'));
    }

    final hasEarlyProof =
        allEntries.any((e) => e.completedAt.toLocal().hour < 7);
    if (hasEarlyProof && !alreadyEarned('early_bird', 'global')) {
      newOnes.add(make('early_bird', 'global'));
    }

    final hasNightProof =
        allEntries.any((e) => e.completedAt.toLocal().hour >= 23);
    if (hasNightProof && !alreadyEarned('night_owl', 'global')) {
      newOnes.add(make('night_owl', 'global'));
    }

    if (!alreadyEarned('perfect_week', 'global') &&
        _hasPerfectWeek(activeHabits, allEntries)) {
      newOnes.add(make('perfect_week', 'global'));
    }

    if (!alreadyEarned('perfect_month', 'global') &&
        _hasPerfectMonth(activeHabits, allEntries)) {
      newOnes.add(make('perfect_month', 'global'));
    }

    // ── Per-habit streak badges ────────────────────────────────────────────
    const streakBadges = [
      ('streak_7', 7),
      ('streak_30', 30),
      ('streak_100', 100),
      ('streak_365', 365),
    ];

    for (final habit in activeHabits) {
      final habitEntries =
          allEntries.where((e) => e.habitId == habit.id).toList();
      final streak =
          StatsService.currentStreak(habit, habitEntries, usedFreezes);

      for (final (badgeId, threshold) in streakBadges) {
        if (streak >= threshold && !alreadyEarned(badgeId, habit.id)) {
          newOnes.add(make(badgeId, habit.id));
        }
      }
    }

    return newOnes;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _hasPerfectWeek(
      List<Habit> habits, List<ProofEntry> allEntries) {
    if (habits.isEmpty) return false;
    final completedSet = _buildCompletedSet(allEntries);
    final today = AppDateUtils.utcDate(DateTime.now());
    final thisMonday = AppDateUtils.startOfWeek(today);

    for (int w = 1; w <= 52; w++) {
      final weekStart = thisMonday.subtract(Duration(days: w * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      if (weekEnd.isAfter(today)) continue; // Week not complete yet

      bool allComplete = true;
      int scheduledCount = 0;

      outer:
      for (final habit in habits) {
        final createdDate =
            AppDateUtils.utcDate(habit.createdAt.toLocal());
        if (createdDate.isAfter(weekStart)) continue;

        for (int d = 0; d < 7; d++) {
          final day = weekStart.add(Duration(days: d));
          if (!habit.isScheduledOn(day.weekday)) continue;
          scheduledCount++;
          if (!completedSet.contains('${habit.id}|${_ds(day)}')) {
            allComplete = false;
            break outer;
          }
        }
      }

      if (scheduledCount > 0 && allComplete) return true;
    }
    return false;
  }

  static bool _hasPerfectMonth(
      List<Habit> habits, List<ProofEntry> allEntries) {
    if (habits.isEmpty) return false;
    final completedSet = _buildCompletedSet(allEntries);
    final now = DateTime.now();
    final today = AppDateUtils.utcDate(now);

    for (int m = 1; m <= 12; m++) {
      var year = now.year;
      var month = now.month - m;
      if (month <= 0) {
        month += 12;
        year--;
      }

      final days = AppDateUtils.daysInMonth(year, month);
      if (days.last.isAfter(today)) continue; // Month not complete

      bool allComplete = true;
      int scheduledCount = 0;

      outer:
      for (final habit in habits) {
        final createdDate =
            AppDateUtils.utcDate(habit.createdAt.toLocal());
        if (createdDate.isAfter(days.first)) continue;

        for (final day in days) {
          if (!habit.isScheduledOn(day.weekday)) continue;
          scheduledCount++;
          if (!completedSet.contains('${habit.id}|${_ds(day)}')) {
            allComplete = false;
            break outer;
          }
        }
      }

      if (scheduledCount > 0 && allComplete) return true;
    }
    return false;
  }

  static Set<String> _buildCompletedSet(List<ProofEntry> entries) => {
        for (final e in entries)
          '${e.habitId}|${_ds(AppDateUtils.utcDate(e.completedAt.toLocal()))}'
      };

  static String _ds(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

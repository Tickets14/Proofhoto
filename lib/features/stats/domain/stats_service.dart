import '../../habits/data/models/habit.dart';
import '../../proof/data/models/proof_entry.dart';
import '../../../core/utils/app_date_utils.dart';

class StatsService {
  /// Calculates the current streak for [habit] given all [entries].
  ///
  /// A streak counts consecutive *scheduled* days backwards from yesterday
  /// (or today if today is already completed), ignoring non-scheduled days.
  /// Already-recorded freeze dates fill in missed days unconditionally.
  /// Additionally, up to [availableFreezes] banked freezes are auto-applied
  /// for single-day gaps (purely for display — not persisted here).
  static int currentStreak(
    Habit habit,
    List<ProofEntry> entries,
    List<String> usedFreezes, {
    int availableFreezes = 0,
  }) {
    final completedDates = _completedDates(habit.id, entries);
    return _calculateStreak(
      habit: habit,
      completedDates: completedDates,
      usedFreezes: usedFreezes,
      fromDate: DateTime.now(),
      availableFreezes: availableFreezes,
    );
  }

  /// Best (longest) streak ever for [habit].
  static int bestStreak(Habit habit, List<ProofEntry> entries) {
    final completedDates = _completedDates(habit.id, entries);
    if (completedDates.isEmpty) return 0;

    final sortedDates = completedDates.toList()..sort();
    int best = 0;
    int current = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prev = sortedDates[i - 1];
      final curr = sortedDates[i];
      final diff = AppDateUtils.daysBetween(curr, prev);

      // Skip non-scheduled days between prev and curr
      final skippedScheduled = _scheduledDaysBetween(habit, prev, curr);
      if (skippedScheduled == 0 || (diff == 1 && habit.isScheduledOn(curr.weekday))) {
        current++;
      } else {
        if (current > best) best = current;
        current = 1;
      }
    }
    return current > best ? current : best;
  }

  /// Completion rate for [habit] over the last [weeks] weeks (0.0 – 1.0).
  static double completionRate(
    Habit habit,
    List<ProofEntry> entries, {
    int weeks = 4,
  }) {
    final completedDates = _completedDates(habit.id, entries);
    final scheduledDays = _scheduledDaysInRange(
      habit,
      DateTime.now().subtract(Duration(days: weeks * 7)),
      DateTime.now(),
    );
    if (scheduledDays == 0) return 0;
    final completed =
        completedDates.where((d) => scheduledDays > 0).length.toDouble();
    return (completed / scheduledDays).clamp(0, 1);
  }

  /// Weekly completion rate over the last [weeks] weeks.
  /// Returns a list of (weekStart, rate) pairs, oldest first.
  static List<({DateTime weekStart, double rate})> weeklyRates(
    Habit habit,
    List<ProofEntry> entries, {
    int weeks = 12,
  }) {
    final result = <({DateTime weekStart, double rate})>[];
    final completedDates = _completedDates(habit.id, entries);

    for (int i = weeks - 1; i >= 0; i--) {
      final weekStart =
          AppDateUtils.startOfWeek(DateTime.now()).subtract(Duration(days: i * 7));
      final scheduledInWeek = <DateTime>[];
      for (int d = 0; d <= 6; d++) {
        final day = weekStart.add(Duration(days: d));
        if (habit.isScheduledOn(day.weekday)) scheduledInWeek.add(day);
      }

      if (scheduledInWeek.isEmpty) {
        result.add((weekStart: weekStart, rate: 0));
        continue;
      }

      final completedInWeek = scheduledInWeek
          .where((d) => completedDates.any((c) => AppDateUtils.isSameDay(c, d)))
          .length;

      result.add((
        weekStart: weekStart,
        rate: completedInWeek / scheduledInWeek.length,
      ));
    }
    return result;
  }

  /// How many habits were completed each of the last 7 days.
  static List<int> last7DaysCompletions(
    List<Habit> habits,
    List<ProofEntry> allEntries,
  ) {
    return List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      return allEntries
          .where((e) => AppDateUtils.isSameDay(e.completedAt.toLocal(), day))
          .map((e) => e.habitId)
          .toSet()
          .length;
    });
  }

  /// Completion ratio for each day in [month].
  /// Returns a map of date → ratio (0.0 – 1.0).
  static Map<DateTime, double> monthlyHeatmap(
    List<Habit> habits,
    List<ProofEntry> allEntries,
    int year,
    int month,
  ) {
    final days = AppDateUtils.daysInMonth(year, month);
    final result = <DateTime, double>{};

    for (final day in days) {
      final scheduled = habits
          .where((h) => !h.isArchived && h.isScheduledOn(day.weekday))
          .length;
      if (scheduled == 0) {
        result[day] = 0;
        continue;
      }
      final completed = allEntries
          .where((e) => AppDateUtils.isSameDay(e.completedAt.toLocal(), day))
          .map((e) => e.habitId)
          .toSet()
          .length;
      result[day] = (completed / scheduled).clamp(0, 1);
    }
    return result;
  }

  /// Returns the weekday (1=Mon…7=Sun) with the highest completion rate.
  static int? bestDayOfWeek(Habit habit, List<ProofEntry> entries) {
    final completedDates = _completedDates(habit.id, entries);
    if (completedDates.isEmpty) return null;

    final counts = List.filled(8, 0); // index 1–7
    final totals = List.filled(8, 0);

    for (final date in completedDates) {
      counts[date.weekday]++;
    }

    // Total scheduled occurrences per weekday
    final allDays = AppDateUtils.lastNDays(90);
    for (final day in allDays) {
      if (habit.isScheduledOn(day.weekday)) totals[day.weekday]++;
    }

    int? best;
    double bestRate = -1;
    for (int d = 1; d <= 7; d++) {
      if (totals[d] == 0) continue;
      final rate = counts[d] / totals[d];
      if (rate > bestRate) {
        bestRate = rate;
        best = d;
      }
    }
    return best;
  }

  // --- Private helpers ---

  static Set<DateTime> _completedDates(String habitId, List<ProofEntry> entries) {
    return entries
        .where((e) => e.habitId == habitId)
        .map((e) => AppDateUtils.utcDate(e.completedAt.toLocal()))
        .toSet();
  }

  static int _calculateStreak({
    required Habit habit,
    required Set<DateTime> completedDates,
    required List<String> usedFreezes,
    required DateTime fromDate,
    int availableFreezes = 0,
  }) {
    int streak = 0;
    int autoFreezes = availableFreezes;
    var current = AppDateUtils.utcDate(fromDate);

    // If today is not yet completed, start checking from yesterday
    if (!completedDates.contains(current)) {
      current = current.subtract(const Duration(days: 1));
    }

    while (true) {
      if (!habit.isScheduledOn(current.weekday)) {
        // Skip non-scheduled days
        current = current.subtract(const Duration(days: 1));
        continue;
      }

      final dateStr =
          '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';

      if (completedDates.contains(current)) {
        streak++;
      } else if (usedFreezes.contains(dateStr)) {
        streak++; // recorded freeze protects this day
      } else if (autoFreezes > 0) {
        streak++; // auto-apply a banked freeze for this gap
        autoFreezes--;
      } else {
        break;
      }
      current = current.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _scheduledDaysBetween(Habit habit, DateTime from, DateTime to) {
    int count = 0;
    var d = from.add(const Duration(days: 1));
    while (d.isBefore(to)) {
      if (habit.isScheduledOn(d.weekday)) count++;
      d = d.add(const Duration(days: 1));
    }
    return count;
  }

  static int _scheduledDaysInRange(Habit habit, DateTime start, DateTime end) {
    int count = 0;
    var d = AppDateUtils.utcDate(start);
    final e = AppDateUtils.utcDate(end);
    while (!d.isAfter(e)) {
      if (habit.isScheduledOn(d.weekday)) count++;
      d = d.add(const Duration(days: 1));
    }
    return count;
  }
}

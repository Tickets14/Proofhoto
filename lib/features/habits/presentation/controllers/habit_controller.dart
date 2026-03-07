import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/habit.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/notification_utils.dart';
import '../../../proof/data/models/proof_entry.dart';
import '../../../proof/presentation/controllers/proof_controller.dart';
import '../../../settings/data/models/user_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../stats/domain/stats_service.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(Hive.box<Habit>(AppConstants.habitsBox));
});

/// All active (non-archived) habits, sorted by sortOrder.
final habitsProvider = StateNotifierProvider<HabitController, List<Habit>>(
  (ref) => HabitController(ref),
);

/// Today's scheduled habits.
final todayHabitsProvider = Provider<List<Habit>>((ref) {
  return HabitService.todayHabits(ref.watch(habitsProvider));
});

/// Number of today's habits that have been completed.
/// Watches [allProofProvider] so it rebuilds whenever proof is added/removed.
final todayCompletedCountProvider = Provider<int>((ref) {
  final habits = ref.watch(todayHabitsProvider);
  final entries = ref.watch(allProofProvider);
  final today = DateTime.now();
  return habits
      .where((h) => entries.any(
            (e) =>
                e.habitId == h.id &&
                AppDateUtils.isSameDay(e.completedAt.toLocal(), today),
          ))
      .length;
});

/// Current streak for a specific habit, accounting for streak freezes.
final habitStreakProvider = Provider.family<int, String>((ref, habitId) {
  final habits = ref.watch(habitsProvider);
  final allProof = ref.watch(allProofProvider);
  final settings = ref.watch(settingsProvider);
  final matches = habits.where((h) => h.id == habitId).toList();
  if (matches.isEmpty) return 0;
  return StatsService.currentStreak(
    matches.first,
    allProof,
    settings.usedFreezes,
    availableFreezes: settings.streakFreezeCount,
  );
});

// ── Controller ─────────────────────────────────────────────────────────────

class HabitController extends StateNotifier<List<Habit>> {
  final Ref _ref;

  HabitController(this._ref) : super([]) {
    _load();
    _listenForChanges();
  }

  HabitRepository get _repo => _ref.read(habitRepositoryProvider);

  void _load() {
    state = _repo.getAll();
  }

  void _listenForChanges() {
    _repo.watch().listen((_) => _load());
  }

  Future<void> createHabit({
    required String name,
    required String emoji,
    required int colorValue,
    required List<int> reminderDays,
    String? reminderTime,
  }) async {
    final habit = HabitService.createNew(
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      reminderDays: reminderDays,
      reminderTime: reminderTime,
      sortOrder: state.length,
    );
    await _repo.save(habit);
    _load();
    _scheduleNotification(habit);
  }

  Future<void> updateHabit(
    Habit habit, {
    String? name,
    String? emoji,
    int? colorValue,
    List<int>? reminderDays,
    Object? reminderTime = const _Unset(),
    int? sortOrder,
  }) async {
    HabitService.update(
      habit,
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      reminderDays: reminderDays,
      reminderTime: reminderTime is _Unset ? const Object() : reminderTime as String?,
      sortOrder: sortOrder,
    );
    await _repo.save(habit);
    _load();
    _scheduleNotification(habit);
  }

  Future<void> archiveHabit(String habitId) async {
    await _repo.archive(habitId);
    await NotificationUtils.cancelHabitReminders(habitId);
    // Delete all proof for this habit
    final proofCtrl = _ref.read(allProofProvider.notifier);
    await proofCtrl.deleteAllForHabit(habitId);
    _load();
  }

  Future<void> reorder(List<String> orderedIds) async {
    await _repo.reorder(orderedIds);
    _load();
  }

  /// Called after proof is saved for [habitId].
  /// Awards a streak-freeze token if a 7-day milestone was just hit,
  /// and auto-applies the oldest banked freeze if yesterday was a gap.
  Future<void> checkMilestone(String habitId) async {
    final habit = _repo.getById(habitId);
    if (habit == null) return;

    final allProof = _ref.read(allProofProvider);
    final settings = _ref.read(settingsProvider);
    final habitProof = allProof.where((e) => e.habitId == habitId).toList();

    final streak = StatsService.currentStreak(
      habit,
      habitProof,
      settings.usedFreezes,
    );

    // Award freeze at every 7-day milestone
    if (streak > 0 && streak % AppConstants.freezesPerStreakMilestone == 0) {
      await _ref.read(settingsProvider.notifier).addFreeze();
    }

    // Auto-apply a freeze to yesterday if it was a scheduled gap
    await _maybeAutoFreeze(habit, allProof, settings);
  }

  Future<void> _maybeAutoFreeze(Habit habit, List<ProofEntry> allProof, UserSettings settings) async {
    if (settings.streakFreezeCount <= 0) return;

    final now = DateTime.now();
    final yesterday =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

    if (!habit.isScheduledOn(yesterday.weekday)) return;

    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (settings.usedFreezes.contains(yesterdayStr)) return;

    final hadProofYesterday = allProof.any((e) =>
        e.habitId == habit.id &&
        AppDateUtils.isSameDay(e.completedAt.toLocal(), yesterday));
    if (hadProofYesterday) return;

    await _ref.read(settingsProvider.notifier).useStreakFreeze(yesterdayStr);
  }

  void _scheduleNotification(Habit habit) {
    final settings = _ref.read(settingsProvider);
    if (!settings.notificationsEnabled) return;
    if (habit.reminderTime == null || habit.reminderDays.isEmpty) return;

    NotificationUtils.scheduleHabitReminders(
      habitId: habit.id,
      habitName: habit.name,
      reminderDays: habit.reminderDays,
      reminderTime: habit.reminderTime!,
    );
  }
}

class _Unset {
  const _Unset();
}

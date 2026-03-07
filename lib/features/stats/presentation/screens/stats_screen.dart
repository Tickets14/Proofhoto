import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../habits/data/models/habit.dart';
import '../../../proof/data/models/proof_entry.dart';
import '../../../settings/data/models/user_settings.dart';
import '../../../habits/presentation/controllers/habit_controller.dart';
import '../../../proof/presentation/controllers/proof_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../stats/domain/stats_service.dart';
import '../../../categories/data/models/habit_category.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../../app.dart' show showWeeklyReview;
import '../widgets/streak_card.dart';
import '../widgets/weekly_bar_chart.dart';
import '../widgets/monthly_heatmap.dart';
import '../widgets/completion_rate_chart.dart';
import '../../../proof/presentation/widgets/proof_timeline.dart';
import '../../../habits/presentation/widgets/daily_progress_ring.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/habits/presentation/widgets/empty_state.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _selectedHabitId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);
    final allEntries = ref.watch(allProofProvider);
    final settings = ref.watch(settingsProvider);
    final categories = ref.watch(categoriesProvider);

    if (habits.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          emoji: '📊',
          title: 'No data yet',
          subtitle: 'Create habits and complete them to see your statistics.',
        ),
      );
    }

    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Week Review'),
            onPressed: () => showWeeklyReview(context, ref),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Per Habit')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _OverviewTab(
            habits: habits,
            allEntries: allEntries,
            settings: settings,
            categories: categories,
            now: now,
          ),
          _PerHabitTab(
            habits: habits,
            allEntries: allEntries,
            settings: settings,
            categories: categories,
            selectedHabitId: _selectedHabitId ?? habits.first.id,
            onHabitChanged: (id) => setState(() => _selectedHabitId = id),
          ),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.habits,
    required this.allEntries,
    required this.settings,
    required this.categories,
    required this.now,
  });

  final List<Habit> habits;
  final List<ProofEntry> allEntries;
  final UserSettings settings;
  final List<HabitCategory> categories;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final completionsPerDay =
        StatsService.last7DaysCompletions(habits, allEntries);
    final heatmapData =
        StatsService.monthlyHeatmap(habits, allEntries, now.year, now.month);

    // Best current and all-time streak across all habits
    int bestCurrentStreak = 0;
    int bestAllTimeStreak = 0;
    for (final h in habits) {
      final entries = allEntries.where((e) => e.habitId == h.id).toList();
      final current = StatsService.currentStreak(
        h, entries, settings.usedFreezes,
        availableFreezes: settings.streakFreezeCount,
      );
      final best = StatsService.bestStreak(h, entries);
      if (current > bestCurrentStreak) bestCurrentStreak = current;
      if (best > bestAllTimeStreak) bestAllTimeStreak = best;
    }

    // Today's score
    final completedHabitIds = allEntries
        .where((e) =>
            e.completedAt.toLocal().day == now.day &&
            e.completedAt.toLocal().month == now.month &&
            e.completedAt.toLocal().year == now.year)
        .map((e) => e.habitId)
        .toSet();
    final scheduledToday =
        habits.where((h) => h.isScheduledOn(now.weekday)).length;
    final completedToday = completedHabitIds.length;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      children: [
        StreakCard(
          currentStreak: bestCurrentStreak,
          bestStreak: bestAllTimeStreak,
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: "Today's Score",
          child: _TodayScoreRow(
            completed: completedToday,
            total: scheduledToday,
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Last 7 Days',
          child: WeeklyBarChart(
            completionsPerDay: completionsPerDay,
            maxHabits: habits.length,
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Monthly Heatmap',
          child: MonthlyHeatmap(
            year: now.year,
            month: now.month,
            completionRatios: heatmapData,
            onDayTap: (date) => _showDayDetail(context, date),
          ),
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'By Category',
            child: _CategoryBreakdown(
              habits: habits,
              allEntries: allEntries,
              categories: categories,
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  void _showDayDetail(BuildContext context, DateTime date) {
    final entriesOnDay = allEntries
        .where((e) => AppDateUtils.isSameDay(e.completedAt.toLocal(), date))
        .toList();
    final habitMap = {for (final h in habits) h.id: h};

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DayDetailSheet(
        date: date,
        entries: entriesOnDay,
        habitMap: habitMap,
      ),
    );
  }
}

// ── Per Habit Tab ─────────────────────────────────────────────────────────────

class _PerHabitTab extends StatelessWidget {
  const _PerHabitTab({
    required this.habits,
    required this.allEntries,
    required this.settings,
    required this.categories,
    required this.selectedHabitId,
    required this.onHabitChanged,
  });

  final List<Habit> habits;
  final List<ProofEntry> allEntries;
  final UserSettings settings;
  final List<HabitCategory> categories;
  final String selectedHabitId;
  final ValueChanged<String> onHabitChanged;

  @override
  Widget build(BuildContext context) {
    final habit = habits.firstWhere(
      (h) => h.id == selectedHabitId,
      orElse: () => habits.first,
    );
    final entries = allEntries.where((e) => e.habitId == habit.id).toList();
    final category = habit.categoryId != null
        ? categories.where((c) => c.id == habit.categoryId).firstOrNull
        : null;
    final currentStreak = StatsService.currentStreak(
      habit, entries, settings.usedFreezes,
      availableFreezes: settings.streakFreezeCount,
    );
    final bestStreak = StatsService.bestStreak(habit, entries);
    final weeklyRates = StatsService.weeklyRates(habit, entries);
    final bestDay = StatsService.bestDayOfWeek(habit, entries);
    final recentEntries = entries.take(6).toList();

    return ListView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      children: [
        // Habit selector dropdown
        DropdownButtonFormField<String>(
          value: selectedHabitId,
          decoration: const InputDecoration(labelText: 'Select habit'),
          items: habits.map((h) {
            return DropdownMenuItem(
              value: h.id,
              child: Text('${h.emoji} ${h.name}'),
            );
          }).toList(),
          onChanged: (id) {
            if (id != null) onHabitChanged(id);
          },
        ),
        if (category != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Color(category.colorValue).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.emoji,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(category.colorValue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Streak card
        StreakCard(
          currentStreak: currentStreak,
          bestStreak: bestStreak,
          habitName: habit.name,
        ),
        const SizedBox(height: 16),

        // Completion rate line chart
        if (weeklyRates.isNotEmpty)
          _SectionCard(
            title: 'Weekly Completion Rate',
            subtitle: 'Last 12 weeks',
            child: CompletionRateChart(weeklyRates: weeklyRates),
          ),
        const SizedBox(height: 16),

        // Best day of week
        if (bestDay != null)
          _SectionCard(
            title: 'Best Day of the Week',
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppConstants.dayLabels[bestDay - 1],
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.dayFullLabels[bestDay - 1],
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "You're most consistent on this day",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // 6-photo collage
        if (recentEntries.isNotEmpty)
          _SectionCard(
            title: 'Recent Proof',
            subtitle: 'Latest ${recentEntries.length} photos',
            child: ProofTimeline(
              entries: recentEntries,
              crossAxisCount: 3,
              spacing: 6,
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Day detail bottom sheet ───────────────────────────────────────────────────

class _DayDetailSheet extends StatelessWidget {
  const _DayDetailSheet({
    required this.date,
    required this.entries,
    required this.habitMap,
  });

  final DateTime date;
  final List<ProofEntry> entries;
  final Map<String, Habit> habitMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  AppDateUtils.friendlyDate(date),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: entries.isEmpty
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${entries.length} done',
                  style: TextStyle(
                    color: entries.isEmpty
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No habits completed on this day.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            ...entries.map((e) {
              final habit = habitMap[e.habitId];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: habit != null
                        ? Color(habit.colorValue).withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    habit?.emoji ?? '❓',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                title: Text(
                  habit?.name ?? 'Deleted habit',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(
                  AppDateUtils.formatTime(e.completedAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                trailing: e.note != null && e.note!.isNotEmpty
                    ? Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
              );
            }),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _TodayScoreRow extends StatelessWidget {
  const _TodayScoreRow({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final allDone = total > 0 && completed >= total;
    final remaining = total - completed;

    return Row(
      children: [
        DailyProgressRing(
          completed: completed,
          total: total,
          size: 80,
          strokeWidth: 8,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                total == 0 ? 'Rest day' : '$completed of $total',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                total == 0
                    ? 'No habits scheduled today'
                    : allDone
                        ? '🎉 All habits completed!'
                        : '$remaining habit${remaining == 1 ? '' : 's'} remaining',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Category breakdown ────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.habits,
    required this.allEntries,
    required this.categories,
  });

  final List<Habit> habits;
  final List<ProofEntry> allEntries;
  final List<HabitCategory> categories;

  @override
  Widget build(BuildContext context) {
    // Total completions per category (all time)
    final Map<String, int> countById = {};
    for (final entry in allEntries) {
      final habit = habits.where((h) => h.id == entry.habitId).firstOrNull;
      if (habit == null) continue;
      final key = habit.categoryId ?? '__uncategorized__';
      countById[key] = (countById[key] ?? 0) + 1;
    }

    final total = countById.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No completions yet.'),
      );
    }

    final rows = <({String label, String emoji, int count, Color color})>[];
    for (final cat in categories) {
      final count = countById[cat.id] ?? 0;
      if (count == 0) continue;
      rows.add((
        label: cat.name,
        emoji: cat.emoji,
        count: count,
        color: Color(cat.colorValue),
      ));
    }
    final uncategorized = countById['__uncategorized__'] ?? 0;
    if (uncategorized > 0) {
      rows.add((
        label: 'Uncategorized',
        emoji: '🗂️',
        count: uncategorized,
        color: Colors.grey,
      ));
    }
    rows.sort((a, b) => b.count.compareTo(a.count));

    return Column(
      children: rows.map((r) {
        final ratio = r.count / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(r.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(r.label,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Text(
                    '${r.count}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: r.color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(r.color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

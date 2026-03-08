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
import '../../../../core/router/app_router.dart';
import '../../../achievements/data/models/achievement.dart';
import '../../../achievements/data/models/badge_definitions.dart';
import '../../../achievements/presentation/controllers/achievement_controller.dart';
import '../widgets/streak_card.dart';
import '../widgets/weekly_bar_chart.dart';
import '../widgets/monthly_heatmap.dart';
import '../widgets/completion_rate_chart.dart';
import '../../../proof/presentation/widgets/proof_timeline.dart';
import '../../../habits/presentation/widgets/daily_progress_ring.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
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
    final responsive = ResponsiveSpec.of(context);
    final habits = ref.watch(habitsProvider);
    final allEntries = ref.watch(allProofProvider);
    final settings = ref.watch(settingsProvider);
    final categories = ref.watch(categoriesProvider);
    final achievements = ref.watch(achievementsProvider);

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
          if (responsive.isCompact)
            IconButton(
              icon: const Icon(Icons.auto_awesome_outlined),
              tooltip: 'Week Review',
              onPressed: () => showWeeklyReview(context, ref),
            )
          else ...[
            TextButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Week Review'),
              onPressed: () => showWeeklyReview(context, ref),
            ),
            const SizedBox(width: 4),
          ],
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: responsive.isCompact,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Per Habit')],
        ),
      ),
      body: ResponsiveBody(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _OverviewTab(
              habits: habits,
              allEntries: allEntries,
              settings: settings,
              categories: categories,
              achievements: achievements,
              now: now,
              horizontalPadding: responsive.horizontalPadding,
              isCompact: responsive.isCompact,
            ),
            _PerHabitTab(
              habits: habits,
              allEntries: allEntries,
              settings: settings,
              categories: categories,
              selectedHabitId: _selectedHabitId ?? habits.first.id,
              onHabitChanged: (id) => setState(() => _selectedHabitId = id),
              horizontalPadding: responsive.horizontalPadding,
              isCompact: responsive.isCompact,
            ),
          ],
        ),
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
    required this.achievements,
    required this.now,
    required this.horizontalPadding,
    required this.isCompact,
  });

  final List<Habit> habits;
  final List<ProofEntry> allEntries;
  final UserSettings settings;
  final List<HabitCategory> categories;
  final List<Achievement> achievements;
  final DateTime now;
  final double horizontalPadding;
  final bool isCompact;

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
        h,
        entries,
        settings.usedFreezes,
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
    final sectionGap = isCompact ? 12.0 : 16.0;

    return ListView(
      padding: EdgeInsets.all(horizontalPadding),
      children: [
        StreakCard(
          currentStreak: bestCurrentStreak,
          bestStreak: bestAllTimeStreak,
        ),
        if (achievements.isNotEmpty) ...[
          SizedBox(height: sectionGap),
          _RecentAchievements(achievements: achievements),
        ],
        SizedBox(height: sectionGap),
        _SectionCard(
          title: "Today's Score",
          child: _TodayScoreRow(
            completed: completedToday,
            total: scheduledToday,
          ),
        ),
        SizedBox(height: sectionGap),
        _SectionCard(
          title: 'Last 7 Days',
          child: WeeklyBarChart(
            completionsPerDay: completionsPerDay,
            maxHabits: habits.length,
          ),
        ),
        SizedBox(height: sectionGap),
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
          SizedBox(height: sectionGap),
          _SectionCard(
            title: 'By Category',
            child: _CategoryBreakdown(
              habits: habits,
              allEntries: allEntries,
              categories: categories,
            ),
          ),
        ],
        SizedBox(height: isCompact ? 72 : 80),
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
      isScrollControlled: true,
      useSafeArea: true,
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
    required this.horizontalPadding,
    required this.isCompact,
  });

  final List<Habit> habits;
  final List<ProofEntry> allEntries;
  final UserSettings settings;
  final List<HabitCategory> categories;
  final String selectedHabitId;
  final ValueChanged<String> onHabitChanged;
  final double horizontalPadding;
  final bool isCompact;

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
      habit,
      entries,
      settings.usedFreezes,
      availableFreezes: settings.streakFreezeCount,
    );
    final bestStreak = StatsService.bestStreak(habit, entries);
    final weeklyRates = StatsService.weeklyRates(habit, entries);
    final bestDay = StatsService.bestDayOfWeek(habit, entries);
    final recentEntries = entries.take(6).toList();
    final sectionGap = isCompact ? 12.0 : 16.0;

    return ListView(
      padding: EdgeInsets.all(horizontalPadding),
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
                  Text(category.emoji, style: const TextStyle(fontSize: 14)),
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
        SizedBox(height: isCompact ? 16 : 20),

        // Streak card
        StreakCard(
          currentStreak: currentStreak,
          bestStreak: bestStreak,
          habitName: habit.name,
        ),
        SizedBox(height: sectionGap),

        // Completion rate line chart
        if (weeklyRates.isNotEmpty)
          _SectionCard(
            title: 'Weekly Completion Rate',
            subtitle: 'Last 12 weeks',
            child: CompletionRateChart(weeklyRates: weeklyRates),
          ),
        SizedBox(height: sectionGap),

        // Best day of week
        if (bestDay != null)
          _SectionCard(
            title: 'Best Day of the Week',
            child: Row(
              children: [
                Container(
                  width: isCompact ? 44 : 48,
                  height: isCompact ? 44 : 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppConstants.dayLabels[bestDay - 1],
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: isCompact ? 13 : 14,
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? 10 : 14),
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
                      SizedBox(height: isCompact ? 1 : 2),
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
        SizedBox(height: sectionGap),

        // 6-photo collage
        if (recentEntries.isNotEmpty)
          _SectionCard(
            title: 'Recent Proof',
            subtitle: 'Latest ${recentEntries.length} photos',
            child: ProofTimeline(
              entries: recentEntries,
              crossAxisCount: isCompact ? 2 : 3,
              spacing: 6,
            ),
          ),
        SizedBox(height: isCompact ? 72 : 80),
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
    final responsive = ResponsiveSpec.of(context);
    final compact = responsive.isCompact;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          responsive.horizontalPadding,
          20,
          responsive.horizontalPadding,
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
                    width: compact ? 36 : 40,
                    height: compact ? 36 : 40,
                    decoration: BoxDecoration(
                      color: habit != null
                          ? Color(habit.colorValue).withValues(alpha: 0.12)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      habit?.emoji ?? '❓',
                      style: TextStyle(fontSize: compact ? 18 : 20),
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
                          size: compact ? 14 : 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : null,
                );
              }),
          ],
        ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;

        final summary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              total == 0 ? 'Rest day' : '$completed of $total',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: compact ? 2 : 3),
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
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DailyProgressRing(
                completed: completed,
                total: total,
                size: 68,
                strokeWidth: 7,
              ),
              const SizedBox(height: 10),
              summary,
            ],
          );
        }

        return Row(
          children: [
            DailyProgressRing(
              completed: completed,
              total: total,
              size: 80,
              strokeWidth: 8,
            ),
            const SizedBox(width: 20),
            Expanded(child: summary),
          ],
        );
      },
    );
  }
}

// ── Recent Achievements ───────────────────────────────────────────────────────

class _RecentAchievements extends StatelessWidget {
  const _RecentAchievements({required this.achievements});
  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSpec.of(context);
    final compact = responsive.isCompact;
    // Last 3 unlocked, newest first
    final recent = achievements.take(3).toList();

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent.map((a) {
              final badge = badgeById(a.id);
              return Tooltip(
                message: badge?.name ?? a.id,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withValues(alpha: 0.12),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge?.emoji ?? '🏅',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.badges),
            child: const Text('See all →'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Row(
            children: recent.map((a) {
              final badge = badgeById(a.id);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: badge?.name ?? a.id,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: 0.12),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text(badge?.emoji ?? '🏅',
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.badges),
          child: const Text('See all →'),
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
        color: Theme.of(context).colorScheme.outline,
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
    final responsive = ResponsiveSpec.of(context);
    final compact = responsive.isCompact;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        // M3: surfaceContainerLow for a subtle card that reads as elevated
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
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
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          child,
        ],
      ),
    );
  }
}

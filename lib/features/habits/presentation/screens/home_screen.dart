import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/habit_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/habit_card.dart';
import '../widgets/daily_progress_ring.dart';
import '../widgets/empty_state.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayHabits = ref.watch(todayHabitsProvider);
    final completed = ref.watch(todayCompletedCountProvider);
    final settings = ref.watch(settingsProvider);
    final dateStr = _todayStr();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HomeHeaderDelegate(
              completed: completed,
              total: todayHabits.length,
            ),
          ),
          if (todayHabits.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                emoji: '🌱',
                title: 'No habits yet',
                subtitle:
                    'Build consistency one photo at a time. Create your first habit to get started.',
                actionLabel: 'Create your first habit',
                onAction: () =>
                    Navigator.of(context).pushNamed(AppRoutes.createHabit),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverReorderableList(
                itemCount: todayHabits.length,
                itemBuilder: (context, index) {
                  final habit = todayHabits[index];
                  final isFrozen = settings.usedFreezes.contains(dateStr);
                  return HabitCard(
                    key: ValueKey(habit.id),
                    habit: habit,
                    isFrozen: isFrozen,
                    dragIndex: index,
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) newIndex--;
                  final ids = todayHabits.map((h) => h.id).toList();
                  ids.insert(newIndex, ids.removeAt(oldIndex));
                  ref.read(habitsProvider.notifier).reorder(ids);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.createHabit),
        tooltip: 'New habit',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

// ── Collapsible header delegate ─────────────────────────────────────────────

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HomeHeaderDelegate({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  double get minExtent => 80;
  @override
  double get maxExtent => 190;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final shrinkRatio =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final expandRatio = 1 - shrinkRatio;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        AppConstants.screenPadding,
        MediaQuery.of(context).padding.top + 8,
        AppConstants.screenPadding,
        8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    heightFactor: expandRatio,
                    child: Opacity(
                      opacity: expandRatio,
                      child: Text(
                        '${AppDateUtils.greeting()}!',
                        style: Theme.of(context).textTheme.headlineLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2 * expandRatio),
                Text(
                  AppDateUtils.todayFormatted(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
          AnimatedScale(
            scale: 0.7 + (0.3 * expandRatio),
            duration: Duration.zero,
            child: DailyProgressRing(
              completed: completed,
              total: total,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_HomeHeaderDelegate old) =>
      old.completed != completed || old.total != total;
}

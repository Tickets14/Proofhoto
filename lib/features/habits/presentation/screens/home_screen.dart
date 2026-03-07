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
import '../../../../features/categories/presentation/controllers/category_controller.dart';
import '../../../../features/categories/data/models/habit_category.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayHabits = ref.watch(todayHabitsProvider);
    final completed = ref.watch(todayCompletedCountProvider);
    final settings = ref.watch(settingsProvider);
    final categories = ref.watch(categoriesProvider);
    final activeFilter = ref.watch(categoryFilterProvider);
    final dateStr = _todayStr();

    // Apply category filter
    final filteredHabits = activeFilter == null
        ? todayHabits
        : activeFilter == '__uncategorized__'
            ? todayHabits.where((h) => h.categoryId == null).toList()
            : todayHabits
                .where((h) => h.categoryId == activeFilter)
                .toList();

    final isFiltering = activeFilter != null;

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

          // Category filter chips (only when categories exist)
          if (categories.isNotEmpty)
            SliverToBoxAdapter(
              child: _CategoryFilterRow(
                categories: categories,
                activeFilter: activeFilter,
                onFilterChanged: (f) =>
                    ref.read(categoryFilterProvider.notifier).state = f,
              ),
            ),

          if (filteredHabits.isEmpty && todayHabits.isEmpty)
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
          else if (filteredHabits.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No habits in this category today.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: isFiltering
                  // No drag handles when filtered — order is ambiguous
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final habit = filteredHabits[i];
                          final isFrozen =
                              settings.usedFreezes.contains(dateStr);
                          return HabitCard(
                            key: ValueKey(habit.id),
                            habit: habit,
                            isFrozen: isFrozen,
                          );
                        },
                        childCount: filteredHabits.length,
                      ),
                    )
                  : SliverReorderableList(
                      itemCount: filteredHabits.length,
                      itemBuilder: (context, index) {
                        final habit = filteredHabits[index];
                        final isFrozen =
                            settings.usedFreezes.contains(dateStr);
                        return HabitCard(
                          key: ValueKey(habit.id),
                          habit: habit,
                          isFrozen: isFrozen,
                          dragIndex: index,
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex < newIndex) newIndex--;
                        final ids =
                            filteredHabits.map((h) => h.id).toList();
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

// ── Category filter row ──────────────────────────────────────────────────────

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.categories,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final List<HabitCategory> categories;
  final String? activeFilter;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPadding, vertical: 4),
        children: [
          _Chip(
            label: 'All',
            isActive: activeFilter == null,
            onTap: () => onFilterChanged(null),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Uncategorized',
            isActive: activeFilter == '__uncategorized__',
            onTap: () => onFilterChanged('__uncategorized__'),
          ),
          const SizedBox(width: 8),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: '${cat.emoji} ${cat.name}',
                  isActive: activeFilter == cat.id,
                  onTap: () => onFilterChanged(cat.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
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

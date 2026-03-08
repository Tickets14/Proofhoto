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
import '../../../../core/utils/responsive_utils.dart';
import '../../../../features/categories/presentation/controllers/category_controller.dart';
import '../../../../features/categories/data/models/habit_category.dart';
import '../../../../features/achievements/presentation/controllers/achievement_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = ResponsiveSpec.of(context);
    final todayHabits = ref.watch(todayHabitsProvider);
    final completed = ref.watch(todayCompletedCountProvider);
    final settings = ref.watch(settingsProvider);
    final categories = ref.watch(categoriesProvider);
    final activeFilter = ref.watch(categoryFilterProvider);
    final unseenBadgeCount = ref.watch(unseenAchievementsProvider).length;
    final dateStr = _todayStr();
    final headerMinExtent =
        responsive.value(compact: 72, regular: 80, largePhone: 88);
    final headerMaxExtent =
        responsive.value(compact: 164, regular: 190, largePhone: 204);

    // Apply category filter
    final filteredHabits = activeFilter == null
        ? todayHabits
        : activeFilter == '__uncategorized__'
            ? todayHabits.where((h) => h.categoryId == null).toList()
            : todayHabits.where((h) => h.categoryId == activeFilter).toList();

    final isFiltering = activeFilter != null;

    return Scaffold(
      body: ResponsiveBody(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(
                completed: completed,
                total: todayHabits.length,
                unseenBadgeCount: unseenBadgeCount,
                horizontalPadding: responsive.horizontalPadding,
                minHeaderExtent: headerMinExtent,
                maxHeaderExtent: headerMaxExtent,
                isCompact: responsive.isCompact,
              ),
            ),

            // Category filter chips (only when categories exist)
            if (categories.isNotEmpty)
              SliverToBoxAdapter(
                child: _CategoryFilterRow(
                  categories: categories,
                  activeFilter: activeFilter,
                  horizontalPadding: responsive.horizontalPadding,
                  isCompact: responsive.isCompact,
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
                padding: EdgeInsets.only(
                  bottom: responsive.value(
                    compact: 88,
                    regular: 100,
                    largePhone: 108,
                  ),
                ),
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
                          final ids = filteredHabits.map((h) => h.id).toList();
                          ids.insert(newIndex, ids.removeAt(oldIndex));
                          ref.read(habitsProvider.notifier).reorder(ids);
                        },
                      ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createHabit),
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
    required this.horizontalPadding,
    required this.isCompact,
    required this.onFilterChanged,
  });

  final List<HabitCategory> categories;
  final String? activeFilter;
  final double horizontalPadding;
  final bool isCompact;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCompact ? 48 : 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: activeFilter == null,
            onSelected: (_) => onFilterChanged(null),
            visualDensity:
                isCompact ? VisualDensity.compact : VisualDensity.standard,
          ),
          SizedBox(width: isCompact ? 6 : 8),
          FilterChip(
            label: const Text('Uncategorized'),
            selected: activeFilter == '__uncategorized__',
            onSelected: (_) => onFilterChanged('__uncategorized__'),
            visualDensity:
                isCompact ? VisualDensity.compact : VisualDensity.standard,
          ),
          SizedBox(width: isCompact ? 6 : 8),
          ...categories.map((cat) => Padding(
                padding: EdgeInsets.only(right: isCompact ? 6 : 8),
                child: FilterChip(
                  label: Text('${cat.emoji} ${cat.name}'),
                  selected: activeFilter == cat.id,
                  onSelected: (_) => onFilterChanged(cat.id),
                  visualDensity: isCompact
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                ),
              )),
        ],
      ),
    );
  }
}

// ── Collapsible header delegate ─────────────────────────────────────────────

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HomeHeaderDelegate({
    required this.completed,
    required this.total,
    required this.unseenBadgeCount,
    required this.horizontalPadding,
    required this.minHeaderExtent,
    required this.maxHeaderExtent,
    required this.isCompact,
  });

  final int completed;
  final int total;
  final int unseenBadgeCount;
  final double horizontalPadding;
  final double minHeaderExtent;
  final double maxHeaderExtent;
  final bool isCompact;

  @override
  double get minExtent => minHeaderExtent;
  @override
  double get maxExtent => maxHeaderExtent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final shrinkRatio =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final expandRatio = 1 - shrinkRatio;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        MediaQuery.of(context).padding.top + 8,
        horizontalPadding,
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
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${AppDateUtils.greeting()}!',
                          style: isCompact
                              ? Theme.of(context).textTheme.headlineMedium
                              : Theme.of(context).textTheme.headlineLarge,
                          softWrap: false,
                        ),
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
          // Trophy / badges button with unseen badge indicator
          Badge(
            isLabelVisible: unseenBadgeCount > 0,
            label: Text(unseenBadgeCount > 9 ? '9+' : '$unseenBadgeCount'),
            child: IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: 'Badges',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.badges),
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
            scale: (isCompact ? 0.64 : 0.7) + (0.3 * expandRatio),
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
      old.completed != completed ||
      old.total != total ||
      old.unseenBadgeCount != unseenBadgeCount ||
      old.horizontalPadding != horizontalPadding ||
      old.minHeaderExtent != minHeaderExtent ||
      old.maxHeaderExtent != maxHeaderExtent ||
      old.isCompact != isCompact;
}

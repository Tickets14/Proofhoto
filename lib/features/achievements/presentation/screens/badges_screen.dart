import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/achievement.dart';
import '../../data/models/badge_definitions.dart';
import '../controllers/achievement_controller.dart';
import '../../../habits/presentation/controllers/habit_controller.dart';
import '../../../../core/constants/app_constants.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final habits = ref.watch(habitsProvider);

    final unlockedCount =
        kBadges.where((b) => _isUnlocked(b.id, achievements)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _ProgressHeader(
              unlocked: unlockedCount, total: kBadges.length),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.fromLTRB(
          AppConstants.screenPadding,
          AppConstants.cardPadding,
          AppConstants.screenPadding,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: kBadges.length,
        itemBuilder: (context, i) {
          final badge = kBadges[i];
          final unlocked = _isUnlocked(badge.id, achievements);
          final earnedOnes = achievements
              .where((a) => a.id == badge.id)
              .toList()
            ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));

          return _BadgeTile(
            badge: badge,
            unlocked: unlocked,
            earnedAchievements: earnedOnes,
            habits: habits,
            onTap: () => _showDetail(context, badge, earnedOnes, habits),
          );
        },
      ),
    );
  }

  bool _isUnlocked(String badgeId, List<Achievement> achievements) =>
      achievements.any((a) => a.id == badgeId);

  void _showDetail(
    BuildContext context,
    BadgeDefinition badge,
    List<Achievement> earned,
    List habits,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BadgeDetailSheet(
        badge: badge,
        earned: earned,
        habits: habits,
      ),
    );
  }
}

// ── Progress header ───────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.unlocked, required this.total});
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : unlocked / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$unlocked / $total badges unlocked',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge grid tile ───────────────────────────────────────────────────────────

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.unlocked,
    required this.earnedAchievements,
    required this.habits,
    required this.onTap,
  });

  final BadgeDefinition badge;
  final bool unlocked;
  final List<Achievement> earnedAchievements;
  final List habits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: unlocked
              ? Colors.amber.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? Colors.amber.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji
                  Opacity(
                    opacity: unlocked ? 1.0 : 0.25,
                    child: Text(
                      badge.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: unlocked
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (unlocked && earnedAchievements.length > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      '×${earnedAchievements.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.amber.shade600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Lock overlay (locked state)
            if (!unlocked)
              Positioned(
                bottom: 8,
                right: 8,
                child: Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Badge detail bottom sheet ─────────────────────────────────────────────────

class _BadgeDetailSheet extends StatelessWidget {
  const _BadgeDetailSheet({
    required this.badge,
    required this.earned,
    required this.habits,
  });

  final BadgeDefinition badge;
  final List<Achievement> earned;
  final List habits;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = earned.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji
          Text(badge.emoji,
              style: TextStyle(
                  fontSize: 64,
                  color: isUnlocked
                      ? null
                      : Theme.of(context).colorScheme.outlineVariant)),
          const SizedBox(height: 12),

          // Name
          Text(
            badge.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          // Description / hint
          Text(
            isUnlocked ? badge.description : 'Hint: ${badge.hint}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),

          // Earned list (for per-habit badges)
          if (isUnlocked && earned.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...earned.take(5).map((a) {
              final habit = a.habitId != 'global'
                  ? habits
                      .where((h) => h.id == a.habitId)
                      .firstOrNull
                  : null;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    if (habit != null) ...[
                      Text(habit.emoji,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          habit.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Expanded(child: Text('All habits')),
                    Text(
                      _formatDate(a.unlockedAt.toLocal()),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (!isUnlocked) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Not yet unlocked',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

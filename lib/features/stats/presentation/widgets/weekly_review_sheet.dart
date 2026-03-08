import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/weekly_review.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/video_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';

class WeeklyReviewSheet extends StatelessWidget {
  const WeeklyReviewSheet({
    super.key,
    required this.review,
    this.onDismiss,
  });

  final WeeklyReviewData review;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.screenPadding, 8,
                    AppConstants.screenPadding, 32),
                children: [
                  _Header(review: review),
                  const SizedBox(height: 24),
                  _BigStat(review: review),
                  const SizedBox(height: 20),
                  _StatsRow(review: review),
                  if (review.streaks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _StreakSection(streaks: review.streaks),
                  ],
                  if (review.highlights.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _PhotoHighlights(highlights: review.highlights),
                  ],
                  const SizedBox(height: 24),
                  _MotivationalCard(review: review),
                  const SizedBox(height: 28),
                  _CTAButton(onDismiss: onDismiss),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.review});
  final WeeklyReviewData review;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              review.headerEmoji,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week in Review',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    AppDateUtils.formatWeekRange(
                        review.weekStart, review.weekEnd),
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
      ],
    );
  }
}

// ── Big completion percentage ─────────────────────────────────────────────────

class _BigStat extends StatelessWidget {
  const _BigStat({required this.review});
  final WeeklyReviewData review;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = review.completionPct;
    final color = pct >= 80
        ? cs.tertiary
        : pct >= 50
            ? cs.primary
            : cs.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            review.hasActivity
                ? '${review.totalCompletions} of ${review.totalScheduled} habit completions'
                : 'No completions this week',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: review.completionRate,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick stats row ───────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.review});
  final WeeklyReviewData review;

  static const _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final bestDayName = review.bestDayWeekday > 0
        ? _dayNames[review.bestDayWeekday - 1]
        : '—';

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_outlined,
            label: 'Best Day',
            value: review.bestDayWeekday > 0
                ? bestDayName.substring(0, 3)
                : '—',
            subtitle: review.bestDayCount > 0
                ? '${review.bestDayCount} done'
                : '',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.emoji_events_outlined,
            label: 'Milestones',
            value:
                '${review.streaks.where((s) => s.milestoneThisWeek != null).length}',
            subtitle: review.streaks
                    .any((s) => s.milestoneThisWeek != null)
                ? '🏆 new!'
                : 'this week',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.photo_camera_outlined,
            label: 'Proof Shots',
            value: '${review.highlights.length}',
            subtitle: 'saved',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

// ── Streak section ────────────────────────────────────────────────────────────

class _StreakSection extends StatelessWidget {
  const _StreakSection({required this.streaks});
  final List<HabitStreakInfo> streaks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak Update',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...streaks.take(5).map((s) => _StreakRow(info: s)),
        if (streaks.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+ ${streaks.length - 5} more habits',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.info});
  final HabitStreakInfo info;

  @override
  Widget build(BuildContext context) {
    final hasMilestone = info.milestoneThisWeek != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(info.habitEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.habitName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasMilestone)
                  Text(
                    '🏆 Hit ${info.milestoneThisWeek} days!',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hasMilestone
                  ? Colors.amber.withValues(alpha: 0.15)
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                Text(
                  '${info.currentStreak}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hasMilestone
                        ? Colors.amber.shade700
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo highlights ──────────────────────────────────────────────────────────

class _PhotoHighlights extends StatelessWidget {
  const _PhotoHighlights({required this.highlights});
  final List<WeeklyHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo Highlights',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: highlights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _HighlightTile(highlight: highlights[i]),
          ),
        ),
      ],
    );
  }
}

class _HighlightTile extends StatefulWidget {
  const _HighlightTile({required this.highlight});
  final WeeklyHighlight highlight;

  @override
  State<_HighlightTile> createState() => _HighlightTileState();
}

class _HighlightTileState extends State<_HighlightTile> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entry = widget.highlight.entry;
    final File? f;
    if (entry.isVideo) {
      f = await VideoUtils.thumbnailFile(entry.imagePath);
    } else {
      f = await ImageUtils.fileFromRelativePath(entry.imagePath);
    }
    if (mounted) setState(() => _file = f);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.highlight;

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRoutes.proofDetail, arguments: h.entry.id),
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Hero(
              tag: 'proof_${h.entry.id}',
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppConstants.imageRadius),
                child: SizedBox(
                  width: 110,
                  height: 100,
                  child: _file != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_file!,
                                fit: BoxFit.cover, cacheWidth: 220),
                            if (h.entry.isVideo)
                              Center(
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                        .withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Habit + day
            Row(
              children: [
                Text(h.habitEmoji,
                    style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    h.dayLabel,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Motivational message ──────────────────────────────────────────────────────

class _MotivationalCard extends StatelessWidget {
  const _MotivationalCard({required this.review});
  final WeeklyReviewData review;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = review.completionPct;
    final color = pct >= 80
        ? cs.tertiary
        : pct >= 50
            ? cs.primary
            : cs.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.hasActivity
                ? (pct >= 90 ? '🚀' : pct >= 70 ? '✨' : pct >= 50 ? '📈' : '💡')
                : '🌱',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              review.motivationalMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTA ───────────────────────────────────────────────────────────────────────

class _CTAButton extends StatelessWidget {
  const _CTAButton({this.onDismiss});
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onDismiss ?? () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius)),
        ),
        child: const Text(
          "Let's make this week even better!",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../proof/presentation/controllers/proof_controller.dart';
import '../../../proof/data/models/proof_entry.dart';
import '../../../habits/data/models/habit.dart';
import '../../../habits/presentation/controllers/habit_controller.dart';
import '../../../../features/habits/presentation/widgets/empty_state.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEntries = ref.watch(allProofProvider);
    final allHabits = ref.watch(habitsProvider);

    if (allEntries.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          emoji: '📸',
          title: 'No proof yet',
          subtitle:
              'Complete a habit to see your photo timeline here. Your journey starts with the first snap!',
        ),
      );
    }

    final habitMap = {for (final h in allHabits) h.id: h};
    final grouped = _groupByDate(allEntries);
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: CustomScrollView(
        slivers: [
          for (final date in dates) ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _DateHeaderDelegate(
                label: AppDateUtils.friendlyDate(date),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final entry = grouped[date]![i];
                  return _TimelineEntry(
                    entry: entry,
                    habit: habitMap[entry.habitId],
                  );
                },
                childCount: grouped[date]!.length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Map<DateTime, List<ProofEntry>> _groupByDate(List<ProofEntry> entries) {
    final result = <DateTime, List<ProofEntry>>{};
    for (final entry in entries) {
      final local = entry.completedAt.toLocal();
      final date = DateTime(local.year, local.month, local.day);
      result.putIfAbsent(date, () => []).add(entry);
    }
    return result;
  }
}

// ── Sticky date header ────────────────────────────────────────────────────────

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DateHeaderDelegate({required this.label});

  final String label;

  static const double _height = 44;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPadding,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DateHeaderDelegate old) => old.label != label;
}

// ── Individual timeline entry card ────────────────────────────────────────────

class _TimelineEntry extends StatefulWidget {
  const _TimelineEntry({required this.entry, this.habit});

  final ProofEntry entry;
  final Habit? habit;

  @override
  State<_TimelineEntry> createState() => _TimelineEntryState();
}

class _TimelineEntryState extends State<_TimelineEntry> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_TimelineEntry old) {
    super.didUpdateWidget(old);
    if (old.entry.imagePath != widget.entry.imagePath) _load();
  }

  Future<void> _load() async {
    final f = await ImageUtils.fileFromRelativePath(widget.entry.imagePath);
    if (mounted) setState(() => _file = f);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenPadding,
        vertical: 5,
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(context)
            .pushNamed(AppRoutes.proofDetail, arguments: widget.entry.id),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Hero(
                tag: 'proof_${widget.entry.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.cardRadius),
                    bottomLeft: Radius.circular(AppConstants.cardRadius),
                  ),
                  child: _file != null
                      ? Image.file(
                          _file!,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          cacheWidth: 176,
                        )
                      : ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: const SizedBox(
                            width: 88,
                            height: 88,
                            child: Icon(Icons.image_outlined, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Habit name + emoji
                      Row(
                        children: [
                          if (widget.habit != null) ...[
                            Text(
                              widget.habit!.emoji,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.habit!.name,
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            Expanded(
                              child: Text(
                                'Deleted habit',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Time
                      Text(
                        AppDateUtils.formatTime(widget.entry.completedAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      // Note preview
                      if (widget.entry.note != null &&
                          widget.entry.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.entry.note!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Chevron
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 12),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

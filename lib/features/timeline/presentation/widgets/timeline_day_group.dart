import 'package:flutter/material.dart';
import '../../../habits/data/models/habit.dart';
import '../../../proof/data/models/proof_entry.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/image_utils.dart';
import 'dart:io';

class TimelineDayGroup extends StatelessWidget {
  const TimelineDayGroup({
    super.key,
    required this.date,
    required this.entries,
    required this.habitMap,
  });

  final DateTime date;
  final List<ProofEntry> entries;
  final Map<String, Habit> habitMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky date header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            AppDateUtils.friendlyDate(date),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        // Entries
        ...entries.map((entry) {
          final habit = habitMap[entry.habitId];
          return _TimelineEntry(entry: entry, habit: habit);
        }),
      ],
    );
  }
}

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

  Future<void> _load() async {
    final f = await ImageUtils.fileFromRelativePath(widget.entry.imagePath);
    if (mounted) setState(() => _file = f);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRoutes.proofDetail, arguments: widget.entry.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Container(
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
          child: Row(
            children: [
              // Photo thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: _file != null
                    ? Hero(
                        tag: 'proof_${widget.entry.id}',
                        child: Image.file(
                          _file!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          cacheWidth: 160,
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Icon(Icons.image_outlined),
                      ),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.habit != null) ...[
                            Text(widget.habit!.emoji,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.habit!.name,
                                style:
                                    Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            Text(
                              'Unknown habit',
                              style:
                                  Theme.of(context).textTheme.titleSmall,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppDateUtils.formatTime(widget.entry.completedAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (widget.entry.note != null &&
                          widget.entry.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.entry.note!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

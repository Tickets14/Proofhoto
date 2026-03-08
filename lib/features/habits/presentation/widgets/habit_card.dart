import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/habit.dart';
import '../../presentation/controllers/habit_controller.dart';
import '../../../proof/data/models/proof_entry.dart';
import '../../../proof/presentation/controllers/proof_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/video_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/responsive_utils.dart';

class HabitCard extends ConsumerWidget {
  const HabitCard({
    super.key,
    required this.habit,
    this.isFrozen = false,
    this.dragIndex,
  });

  final Habit habit;
  final bool isFrozen;

  /// When non-null, a drag handle is shown for reordering.
  final int? dragIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = ResponsiveSpec.of(context);
    final compact = responsive.isCompact;
    final isCompleted = ref.watch(isCompletedTodayProvider(habit.id));
    final proofEntry = isCompleted
        ? ref.watch(habitProofProvider(habit.id)).firstOrNull
        : null;
    final streak = ref.watch(habitStreakProvider(habit.id));
    final habitColor = Color(habit.colorValue);
    final cs = Theme.of(context).colorScheme;

    // M3 surface roles: completed = tonal surface with habit colour tint,
    // frozen = ice tint, default = surfaceContainerLow
    final cardColor = isCompleted
        ? Color.alphaBlend(
            habitColor.withValues(alpha: 0.06), cs.surfaceContainerLow)
        : cs.surfaceContainerLow;

    final borderColor = isCompleted
        ? habitColor.withValues(alpha: 0.35)
        : isFrozen
            ? Colors.lightBlue.withValues(alpha: 0.45)
            : cs.outlineVariant;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: compact ? 3 : 4,
      ),
      child: GestureDetector(
        onTap: () => _onTap(context, isCompleted, proofEntry),
        onLongPress: () => Navigator.of(context)
            .pushNamed(AppRoutes.editHabit, arguments: habit.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            children: [
              _EmojiIcon(
                emoji: habit.emoji,
                color: habitColor,
                isCompleted: isCompleted,
                isFrozen: isFrozen,
                compact: compact,
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: cs.onSurfaceVariant,
                            color: isCompleted
                                ? cs.onSurfaceVariant
                                : cs.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _StatusRow(
                      isCompleted: isCompleted,
                      isFrozen: isFrozen,
                      streak: streak,
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              _RightWidget(
                isCompleted: isCompleted,
                isFrozen: isFrozen,
                proofEntry: proofEntry,
                habitId: habit.id,
                habitColor: habitColor,
                compact: compact,
              ),
              if (dragIndex != null) ...[
                const SizedBox(width: 6),
                ReorderableDragStartListener(
                  index: dragIndex!,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.drag_handle_rounded,
                        size: 20, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, bool isCompleted, ProofEntry? proof) {
    if (isCompleted && proof != null) {
      Navigator.of(context)
          .pushNamed(AppRoutes.proofDetail, arguments: proof.id);
    } else if (!isCompleted && !isFrozen) {
      Navigator.of(context)
          .pushNamed(AppRoutes.captureProof, arguments: habit.id);
    }
  }
}

// ── Emoji icon ────────────────────────────────────────────────────────────────

class _EmojiIcon extends StatelessWidget {
  const _EmojiIcon({
    required this.emoji,
    required this.color,
    required this.isCompleted,
    required this.isFrozen,
    required this.compact,
  });

  final String emoji;
  final Color color;
  final bool isCompleted;
  final bool isFrozen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bg = isFrozen
        ? Colors.lightBlue.withValues(alpha: 0.15)
        : color.withValues(alpha: isCompleted ? 0.18 : 0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: compact ? 42 : 48,
      height: compact ? 42 : 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      alignment: Alignment.center,
      child: Text(
        isFrozen ? '❄️' : emoji,
        style: TextStyle(fontSize: compact ? 20 : 24),
      ),
    );
  }
}

// ── Status row ────────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.isCompleted,
    required this.isFrozen,
    required this.streak,
  });

  final bool isCompleted;
  final bool isFrozen;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme.labelSmall;

    if (isFrozen) {
      return Text(
        '❄️ Streak frozen',
        style: ts?.copyWith(color: Colors.lightBlue.shade300),
      );
    }

    return Row(
      children: [
        if (streak > 0) ...[
          Text(
            '🔥 $streak',
            style: ts?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text('·', style: ts?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            isCompleted ? 'Done' : 'Tap to add proof',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: isCompleted
                ? ts?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  )
                : ts?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ── Right widget ──────────────────────────────────────────────────────────────

class _RightWidget extends ConsumerWidget {
  const _RightWidget({
    required this.isCompleted,
    required this.isFrozen,
    required this.proofEntry,
    required this.habitId,
    required this.habitColor,
    required this.compact,
  });

  final bool isCompleted;
  final bool isFrozen;
  final ProofEntry? proofEntry;
  final String habitId;
  final Color habitColor;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isCompleted && proofEntry != null) {
      return _ProofThumbnail(
        imagePath: proofEntry!.imagePath,
        proofId: proofEntry!.id,
        isVideo: proofEntry!.isVideo,
        compact: compact,
      );
    }

    if (isFrozen) {
      return SizedBox(
        width: compact ? 40 : 44,
        height: compact ? 40 : 44,
        child: Center(
          child: Text('❄️', style: TextStyle(fontSize: compact ? 20 : 24)),
        ),
      );
    }

    return Container(
      width: compact ? 40 : 44,
      height: compact ? 40 : 44,
      decoration: BoxDecoration(
        color: habitColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Icon(
        Icons.camera_alt_outlined,
        color: habitColor,
        size: compact ? 18 : 20,
      ),
    );
  }
}

// ── Proof thumbnail ───────────────────────────────────────────────────────────

class _ProofThumbnail extends StatefulWidget {
  const _ProofThumbnail({
    required this.imagePath,
    required this.proofId,
    required this.isVideo,
    required this.compact,
  });
  final String imagePath;
  final String proofId;
  final bool isVideo;
  final bool compact;

  @override
  State<_ProofThumbnail> createState() => _ProofThumbnailState();
}

class _ProofThumbnailState extends State<_ProofThumbnail> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    final File? f;
    if (widget.isVideo) {
      f = await VideoUtils.thumbnailFile(widget.imagePath);
    } else {
      f = await ImageUtils.fileFromRelativePath(widget.imagePath);
    }
    if (mounted) setState(() => _file = f);
  }

  @override
  Widget build(BuildContext context) {
    if (_file == null) {
      return Container(
        width: widget.compact ? 40 : 44,
        height: widget.compact ? 40 : 44,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(widget.compact ? 10 : 12),
        ),
        child: Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: widget.compact ? 20 : 22,
        ),
      );
    }

    return Hero(
      tag: 'proof_${widget.proofId}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.compact ? 10 : 12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.file(
              _file!,
              width: widget.compact ? 40 : 44,
              height: widget.compact ? 40 : 44,
              fit: BoxFit.cover,
              cacheWidth: widget.compact ? 80 : 88,
            ),
            if (widget.isVideo)
              Container(
                width: widget.compact ? 16 : 18,
                height: widget.compact ? 16 : 18,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: widget.compact ? 11 : 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

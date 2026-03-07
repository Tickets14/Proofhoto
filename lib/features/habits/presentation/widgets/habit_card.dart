import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/habit.dart';
import '../../presentation/controllers/habit_controller.dart';
import '../../../proof/data/models/proof_entry.dart';
import '../../../proof/presentation/controllers/proof_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/router/app_router.dart';

class HabitCard extends ConsumerWidget {
  const HabitCard({
    super.key,
    required this.habit,
    this.isFrozen = false,
    this.dragIndex,
  });

  final Habit habit;
  final bool isFrozen;
  /// When non-null, a drag handle is shown that lets the user reorder the card
  /// in a [SliverReorderableList]. The value is the item's current index.
  final int? dragIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = ref.watch(isCompletedTodayProvider(habit.id));
    final proofEntry = isCompleted
        ? ref.watch(habitProofProvider(habit.id)).firstOrNull
        : null;
    final streak = ref.watch(habitStreakProvider(habit.id));
    final color = Color(habit.colorValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: () => _onTap(context, isCompleted, proofEntry),
        onLongPress: () =>
            Navigator.of(context).pushNamed(AppRoutes.editHabit, arguments: habit.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? color.withOpacity(0.4)
                  : isFrozen
                      ? Colors.lightBlue.withOpacity(0.4)
                      : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Emoji icon
              _EmojiIcon(
                emoji: habit.emoji,
                color: color,
                isCompleted: isCompleted,
                isFrozen: isFrozen,
              ),
              const SizedBox(width: 14),
              // Name + streak + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (streak > 0) ...[
                          Text(
                            '🔥 $streak',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _StatusChip(
                          isCompleted: isCompleted,
                          isFrozen: isFrozen,
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Right side: proof thumbnail or action indicator
              _RightWidget(
                isCompleted: isCompleted,
                isFrozen: isFrozen,
                proofEntry: proofEntry,
                habitId: habit.id,
                color: color,
              ),
              if (dragIndex != null) ...[
                const SizedBox(width: 6),
                ReorderableDragStartListener(
                  index: dragIndex!,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 20,
                      color: Colors.grey,
                    ),
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

class _EmojiIcon extends StatelessWidget {
  const _EmojiIcon({
    required this.emoji,
    required this.color,
    required this.isCompleted,
    required this.isFrozen,
  });

  final String emoji;
  final Color color;
  final bool isCompleted;
  final bool isFrozen;

  @override
  Widget build(BuildContext context) {
    final bg = isFrozen
        ? Colors.lightBlue.withOpacity(0.15)
        : isCompleted
            ? color.withOpacity(0.15)
            : color.withOpacity(0.1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        isFrozen ? '❄️' : emoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.isCompleted,
    required this.isFrozen,
    required this.color,
  });

  final bool isCompleted;
  final bool isFrozen;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (isFrozen) {
      return Text(
        '❄️ Streak frozen',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: Colors.lightBlue),
      );
    }
    if (isCompleted) {
      return Text(
        '✅ Done',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.success),
      );
    }
    return Text(
      'Tap to add proof',
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}

class _RightWidget extends ConsumerWidget {
  const _RightWidget({
    required this.isCompleted,
    required this.isFrozen,
    required this.proofEntry,
    required this.habitId,
    required this.color,
  });

  final bool isCompleted;
  final bool isFrozen;
  final ProofEntry? proofEntry;
  final String habitId;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isCompleted && proofEntry != null) {
      return _ProofThumbnail(imagePath: proofEntry!.imagePath, proofId: proofEntry!.id);
    }

    if (isFrozen) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Text('❄️', style: TextStyle(fontSize: 24)),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.camera_alt_outlined, color: color, size: 20),
    );
  }
}

class _ProofThumbnail extends StatefulWidget {
  const _ProofThumbnail({required this.imagePath, required this.proofId});
  final String imagePath;
  final String proofId;

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
    final f = await ImageUtils.fileFromRelativePath(widget.imagePath);
    if (mounted) setState(() => _file = f);
  }

  @override
  Widget build(BuildContext context) {
    if (_file == null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check_circle, color: AppColors.success, size: 22),
      );
    }

    return Hero(
      tag: 'proof_${widget.proofId}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _file!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          cacheWidth: 88,
        ),
      ),
    );
  }
}

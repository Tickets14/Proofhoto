import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../habits/presentation/controllers/habit_controller.dart';
import '../../../habits/data/models/habit.dart';
import '../../../habits/presentation/widgets/daily_progress_ring.dart';
import '../../../proof/presentation/controllers/proof_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/app_date_utils.dart';

/// In-memory provider: stores today's date string if the user dismissed Focus
/// Mode without completing all habits (so we don't nag them again today).
final focusModeDismissedTodayProvider = StateProvider<String?>((ref) => null);

class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> {
  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List<Habit> _computeIncomplete(List<Habit> todayHabits, List allEntries) {
    final today = DateTime.now();
    return todayHabits
        .where((h) => !allEntries.any((e) =>
            e.habitId == h.id &&
            AppDateUtils.isSameDay(e.completedAt.toLocal(), today)))
        .toList();
  }

  /// Navigate to CaptureProofScreen and, when it returns, refresh the list.
  /// This is the only reliable way to ensure the list updates — awaiting the
  /// navigation future guarantees we react AFTER the proof has been saved and
  /// CaptureProofScreen has fully popped.
  Future<void> _navigateToCapture(String habitId) async {
    await Navigator.of(context)
        .pushNamed(AppRoutes.captureProof, arguments: habitId);

    if (!mounted) return;

    // Re-read current state to decide what to do next.
    final todayHabits = ref.read(todayHabitsProvider);
    final allEntries = ref.read(allProofProvider);
    final incomplete = _computeIncomplete(todayHabits, allEntries);

    if (incomplete.isEmpty && todayHabits.isNotEmpty) {
      // All done — pop Focus Mode so the user lands on the home screen.
      Navigator.of(context).pop();
    } else {
      // Still habits remaining — refresh the list.
      setState(() {});
    }
  }

  Future<void> _confirmSkip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip Focus Mode?'),
        content: const Text(
            'You can still complete your habits from the home screen. '
            'Focus Mode won\'t appear again today.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay focused'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(focusModeDismissedTodayProvider.notifier).state = _todayStr();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayHabits = ref.watch(todayHabitsProvider);
    final allEntries = ref.watch(allProofProvider);
    final completed = ref.watch(todayCompletedCountProvider);
    final total = todayHabits.length;
    final incompleteHabits = _computeIncomplete(todayHabits, allEntries);
    final allDone = incompleteHabits.isEmpty && total > 0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus Time',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            allDone
                                ? 'All done! Great work today.'
                                : '${incompleteHabits.length} habit${incompleteHabits.length == 1 ? '' : 's'} left to complete',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withValues(alpha: 0.85),
                                ),
                          ),
                        ],
                      ),
                    ),
                    DailyProgressRing(
                      completed: completed,
                      total: total,
                    ),
                  ],
                ),
              ),

              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                  ),
                  child: allDone
                      ? _AllDoneContent(
                          onClose: () => Navigator.of(context).pop())
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          itemCount: incompleteHabits.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _FocusHabitTile(
                            habit: incompleteHabits[i],
                            onProveIt: () =>
                                _navigateToCapture(incompleteHabits[i].id),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: allDone
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: TextButton(
                  onPressed: _confirmSkip,
                  child: Text(
                    'Skip for today',
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Habit tile ────────────────────────────────────────────────────────────────

class _FocusHabitTile extends StatelessWidget {
  const _FocusHabitTile({required this.habit, required this.onProveIt});
  final Habit habit;
  final VoidCallback onProveIt;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Text(
          habit.emoji,
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(
          habit.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Tap to capture proof'),
        trailing: FilledButton.tonal(
          onPressed: onProveIt,
          child: const Text('Prove it'),
        ),
      ),
    );
  }
}

// ── All done state ────────────────────────────────────────────────────────────

class _AllDoneContent extends StatelessWidget {
  const _AllDoneContent({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              'All habits complete!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You crushed it today. Keep the momentum going!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onClose,
              child: const Text('Continue to app'),
            ),
          ],
        ),
      ),
    );
  }
}

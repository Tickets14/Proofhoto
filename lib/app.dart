import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/app_date_utils.dart';
import 'features/habits/presentation/screens/home_screen.dart';
import 'features/habits/presentation/screens/create_habit_screen.dart';
import 'features/proof/presentation/screens/capture_proof_screen.dart';
import 'features/proof/presentation/screens/proof_detail_screen.dart';
import 'features/timeline/presentation/screens/timeline_screen.dart';
import 'features/stats/presentation/screens/stats_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';
import 'features/habits/presentation/controllers/habit_controller.dart';
import 'features/proof/presentation/controllers/proof_controller.dart';
import 'features/stats/domain/stats_service.dart';
import 'features/stats/presentation/widgets/weekly_review_sheet.dart';
import 'features/achievements/presentation/controllers/achievement_controller.dart';
import 'features/achievements/presentation/screens/badges_screen.dart';
import 'features/achievements/presentation/widgets/achievement_popup.dart';
import 'shared/widgets/app_bottom_nav.dart';

class ProofApp extends ConsumerWidget {
  const ProofApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Proofhoto',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRoutes.navigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const _AppShell(),
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.createHabit:
        return _slide(const CreateHabitScreen());

      case AppRoutes.editHabit:
        final habitId = settings.arguments as String?;
        return _slide(CreateHabitScreen(habitId: habitId));

      case AppRoutes.captureProof:
        final habitId = settings.arguments as String;
        return _slide(CaptureProofScreen(habitId: habitId));

      case AppRoutes.proofDetail:
        final proofId = settings.arguments as String;
        return _slide(ProofDetailScreen(proofId: proofId));

      case AppRoutes.badges:
        return _slide(const BadgesScreen());

      default:
        return null;
    }
  }

  static PageRouteBuilder<T> _slide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}

// ── App Shell with IndexedStack navigation ─────────────────────────────────

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell();

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  int _currentIndex = 0;
  bool _reviewScheduled = false;
  bool _isShowingAchievementPopup = false;

  static const _screens = [
    HomeScreen(),
    TimelineScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _maybeShowWeeklyReview();
      await ref.read(achievementsProvider.notifier).checkAndAward();
      if (mounted) _showNextUnseenAchievement();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPendingNotification();
  }

  void _checkPendingNotification() {
    final habitId = AppRoutes.pendingNotificationHabitId;
    if (habitId != null) {
      AppRoutes.pendingNotificationHabitId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context)
              .pushNamed(AppRoutes.captureProof, arguments: habitId);
        }
      });
    }
  }

  void _maybeShowWeeklyReview() {
    if (_reviewScheduled) return;
    final now = DateTime.now();
    if (now.weekday != DateTime.monday) return;

    final settings = ref.read(settingsProvider);
    final currentWeek = AppDateUtils.isoWeekString(now);
    if (settings.lastReviewShownWeek == currentWeek) return;

    _reviewScheduled = true;
    _showWeeklyReview(previousWeek: true);
  }

  void _showNextUnseenAchievement() {
    if (!mounted || _isShowingAchievementPopup) return;
    final unseen = ref.read(unseenAchievementsProvider);
    if (unseen.isEmpty) return;

    _isShowingAchievementPopup = true;
    final achievement = unseen.first;
    final habits = ref.read(habitsProvider);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AchievementPopup(
        achievement: achievement,
        habits: habits,
        onDismiss: () async {
          Navigator.of(context).pop();
          await ref
              .read(achievementsProvider.notifier)
              .markAsSeen(achievement.id, achievement.habitId);
          _isShowingAchievementPopup = false;
          _showNextUnseenAchievement();
        },
      ),
    );
  }

  void _showWeeklyReview({bool previousWeek = false}) {
    final now = DateTime.now();
    final weekStart = previousWeek
        ? AppDateUtils.previousWeekStart(now)
        : AppDateUtils.previousWeekStart(
            now.add(const Duration(days: 7))); // most recent completed week

    final habits = ref.read(habitsProvider);
    final allEntries = ref.read(allProofProvider);
    final settings = ref.read(settingsProvider);

    final review = StatsService.getWeeklyReview(
      weekStart: weekStart,
      habits: habits,
      allEntries: allEntries,
      usedFreezes: settings.usedFreezes,
    );

    final currentWeek = AppDateUtils.isoWeekString(now);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WeeklyReviewSheet(
        review: review,
        onDismiss: () {
          Navigator.of(context).pop();
          if (previousWeek) {
            // Mark as shown so it doesn't reappear this Monday
            ref.read(settingsProvider.notifier).markReviewShown(currentWeek);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // React to newly unlocked achievements (e.g., after saving proof)
    ref.listen<List>(unseenAchievementsProvider, (prev, next) {
      if (next.isNotEmpty && !_isShowingAchievementPopup) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showNextUnseenAchievement();
        });
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// Shows the Weekly Review sheet for the most recently completed Mon–Sun week.
/// Can be called from any screen that has a [BuildContext] and [WidgetRef].
void showWeeklyReview(BuildContext context, WidgetRef ref) {
  final now = DateTime.now();
  // "Most recent completed week" = previous Mon–Sun, regardless of current day
  final weekStart = AppDateUtils.previousWeekStart(now);

  final habits = ref.read(habitsProvider);
  final allEntries = ref.read(allProofProvider);
  final settings = ref.read(settingsProvider);

  final review = StatsService.getWeeklyReview(
    weekStart: weekStart,
    habits: habits,
    allEntries: allEntries,
    usedFreezes: settings.usedFreezes,
  );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WeeklyReviewSheet(review: review),
  );
}

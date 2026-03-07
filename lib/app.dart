import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/habits/presentation/screens/home_screen.dart';
import 'features/habits/presentation/screens/create_habit_screen.dart';
import 'features/proof/presentation/screens/capture_proof_screen.dart';
import 'features/proof/presentation/screens/proof_detail_screen.dart';
import 'features/timeline/presentation/screens/timeline_screen.dart';
import 'features/stats/presentation/screens/stats_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';
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

  static const _screens = [
    HomeScreen(),
    TimelineScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

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

  @override
  Widget build(BuildContext context) {
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

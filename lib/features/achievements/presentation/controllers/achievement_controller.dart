import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/achievement.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../domain/achievement_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../habits/presentation/controllers/habit_controller.dart';
import '../../../proof/presentation/controllers/proof_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(
      Hive.box<Achievement>(AppConstants.achievementsBox));
});

final achievementsProvider =
    StateNotifierProvider<AchievementController, List<Achievement>>(
  (ref) => AchievementController(ref),
);

/// Achievements that have not yet shown their unlock popup.
final unseenAchievementsProvider = Provider<List<Achievement>>((ref) {
  final all = ref.watch(achievementsProvider);
  return all.where((a) => !a.hasBeenSeen).toList()
    ..sort((a, b) => a.unlockedAt.compareTo(b.unlockedAt));
});

// ── Controller ─────────────────────────────────────────────────────────────

class AchievementController extends StateNotifier<List<Achievement>> {
  AchievementController(this._ref) : super([]) {
    _load();
    _listenForChanges();
  }

  final Ref _ref;

  AchievementRepository get _repo => _ref.read(achievementRepositoryProvider);

  void _load() {
    state = _repo.getAll()
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
  }

  void _listenForChanges() {
    _repo.watch().listen((_) => _load());
  }

  /// Runs the full badge check against current app state.
  /// Saves any newly unlocked achievements and updates state.
  Future<void> checkAndAward() async {
    final habits = _ref.read(habitsProvider);
    final allEntries = _ref.read(allProofProvider);
    final settings = _ref.read(settingsProvider);

    final newOnes = AchievementService.checkAll(
      habits: habits,
      allEntries: allEntries,
      existing: state,
      usedFreezes: settings.usedFreezes,
    );

    for (final a in newOnes) {
      await _repo.save(a);
    }

    if (newOnes.isNotEmpty) _load();
  }

  /// Marks a specific achievement as seen (popup dismissed).
  Future<void> markAsSeen(String badgeId, String habitId) async {
    final a = _repo.getByKey(badgeId, habitId);
    if (a == null) return;
    a.hasBeenSeen = true;
    await _repo.save(a);
    _load();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/notification_utils.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(Hive.box<UserSettings>(AppConstants.settingsBox));
});

final settingsProvider =
    StateNotifierProvider<SettingsController, UserSettings>(
  (ref) => SettingsController(ref),
);

/// Resolved ThemeMode based on user preference.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  switch (settings.themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});

// ── Controller ─────────────────────────────────────────────────────────────

class SettingsController extends StateNotifier<UserSettings> {
  final Ref _ref;

  SettingsController(this._ref)
      : super(_ref.read(settingsRepositoryProvider).settings) {
    _listenForChanges();
  }

  SettingsRepository get _repo => _ref.read(settingsRepositoryProvider);

  void _listenForChanges() {
    _repo.watch().listen((_) {
      state = _repo.settings;
    });
  }

  Future<void> setThemeMode(String mode) async {
    final updated = state.copyWith(
      themeMode: mode,
      isDarkMode: mode == 'dark',
    );
    await _repo.save(updated);
    state = updated;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationUtils.requestPermission();
      if (!granted) return;
    }
    final updated = state.copyWith(notificationsEnabled: enabled);
    await _repo.save(updated);
    state = updated;
  }

  Future<void> useStreakFreeze(String dateStr) async {
    if (state.streakFreezeCount <= 0) return;
    if (state.usedFreezes.contains(dateStr)) return;
    final updated = state.copyWith(
      streakFreezeCount: state.streakFreezeCount - 1,
      usedFreezes: [...state.usedFreezes, dateStr],
    );
    await _repo.save(updated);
    state = updated;
  }

  Future<void> addFreeze() async {
    if (state.streakFreezeCount >= AppConstants.maxFreezesbanked) return;
    final updated = state.copyWith(
      streakFreezeCount: state.streakFreezeCount + 1,
    );
    await _repo.save(updated);
    state = updated;
  }

  bool isFreezeUsed(String dateStr) => state.usedFreezes.contains(dateStr);
}

import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_settings.dart';
import '../../../../core/constants/app_constants.dart';

class SettingsRepository {
  final Box<UserSettings> _box;

  SettingsRepository(this._box);

  UserSettings get settings {
    var s = _box.get(AppConstants.settingsKey);
    if (s == null) {
      s = UserSettings()
        ..isDarkMode = false
        ..notificationsEnabled = true
        ..streakFreezeCount = 0
        ..usedFreezes = []
        ..themeMode = 'system';
      _box.put(AppConstants.settingsKey, s);
    }
    return s;
  }

  Future<void> save(UserSettings s) async {
    await _box.put(AppConstants.settingsKey, s);
  }

  Stream<BoxEvent> watch() => _box.watch();
}

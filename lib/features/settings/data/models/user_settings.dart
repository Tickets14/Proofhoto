import 'package:hive_flutter/hive_flutter.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 2)
class UserSettings extends HiveObject {
  @HiveField(0)
  late bool isDarkMode;

  @HiveField(1)
  late bool notificationsEnabled;

  /// Number of streak-freeze tokens the user has banked.
  @HiveField(2)
  late int streakFreezeCount;

  /// Dates (yyyy-MM-dd) on which a freeze was consumed.
  @HiveField(3)
  late List<String> usedFreezes;

  /// Theme preference: 'light', 'dark', or 'system'.
  @HiveField(4)
  late String themeMode;

  /// Returns a new [UserSettings] instance with updated fields.
  /// Required because [HiveObject] is a mutable reference type — mutating the
  /// existing instance and reassigning to [StateNotifier.state] is a no-op
  /// (same reference → Riverpod detects no change → UI never rebuilds).
  UserSettings copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    int? streakFreezeCount,
    List<String>? usedFreezes,
    String? themeMode,
  }) {
    return UserSettings()
      ..isDarkMode = isDarkMode ?? this.isDarkMode
      ..notificationsEnabled = notificationsEnabled ?? this.notificationsEnabled
      ..streakFreezeCount = streakFreezeCount ?? this.streakFreezeCount
      ..usedFreezes = usedFreezes ?? this.usedFreezes
      ..themeMode = themeMode ?? this.themeMode;
  }
}

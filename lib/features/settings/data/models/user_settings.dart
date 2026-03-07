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

  /// ISO week string ("yyyy-Www") of the last weekly review shown.
  /// Null means the review has never been shown.
  @HiveField(5)
  String? lastReviewShownWeek;

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
    Object? lastReviewShownWeek = _sentinel,
  }) {
    return UserSettings()
      ..isDarkMode = isDarkMode ?? this.isDarkMode
      ..notificationsEnabled = notificationsEnabled ?? this.notificationsEnabled
      ..streakFreezeCount = streakFreezeCount ?? this.streakFreezeCount
      ..usedFreezes = usedFreezes ?? this.usedFreezes
      ..themeMode = themeMode ?? this.themeMode
      ..lastReviewShownWeek = identical(lastReviewShownWeek, _sentinel)
          ? this.lastReviewShownWeek
          : lastReviewShownWeek as String?;
  }

  static const _sentinel = Object();
}

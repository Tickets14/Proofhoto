import 'package:hive_flutter/hive_flutter.dart';

part 'achievement.g.dart';

@HiveType(typeId: 4)
class Achievement extends HiveObject {
  /// Badge type id, e.g. "streak_7", "first_proof".
  @HiveField(0)
  late String id;

  /// Which habit earned it, or "global" for app-wide achievements.
  @HiveField(1)
  late String habitId;

  @HiveField(2)
  late DateTime unlockedAt;

  /// False until the user has seen the unlock popup.
  @HiveField(3)
  late bool hasBeenSeen;
}

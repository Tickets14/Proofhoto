import 'package:hive_flutter/hive_flutter.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  /// Emoji used as the habit's visual icon.
  @HiveField(2)
  late String emoji;

  /// Material color integer (Color.value).
  @HiveField(3)
  late int colorValue;

  /// Days of week this habit is active: 1=Monday … 7=Sunday.
  @HiveField(4)
  late List<int> reminderDays;

  /// "HH:mm" reminder time, or null if no reminder.
  @HiveField(5)
  String? reminderTime;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  late bool isArchived;

  /// Used for manual list reordering.
  @HiveField(8)
  late int sortOrder;

  /// Optional category id. Null means uncategorized.
  @HiveField(9)
  String? categoryId;

  /// Whether this habit is scheduled for the given [weekday] (1=Mon…7=Sun).
  bool isScheduledOn(int weekday) => reminderDays.contains(weekday);
}

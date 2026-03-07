import 'package:hive_flutter/hive_flutter.dart';

part 'habit_category.g.dart';

@HiveType(typeId: 3)
class HabitCategory extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String emoji;

  /// Material color integer (Color.value).
  @HiveField(3)
  late int colorValue;

  @HiveField(4)
  late int sortOrder;
}

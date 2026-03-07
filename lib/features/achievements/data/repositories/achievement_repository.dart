import 'package:hive_flutter/hive_flutter.dart';
import '../models/achievement.dart';

class AchievementRepository {
  AchievementRepository(this._box);

  final Box<Achievement> _box;

  /// Hive key format: "{badgeId}|{habitId}"
  static String _key(String badgeId, String habitId) => '$badgeId|$habitId';

  List<Achievement> getAll() => _box.values.toList();

  bool exists(String badgeId, String habitId) =>
      _box.containsKey(_key(badgeId, habitId));

  Future<void> save(Achievement a) =>
      _box.put(_key(a.id, a.habitId), a);

  Achievement? getByKey(String badgeId, String habitId) =>
      _box.get(_key(badgeId, habitId));

  Stream<BoxEvent> watch() => _box.watch();
}

import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit_category.dart';

class CategoryRepository {
  CategoryRepository(this._box);

  final Box<HabitCategory> _box;

  List<HabitCategory> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  HabitCategory? getById(String id) =>
      _box.values.where((c) => c.id == id).firstOrNull;

  Future<void> save(HabitCategory category) =>
      _box.put(category.id, category);

  Future<void> delete(String id) => _box.delete(id);

  Stream<BoxEvent> watch() => _box.watch();
}

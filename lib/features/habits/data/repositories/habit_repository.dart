import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

class HabitRepository {
  final Box<Habit> _box;

  HabitRepository(this._box);

  List<Habit> getAll() => _box.values
      .where((h) => !h.isArchived)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Habit> getAllIncludingArchived() => _box.values.toList();

  Habit? getById(String id) {
    try {
      return _box.values.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Habit habit) async {
    await _box.put(habit.id, habit);
  }

  Future<void> archive(String id) async {
    final habit = getById(id);
    if (habit != null) {
      habit.isArchived = true;
      await habit.save();
    }
  }

  Future<void> delete(String id) async {
    final habit = getById(id);
    if (habit != null) await habit.delete();
  }

  Future<void> reorder(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final habit = getById(orderedIds[i]);
      if (habit != null) {
        habit.sortOrder = i;
        await habit.save();
      }
    }
  }

  /// Stream of changes from the habits box.
  Stream<BoxEvent> watch() => _box.watch();
}

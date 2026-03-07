import 'package:hive_flutter/hive_flutter.dart';
import '../models/proof_entry.dart';
import '../../../../core/utils/app_date_utils.dart';

class ProofRepository {
  final Box<ProofEntry> _box;

  ProofRepository(this._box);

  List<ProofEntry> getAll() => _box.values.toList()
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  List<ProofEntry> getForHabit(String habitId) =>
      _box.values.where((e) => e.habitId == habitId).toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  /// Returns the most recent entry for [habitId] on [date] (UTC calendar day),
  /// or null if none exists.
  ProofEntry? getForHabitOnDate(String habitId, DateTime date) {
    try {
      return _box.values.firstWhere(
        (e) =>
            e.habitId == habitId &&
            AppDateUtils.isSameDay(e.completedAt.toLocal(), date),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns all entries on [date] (local calendar day).
  List<ProofEntry> getForDate(DateTime date) => _box.values
      .where((e) => AppDateUtils.isSameDay(e.completedAt.toLocal(), date))
      .toList()
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  bool isCompletedToday(String habitId) {
    final today = DateTime.now();
    return getForHabitOnDate(habitId, today) != null;
  }

  Future<void> save(ProofEntry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> delete(String id) async {
    final entry = _box.get(id);
    if (entry != null) await entry.delete();
  }

  Future<void> deleteAllForHabit(String habitId) async {
    final keys = _box.values
        .where((e) => e.habitId == habitId)
        .map((e) => e.id)
        .toList();
    await _box.deleteAll(keys);
  }

  Stream<BoxEvent> watch() => _box.watch();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/habit_category.dart';
import '../../data/repositories/category_repository.dart';
import '../../../../core/constants/app_constants.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
      Hive.box<HabitCategory>(AppConstants.categoriesBox));
});

final categoriesProvider =
    StateNotifierProvider<CategoryController, List<HabitCategory>>(
  (ref) => CategoryController(ref),
);

/// The currently active filter on Home.
/// null = All, '__uncategorized__' = Uncategorized, otherwise a category id.
final categoryFilterProvider = StateProvider<String?>((ref) => null);

// ── Controller ─────────────────────────────────────────────────────────────

class CategoryController extends StateNotifier<List<HabitCategory>> {
  CategoryController(this._ref) : super([]) {
    _load();
    _listenForChanges();
  }

  final Ref _ref;
  static const _uuid = Uuid();

  CategoryRepository get _repo => _ref.read(categoryRepositoryProvider);

  void _load() {
    state = _repo.getAll();
  }

  void _listenForChanges() {
    _repo.watch().listen((_) => _load());
  }

  Future<HabitCategory> create({
    required String name,
    required String emoji,
    required int colorValue,
  }) async {
    final cat = HabitCategory()
      ..id = _uuid.v4()
      ..name = name.trim()
      ..emoji = emoji
      ..colorValue = colorValue
      ..sortOrder = state.length;
    await _repo.save(cat);
    _load();
    return cat;
  }

  Future<void> update(
    HabitCategory category, {
    String? name,
    String? emoji,
    int? colorValue,
  }) async {
    if (name != null) category.name = name.trim();
    if (emoji != null) category.emoji = emoji;
    if (colorValue != null) category.colorValue = colorValue;
    await _repo.save(category);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }
}

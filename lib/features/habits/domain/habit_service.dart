import 'package:uuid/uuid.dart';
import '../data/models/habit.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';

class HabitService {
  static const _uuid = Uuid();

  /// Builds a new Habit with validated fields and defaults.
  ///
  /// Throws [ArgumentError] if [name] is empty.
  static Habit createNew({
    required String name,
    required String emoji,
    required int colorValue,
    required List<int> reminderDays,
    String? reminderTime,
    int sortOrder = 0,
  }) {
    if (name.trim().isEmpty) throw ArgumentError('Habit name cannot be empty.');
    return Habit()
      ..id = _uuid.v4()
      ..name = name.trim()
      ..emoji = emoji
      ..colorValue = colorValue
      ..reminderDays = reminderDays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : reminderDays
      ..reminderTime = reminderTime
      ..createdAt = DateTime.now().toUtc()
      ..isArchived = false
      ..sortOrder = sortOrder;
  }

  /// Updates fields on an existing habit in place.
  static void update(
    Habit habit, {
    String? name,
    String? emoji,
    int? colorValue,
    List<int>? reminderDays,
    Object? reminderTime = _sentinel,
    int? sortOrder,
  }) {
    if (name != null) {
      if (name.trim().isEmpty) throw ArgumentError('Habit name cannot be empty.');
      habit.name = name.trim();
    }
    if (emoji != null) habit.emoji = emoji;
    if (colorValue != null) habit.colorValue = colorValue;
    if (reminderDays != null) habit.reminderDays = reminderDays;
    if (!identical(reminderTime, _sentinel)) {
      habit.reminderTime = reminderTime as String?;
    }
    if (sortOrder != null) habit.sortOrder = sortOrder;
  }

  static const _sentinel = Object();

  /// Returns today's habits for display (not archived, scheduled for today).
  static List<Habit> todayHabits(List<Habit> all) {
    final weekday = AppDateUtils.weekday(DateTime.now());
    return all
        .where((h) => !h.isArchived && h.reminderDays.contains(weekday))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Validates the habit name field.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required.';
    if (value.trim().length > AppConstants.habitNameMaxLength) {
      return 'Name must be ${AppConstants.habitNameMaxLength} characters or fewer.';
    }
    return null;
  }

  /// Returns a default color from the palette for a given index.
  static int defaultColor(int index) =>
      AppColors.habitColors[index % AppColors.habitColors.length].value;
}

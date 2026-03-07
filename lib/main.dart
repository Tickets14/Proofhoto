import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'features/habits/data/models/habit.dart';
import 'features/proof/data/models/proof_entry.dart';
import 'features/settings/data/models/user_settings.dart';
import 'features/categories/data/models/habit_category.dart';
import 'features/achievements/data/models/achievement.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/notification_utils.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize Hive ─────────────────────────────────────────────────────
  await Hive.initFlutter();

  // Register type adapters
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(ProofEntryAdapter());
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(HabitCategoryAdapter());
  Hive.registerAdapter(AchievementAdapter());

  // Open all boxes before the app starts
  await Future.wait([
    Hive.openBox<Habit>(AppConstants.habitsBox),
    Hive.openBox<ProofEntry>(AppConstants.proofEntriesBox),
    Hive.openBox<UserSettings>(AppConstants.settingsBox),
    Hive.openBox<HabitCategory>(AppConstants.categoriesBox),
    Hive.openBox<Achievement>(AppConstants.achievementsBox),
  ]);

  // ── Seed default categories on first launch ──────────────────────────────
  await _seedDefaultCategories();

  // ── Initialize Notifications ─────────────────────────────────────────────
  await NotificationUtils.initialize();

  // ── Run app ──────────────────────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: ProofApp(),
    ),
  );
}

Future<void> _seedDefaultCategories() async {
  final box = Hive.box<HabitCategory>(AppConstants.categoriesBox);
  if (box.isNotEmpty) return; // Already seeded

  const uuid = Uuid();
  const defaults = [
    (name: 'Fitness', emoji: '💪', color: 0xFFEF5350),
    (name: 'Health', emoji: '🍎', color: 0xFF66BB6A),
    (name: 'Learning', emoji: '📚', color: 0xFF42A5F5),
    (name: 'Mindfulness', emoji: '🧘', color: 0xFFAB47BC),
    (name: 'Productivity', emoji: '⚡', color: 0xFFFFCA28),
  ];

  for (var i = 0; i < defaults.length; i++) {
    final d = defaults[i];
    final cat = HabitCategory()
      ..id = uuid.v4()
      ..name = d.name
      ..emoji = d.emoji
      ..colorValue = d.color
      ..sortOrder = i;
    await box.put(cat.id, cat);
  }
}

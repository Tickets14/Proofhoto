import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/habits/data/models/habit.dart';
import 'features/proof/data/models/proof_entry.dart';
import 'features/settings/data/models/user_settings.dart';
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

  // Open all boxes before the app starts
  await Future.wait([
    Hive.openBox<Habit>(AppConstants.habitsBox),
    Hive.openBox<ProofEntry>(AppConstants.proofEntriesBox),
    Hive.openBox<UserSettings>(AppConstants.settingsBox),
  ]);

  // ── Initialize Notifications ─────────────────────────────────────────────
  await NotificationUtils.initialize();

  // ── Run app ──────────────────────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: ProofApp(),
    ),
  );
}

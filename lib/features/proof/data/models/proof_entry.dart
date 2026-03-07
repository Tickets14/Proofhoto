import 'package:hive_flutter/hive_flutter.dart';

part 'proof_entry.g.dart';

@HiveType(typeId: 1)
class ProofEntry extends HiveObject {
  @HiveField(0)
  late String id;

  /// Foreign key to [Habit.id].
  @HiveField(1)
  late String habitId;

  /// *Relative* path from the app documents directory.
  /// e.g. "proof/{habitId}/{timestamp}.jpg"
  @HiveField(2)
  late String imagePath;

  /// Optional user-written note.
  @HiveField(3)
  String? note;

  /// UTC timestamp of when the proof was submitted.
  @HiveField(4)
  late DateTime completedAt;
}

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

  /// Media type: 'image' or 'video'.
  /// Defaults to 'image' so all existing entries remain compatible.
  @HiveField(5)
  late String mediaType;

  /// Duration of the video in milliseconds. Null for image entries.
  @HiveField(6)
  int? videoDurationMs;

  bool get isVideo => mediaType == 'video';

  /// For video entries the thumbnail is stored alongside the video.
  /// For image entries this is just [imagePath].
  String get thumbnailPath =>
      isVideo ? imagePath.replaceAll('.mp4', '_thumb.jpg') : imagePath;

  /// Formatted video duration string, e.g. "00:12". Empty for images.
  String get formattedDuration {
    if (!isVideo || videoDurationMs == null) return '';
    final d = Duration(milliseconds: videoDurationMs!);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

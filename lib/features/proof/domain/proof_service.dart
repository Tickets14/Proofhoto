import 'package:uuid/uuid.dart';
import '../data/models/proof_entry.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/video_utils.dart';

class ProofService {
  static const _uuid = Uuid();

  static String? _clean(String? note) =>
      (note?.trim().isEmpty ?? true) ? null : note!.trim();

  /// Creates a new [ProofEntry] after compressing and saving an image.
  static Future<ProofEntry> createEntry({
    required String sourcePath,
    required String habitId,
    String? note,
  }) async {
    final relativePath = await ImageUtils.saveProofImage(
      sourcePath: sourcePath,
      habitId: habitId,
    );

    return ProofEntry()
      ..id = _uuid.v4()
      ..habitId = habitId
      ..imagePath = relativePath
      ..note = _clean(note)
      ..completedAt = DateTime.now().toUtc()
      ..mediaType = 'image'
      ..videoDurationMs = null;
  }

  /// Creates a new [ProofEntry] after compressing a video and generating
  /// its thumbnail. Stores duration so the UI can display it without
  /// re-reading the file.
  static Future<ProofEntry> createVideoEntry({
    required String sourcePath,
    required String habitId,
    String? note,
  }) async {
    final result = await VideoUtils.saveProofVideo(
      sourcePath: sourcePath,
      habitId: habitId,
    );

    return ProofEntry()
      ..id = _uuid.v4()
      ..habitId = habitId
      ..imagePath = result.videoPath // imagePath stores the video path
      ..note = _clean(note)
      ..completedAt = DateTime.now().toUtc()
      ..mediaType = 'video'
      ..videoDurationMs = result.durationMs;
  }

  /// Deletes the media file(s) for an entry. For videos this also removes
  /// the companion thumbnail.
  static Future<void> deleteEntry(ProofEntry entry) async {
    if (entry.isVideo) {
      await VideoUtils.deleteVideo(entry.imagePath);
    } else {
      await ImageUtils.deleteImage(entry.imagePath);
    }
  }
}

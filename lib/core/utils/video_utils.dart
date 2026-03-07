import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../constants/app_constants.dart';

abstract final class VideoUtils {
  static Future<String> _docsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Compresses a video, saves it, and generates a thumbnail.
  ///
  /// Returns a record with:
  /// - [videoPath] — relative path to the compressed video
  /// - [thumbPath] — relative path to the generated thumbnail
  /// - [durationMs] — video duration in milliseconds (may be null on failure)
  static Future<({String videoPath, String thumbPath, int? durationMs})>
      saveProofVideo({
    required String sourcePath,
    required String habitId,
  }) async {
    final docs = await _docsPath();
    final dir = Directory(p.join(docs, AppConstants.proofDir, habitId));
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final ts = DateTime.now().millisecondsSinceEpoch;
    final videoFileName = '$ts.mp4';
    final thumbFileName = '${ts}_thumb.jpg';
    final destVideoPath = p.join(dir.path, videoFileName);
    final destThumbPath = p.join(dir.path, thumbFileName);

    // Compress video to 720p medium quality
    int? durationMs;
    try {
      final info = await VideoCompress.compressVideo(
        sourcePath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      durationMs = info?.duration?.toInt();
      if (info?.file != null) {
        await info!.file!.copy(destVideoPath);
      } else {
        await File(sourcePath).copy(destVideoPath);
      }
    } catch (_) {
      // Fallback: copy original uncompressed
      await File(sourcePath).copy(destVideoPath);
    }

    // Get duration via media info if compression didn't return it
    if (durationMs == null) {
      try {
        final mediaInfo = await VideoCompress.getMediaInfo(destVideoPath);
        durationMs = mediaInfo.duration?.toInt();
      } catch (_) {}
    }

    // Generate and save thumbnail
    try {
      final thumbData = await VideoThumbnail.thumbnailData(
        video: destVideoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 75,
      );
      if (thumbData != null) {
        await File(destThumbPath).writeAsBytes(thumbData);
      }
    } catch (_) {}

    final relVideo = p.join(AppConstants.proofDir, habitId, videoFileName);
    final relThumb = p.join(AppConstants.proofDir, habitId, thumbFileName);
    return (videoPath: relVideo, thumbPath: relThumb, durationMs: durationMs);
  }

  /// Returns the duration in milliseconds for a video at [absolutePath].
  static Future<int?> getDurationMs(String absolutePath) async {
    try {
      final info = await VideoCompress.getMediaInfo(absolutePath);
      return info.duration?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Deletes a video file and its companion thumbnail.
  static Future<void> deleteVideo(String relativeVideoPath) async {
    try {
      final docs = await _docsPath();
      final absVideo = p.join(docs, relativeVideoPath);
      final absThumb = absVideo.replaceAll('.mp4', '_thumb.jpg');
      final v = File(absVideo);
      final t = File(absThumb);
      if (v.existsSync()) await v.delete();
      if (t.existsSync()) await t.delete();
    } catch (_) {}
  }

  /// Returns the absolute path to the video file from a relative path.
  static Future<String> absolutePath(String relativePath) async {
    final docs = await _docsPath();
    return p.join(docs, relativePath);
  }

  /// Returns a [File] for the video thumbnail, or null if it doesn't exist.
  static Future<File?> thumbnailFile(String relativeVideoPath) async {
    final docs = await _docsPath();
    final absThumb = p
        .join(docs, relativeVideoPath)
        .replaceAll('.mp4', '_thumb.jpg');
    final f = File(absThumb);
    return f.existsSync() ? f : null;
  }
}

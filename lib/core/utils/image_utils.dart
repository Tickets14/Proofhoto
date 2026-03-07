import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

abstract final class ImageUtils {
  /// Returns the app's documents directory path.
  static Future<String> _docsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Compresses and saves an image.
  ///
  /// [sourcePath] — path to the source image (from camera or gallery).
  /// [habitId] — used to organise files under proof/{habitId}/.
  ///
  /// Returns the *relative* path (from documents dir) to the saved image,
  /// e.g. "proof/abc123/1704067200000.jpg".
  static Future<String> saveProofImage({
    required String sourcePath,
    required String habitId,
  }) async {
    final docs = await _docsPath();
    final dir = Directory(p.join(docs, AppConstants.proofDir, habitId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = p.join(dir.path, fileName);

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      destPath,
      minWidth: AppConstants.imageMaxWidth,
      minHeight: 1,
      quality: AppConstants.imageQuality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    if (result == null) {
      // Fallback: copy original file uncompressed
      await File(sourcePath).copy(destPath);
    }

    // Return relative path
    return p.join(AppConstants.proofDir, habitId, fileName);
  }

  /// Reconstructs the absolute path from a stored relative path.
  static Future<String> absolutePath(String relativePath) async {
    final docs = await _docsPath();
    return p.join(docs, relativePath);
  }

  /// Deletes a single proof image by its relative path.
  static Future<void> deleteImage(String relativePath) async {
    try {
      final abs = await absolutePath(relativePath);
      final file = File(abs);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  /// Deletes all proof images for a habit.
  static Future<void> deleteHabitImages(String habitId) async {
    try {
      final docs = await _docsPath();
      final dir = Directory(p.join(docs, AppConstants.proofDir, habitId));
      if (dir.existsSync()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  /// Returns a [File] from a relative path, or null if it doesn't exist.
  static Future<File?> fileFromRelativePath(String relativePath) async {
    final abs = await absolutePath(relativePath);
    final file = File(abs);
    return file.existsSync() ? file : null;
  }
}

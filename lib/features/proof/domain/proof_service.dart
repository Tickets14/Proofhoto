import 'package:uuid/uuid.dart';
import '../data/models/proof_entry.dart';
import '../../../core/utils/image_utils.dart';

class ProofService {
  static const _uuid = Uuid();

  /// Creates a new ProofEntry after compressing and saving the image.
  ///
  /// [sourcePath] — raw path from the image picker.
  /// [habitId] — the habit this proof belongs to.
  /// [note] — optional text note.
  ///
  /// Returns the saved ProofEntry.
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
      ..note = note?.trim().isEmpty == true ? null : note?.trim()
      ..completedAt = DateTime.now().toUtc();
  }

  /// Deletes the image file associated with an entry before removing the entry.
  static Future<void> deleteEntry(ProofEntry entry) async {
    await ImageUtils.deleteImage(entry.imagePath);
  }
}

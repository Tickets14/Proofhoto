import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/proof_controller.dart';
import '../../data/models/proof_entry.dart';
import '../../../habits/presentation/controllers/habit_controller.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/widgets/confirm_dialog.dart';

class ProofDetailScreen extends ConsumerStatefulWidget {
  const ProofDetailScreen({super.key, required this.proofId});
  final String proofId;

  @override
  ConsumerState<ProofDetailScreen> createState() => _ProofDetailScreenState();
}

class _ProofDetailScreenState extends ConsumerState<ProofDetailScreen> {
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final entry = ref.read(allProofProvider).firstWhere(
          (e) => e.id == widget.proofId,
          orElse: () => throw Exception('Not found'),
        );
    final f = await ImageUtils.fileFromRelativePath(entry.imagePath);
    if (mounted) setState(() => _imageFile = f);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(allProofProvider);
    final entry = entries.where((e) => e.id == widget.proofId).firstOrNull;

    if (entry == null) {
      return const Scaffold(body: Center(child: Text('Proof not found')));
    }

    final habit =
        ref.read(habitRepositoryProvider).getById(entry.habitId);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: habit != null
            ? Text('${habit.emoji} ${habit.name}',
                style: const TextStyle(color: Colors.white))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _confirmDelete(entry),
          ),
        ],
      ),
      body: Column(
        children: [
          // Full-screen zoomable image
          Expanded(
            child: _imageFile != null
                ? Hero(
                    tag: 'proof_${entry.id}',
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: Image.file(
                        _imageFile!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          // Metadata strip
          Container(
            color: Colors.black87,
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      AppDateUtils.formatDateTime(entry.completedAt),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_outlined,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.note!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ProofEntry entry) async {
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete proof?',
      message:
          'This will permanently delete this photo and mark the habit as incomplete for this day.',
    );
    if (confirmed && mounted) {
      await ref.read(allProofProvider.notifier).deleteEntry(entry);
      if (mounted) navigator.pop();
    }
  }
}


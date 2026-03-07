import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
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
  File? _mediaFile;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    final entries = ref.read(allProofProvider);
    final entry = entries.where((e) => e.id == widget.proofId).firstOrNull;
    if (entry == null) return;

    final f = await ImageUtils.fileFromRelativePath(entry.imagePath);
    if (!mounted) return;
    setState(() => _mediaFile = f);

    if (entry.isVideo && f != null) {
      final ctrl = VideoPlayerController.file(f);
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      ctrl.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() => _videoController = ctrl);
      ctrl.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(allProofProvider);
    final entry = entries.where((e) => e.id == widget.proofId).firstOrNull;

    if (entry == null) {
      return const Scaffold(body: Center(child: Text('Proof not found')));
    }

    final habit = ref.read(habitRepositoryProvider).getById(entry.habitId);

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
          // ── Media area ─────────────────────────────────────────────────
          Expanded(
            child: entry.isVideo
                ? _buildVideoPlayer()
                : _buildImageViewer(entry),
          ),

          // ── Metadata / controls strip ──────────────────────────────────
          Container(
            color: Colors.black87,
            padding: EdgeInsets.fromLTRB(
              20,
              entry.isVideo ? 0 : 16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: entry.isVideo
                ? _buildVideoControls(entry)
                : _buildImageMeta(entry),
          ),
        ],
      ),
    );
  }

  // ── Image viewer ──────────────────────────────────────────────────────────

  Widget _buildImageViewer(ProofEntry entry) {
    if (_mediaFile == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return Hero(
      tag: 'proof_${entry.id}',
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Image.file(
          _mediaFile!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildImageMeta(ProofEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              AppDateUtils.formatDateTime(entry.completedAt),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        if (entry.note != null && entry.note!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.note_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.note!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Video player ──────────────────────────────────────────────────────────

  Widget _buildVideoPlayer() {
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return Center(
      child: AspectRatio(
        aspectRatio: ctrl.value.aspectRatio,
        child: VideoPlayer(ctrl),
      ),
    );
  }

  Widget _buildVideoControls(ProofEntry entry) {
    final ctrl = _videoController;
    final initialized = ctrl != null && ctrl.value.isInitialized;
    final position = initialized ? ctrl!.value.position : Duration.zero;
    final duration = initialized ? ctrl!.value.duration : Duration.zero;
    final isPlaying = initialized && ctrl!.value.isPlaying;
    final isMuted = initialized && ctrl!.value.volume == 0;
    final maxMs = duration.inMilliseconds.toDouble().clamp(1.0, double.maxFinite);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seek bar
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
          ),
          child: Slider(
            value: position.inMilliseconds.toDouble().clamp(0, maxMs),
            min: 0,
            max: maxMs,
            onChanged: initialized
                ? (v) => ctrl!.seekTo(Duration(milliseconds: v.toInt()))
                : null,
          ),
        ),

        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(position),
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(_fmt(duration),
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),

        // Play/pause + mute row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                isMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                color: Colors.white,
              ),
              onPressed: initialized
                  ? () => ctrl!.setVolume(isMuted ? 1 : 0)
                  : null,
            ),
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.white,
                size: 48,
              ),
              padding: EdgeInsets.zero,
              onPressed: initialized
                  ? () => isPlaying ? ctrl!.pause() : ctrl!.play()
                  : null,
            ),
            const SizedBox(width: 48),
          ],
        ),

        // Timestamp + note
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(
              AppDateUtils.formatDateTime(entry.completedAt),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        if (entry.note != null && entry.note!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.note_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.note!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(ProofEntry entry) async {
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete proof?',
      message:
          'This will permanently delete this ${entry.isVideo ? 'video' : 'photo'} '
          'and mark the habit as incomplete for this day.',
    );
    if (confirmed && mounted) {
      _videoController?.pause();
      await ref.read(allProofProvider.notifier).deleteEntry(entry);
      if (mounted) navigator.pop();
    }
  }
}

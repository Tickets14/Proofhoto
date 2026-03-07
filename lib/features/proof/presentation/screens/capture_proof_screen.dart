import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import '../controllers/proof_controller.dart';
import '../../../habits/data/models/habit.dart';
import '../../../habits/presentation/controllers/habit_controller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class CaptureProofScreen extends ConsumerStatefulWidget {
  const CaptureProofScreen({super.key, required this.habitId});
  final String habitId;

  @override
  ConsumerState<CaptureProofScreen> createState() => _CaptureProofScreenState();
}

class _CaptureProofScreenState extends ConsumerState<CaptureProofScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _noteCtrl = TextEditingController();

  XFile? _selectedImage;
  XFile? _selectedVideo;
  bool _isSaving = false;
  bool _showSuccess = false;

  late AnimationController _successCtrl;
  late Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Habit? get _habit => ref.read(habitRepositoryProvider).getById(widget.habitId);

  // ── Camera / gallery pickers ──────────────────────────────────────────────

  Future<void> _fromCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) _showPermissionDialog('Camera');
      return;
    }
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null && mounted) {
      setState(() {
        _selectedImage = file;
        _selectedVideo = null;
      });
    }
  }

  Future<void> _fromVideo() async {
    final camStatus = await Permission.camera.request();
    if (camStatus.isDenied || camStatus.isPermanentlyDenied) {
      if (mounted) _showPermissionDialog('Camera');
      return;
    }

    // Check microphone — video still records without audio if denied
    final micStatus = await Permission.microphone.status;
    if (micStatus.isDenied) await Permission.microphone.request();
    final micDenied = (await Permission.microphone.status).isDenied ||
        (await Permission.microphone.status).isPermanentlyDenied;

    if (micDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio unavailable — recording video only.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: AppConstants.videoMaxSeconds),
    );
    if (file != null && mounted) {
      setState(() {
        _selectedVideo = file;
        _selectedImage = null;
      });
    }
  }

  Future<void> _fromGallery() async {
    // pickMedia() accepts both images and videos
    final file = await _picker.pickMedia();
    if (file == null || !mounted) return;

    final ext = file.path.toLowerCase();
    final isVideo = ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.m4v');

    setState(() {
      if (isVideo) {
        _selectedVideo = file;
        _selectedImage = null;
      } else {
        _selectedImage = file;
        _selectedVideo = null;
      }
    });
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_selectedImage == null && _selectedVideo == null) return;
    setState(() => _isSaving = true);

    try {
      final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
      if (_selectedVideo != null) {
        await ref.read(allProofProvider.notifier).addVideoProof(
              sourcePath: _selectedVideo!.path,
              habitId: widget.habitId,
              note: note,
            );
      } else {
        await ref.read(allProofProvider.notifier).addProof(
              sourcePath: _selectedImage!.path,
              habitId: widget.habitId,
              note: note,
            );
      }
      await ref.read(habitsProvider.notifier).checkMilestone(widget.habitId);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _showSuccess = true;
        });
        _successCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save proof: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$permission Access Needed'),
        content: Text(
          'Proofhoto needs access to your $permission to capture habit evidence. '
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habit = _habit;
    return Scaffold(
      appBar: AppBar(
        title: Text(habit != null ? '${habit.emoji} ${habit.name}' : 'Add Proof'),
      ),
      body: _showSuccess
          ? _SuccessView(animation: _successAnim)
          : _selectedVideo != null
              ? _VideoPreviewView(
                  videoPath: _selectedVideo!.path,
                  noteCtrl: _noteCtrl,
                  isSaving: _isSaving,
                  onRetake: () => setState(() => _selectedVideo = null),
                  onSave: _save,
                )
              : _selectedImage != null
                  ? _PreviewView(
                      imagePath: _selectedImage!.path,
                      noteCtrl: _noteCtrl,
                      isSaving: _isSaving,
                      onRetake: () => setState(() => _selectedImage = null),
                      onSave: _save,
                    )
                  : _PickerView(
                      onCamera: _fromCamera,
                      onVideo: _fromVideo,
                      onGallery: _fromGallery,
                    ),
    );
  }
}

// ── Picker view ───────────────────────────────────────────────────────────────

class _PickerView extends StatelessWidget {
  const _PickerView({
    required this.onCamera,
    required this.onVideo,
    required this.onGallery,
  });
  final VoidCallback onCamera;
  final VoidCallback onVideo;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            'How would you like to capture your proof?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A photo or short video is required to mark this habit as complete.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _PickerButton(
            icon: Icons.camera_alt_rounded,
            label: 'Take a Photo',
            subtitle: 'Use your camera',
            color: AppColors.primary,
            onTap: onCamera,
          ),
          const SizedBox(height: 16),
          _PickerButton(
            icon: Icons.videocam_rounded,
            label: 'Record Video',
            subtitle: 'Up to ${AppConstants.videoMaxSeconds} seconds',
            color: Colors.deepPurple,
            onTap: onVideo,
          ),
          const SizedBox(height: 16),
          _PickerButton(
            icon: Icons.photo_library_rounded,
            label: 'Choose from Gallery',
            subtitle: 'Select a photo or video',
            color: AppColors.secondary,
            onTap: onGallery,
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: color)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo preview view ────────────────────────────────────────────────────────

class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.imagePath,
    required this.noteCtrl,
    required this.isSaving,
    required this.onRetake,
    required this.onSave,
  });
  final String imagePath;
  final TextEditingController noteCtrl;
  final bool isSaving;
  final VoidCallback onRetake;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Image.file(File(imagePath),
                width: double.infinity, fit: BoxFit.cover),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppConstants.screenPadding,
            16,
            AppConstants.screenPadding,
            MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                16,
          ),
          child: Column(
            children: [
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'How did it go? (optional)',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
                maxLines: 2,
                maxLength: AppConstants.noteMaxLength,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onRetake,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : onSave,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(isSaving ? 'Saving…' : 'Save Proof'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Video preview view ────────────────────────────────────────────────────────

class _VideoPreviewView extends StatefulWidget {
  const _VideoPreviewView({
    required this.videoPath,
    required this.noteCtrl,
    required this.isSaving,
    required this.onRetake,
    required this.onSave,
  });
  final String videoPath;
  final TextEditingController noteCtrl;
  final bool isSaving;
  final VoidCallback onRetake;
  final VoidCallback onSave;

  @override
  State<_VideoPreviewView> createState() => _VideoPreviewViewState();
}

class _VideoPreviewViewState extends State<_VideoPreviewView> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    await _controller.initialize();
    _controller.addListener(_onUpdate);
    if (mounted) setState(() => _initialized = true);
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    // Auto-reset when playback reaches the end
    if (_controller.value.isInitialized &&
        !_controller.value.isPlaying &&
        _controller.value.position >= _controller.value.duration) {
      _controller.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final duration =
        _initialized ? _controller.value.duration : Duration.zero;
    final position =
        _initialized ? _controller.value.position : Duration.zero;
    final isPlaying = _initialized && _controller.value.isPlaying;
    final isMuted = _initialized && _controller.value.volume == 0;
    final isValid =
        !_initialized || duration.inSeconds <= AppConstants.videoMaxSeconds;
    final maxMs =
        duration.inMilliseconds.toDouble().clamp(1.0, double.maxFinite);

    return Column(
      children: [
        // ── Video area ───────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: _initialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),

        // ── Controls ─────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppConstants.screenPadding,
            8,
            AppConstants.screenPadding,
            MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Duration warning
              if (_initialized && !isValid)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Video must be ${AppConstants.videoMaxSeconds} seconds or less. '
                    'Please choose a shorter clip.',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              // Seek bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: position.inMilliseconds
                      .toDouble()
                      .clamp(0, maxMs),
                  min: 0,
                  max: maxMs,
                  onChanged: _initialized
                      ? (v) => _controller
                          .seekTo(Duration(milliseconds: v.toInt()))
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
                        style: Theme.of(context).textTheme.labelSmall),
                    Text(
                      _fmt(duration),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isValid ? null : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(isMuted
                        ? Icons.volume_off_outlined
                        : Icons.volume_up_outlined),
                    onPressed: _initialized
                        ? () => _controller.setVolume(isMuted ? 1 : 0)
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 48,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: _initialized
                        ? () =>
                            isPlaying ? _controller.pause() : _controller.play()
                        : null,
                  ),
                  const SizedBox(width: 48), // visual balance
                ],
              ),
              const SizedBox(height: 4),

              // Note
              TextField(
                controller: widget.noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'How did it go? (optional)',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
                maxLines: 2,
                maxLength: AppConstants.noteMaxLength,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onRetake,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          (widget.isSaving || !isValid || !_initialized)
                              ? null
                              : widget.onSave,
                      icon: widget.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label:
                          Text(widget.isSaving ? 'Saving…' : 'Save Proof'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Success view ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: animation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 56),
            ),
            const SizedBox(height: 20),
            Text('Habit completed!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Your proof has been saved.',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

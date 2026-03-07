import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/proof_controller.dart';
import '../../../habits/data/models/habit.dart';
import '../../../habits/presentation/controllers/habit_controller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class CaptureProofScreen extends ConsumerStatefulWidget {
  const CaptureProofScreen({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<CaptureProofScreen> createState() =>
      _CaptureProofScreenState();
}

class _CaptureProofScreenState extends ConsumerState<CaptureProofScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _noteCtrl = TextEditingController();
  XFile? _selectedImage;
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
    _successAnim = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Habit? get _habit =>
      ref.read(habitRepositoryProvider).getById(widget.habitId);

  @override
  Widget build(BuildContext context) {
    final habit = _habit;

    return Scaffold(
      appBar: AppBar(
        title: Text(habit != null
            ? '${habit.emoji} ${habit.name}'
            : 'Add Proof'),
      ),
      body: _showSuccess
          ? _SuccessView(animation: _successAnim)
          : _selectedImage == null
              ? _PickerView(onCamera: _fromCamera, onGallery: _fromGallery)
              : _PreviewView(
                  imagePath: _selectedImage!.path,
                  noteCtrl: _noteCtrl,
                  isSaving: _isSaving,
                  onRetake: () => setState(() => _selectedImage = null),
                  onSave: _save,
                ),
    );
  }

  Future<void> _fromCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) _showPermissionDialog('Camera');
      return;
    }
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null && mounted) setState(() => _selectedImage = file);
  }

  Future<void> _fromGallery() async {
    final status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) _showPermissionDialog('Photo Library');
      return;
    }
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) setState(() => _selectedImage = file);
  }

  Future<void> _save() async {
    if (_selectedImage == null) return;
    setState(() => _isSaving = true);

    try {
      await ref.read(allProofProvider.notifier).addProof(
            sourcePath: _selectedImage!.path,
            habitId: widget.habitId,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
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
          'Proof needs access to your $permission to capture habit evidence. '
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
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _PickerView extends StatelessWidget {
  const _PickerView({required this.onCamera, required this.onGallery});
  final VoidCallback onCamera;
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
            'A photo is required to mark this habit as complete.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            icon: Icons.photo_library_rounded,
            label: 'Choose from Gallery',
            subtitle: 'Select an existing photo',
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
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
        // Image preview
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: Image.file(
              File(imagePath),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Note + actions
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
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
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
            Text(
              'Habit completed! 🎉',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your proof has been saved.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

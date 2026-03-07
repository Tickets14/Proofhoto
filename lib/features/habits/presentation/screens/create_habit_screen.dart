import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/habit.dart' show Habit;
import '../../domain/habit_service.dart';
import '../controllers/habit_controller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/confirm_dialog.dart';

class CreateHabitScreen extends ConsumerStatefulWidget {
  const CreateHabitScreen({super.key, this.habitId});

  /// If set, the screen is in "edit" mode.
  final String? habitId;

  @override
  ConsumerState<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _emoji = '🏃';
  int _colorValue = AppColors.habitColors[0].value;
  List<int> _reminderDays = [1, 2, 3, 4, 5, 6, 7];
  TimeOfDay? _reminderTime;
  Habit? _editing;

  @override
  void initState() {
    super.initState();
    if (widget.habitId != null) {
      final habit = ref.read(habitRepositoryProvider).getById(widget.habitId!);
      if (habit != null) {
        _editing = habit;
        _nameCtrl.text = habit.name;
        _emoji = habit.emoji;
        _colorValue = habit.colorValue;
        _reminderDays = List.from(habit.reminderDays);
        if (habit.reminderTime != null) {
          final parts = habit.reminderTime!.split(':');
          _reminderTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _editing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Habit' : 'New Habit'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete habit',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          children: [
            // Name field
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Morning run',
              ),
              maxLength: AppConstants.habitNameMaxLength,
              textCapitalization: TextCapitalization.sentences,
              validator: HabitService.validateName,
              autofocus: !isEdit,
            ),
            const SizedBox(height: 24),

            // Emoji picker
            _Section(
              title: 'Icon',
              child: _EmojiPicker(
                selected: _emoji,
                onSelected: (e) => setState(() => _emoji = e),
              ),
            ),
            const SizedBox(height: 24),

            // Color picker
            _Section(
              title: 'Color',
              child: _ColorPicker(
                selected: _colorValue,
                onSelected: (v) => setState(() => _colorValue = v),
              ),
            ),
            const SizedBox(height: 24),

            // Days of week
            _Section(
              title: 'Repeat',
              child: _DayPicker(
                selected: _reminderDays,
                onChanged: (days) => setState(() => _reminderDays = days),
              ),
            ),
            const SizedBox(height: 24),

            // Reminder time
            _Section(
              title: 'Reminder',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm_outlined),
                title: Text(
                  _reminderTime == null
                      ? 'No reminder'
                      : _reminderTime!.format(context),
                ),
                trailing: _reminderTime != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            setState(() => _reminderTime = null),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _pickTime,
              ),
            ),
            const SizedBox(height: 40),

            // Save button
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(isEdit ? 'Save changes' : 'Create habit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reminderDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one day.')),
      );
      return;
    }

    final timeStr = _reminderTime == null
        ? null
        : '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}';

    final ctrl = ref.read(habitsProvider.notifier);

    if (_editing != null) {
      await ctrl.updateHabit(
        _editing!,
        name: _nameCtrl.text,
        emoji: _emoji,
        colorValue: _colorValue,
        reminderDays: _reminderDays,
        reminderTime: timeStr,
      );
    } else {
      await ctrl.createHabit(
        name: _nameCtrl.text,
        emoji: _emoji,
        colorValue: _colorValue,
        reminderDays: _reminderDays,
        reminderTime: timeStr,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    if (_editing == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete habit?',
      message:
          'This will permanently delete "${_editing!.name}" and all its proof photos. This cannot be undone.',
    );
    if (confirmed && mounted) {
      await ref.read(habitsProvider.notifier).archiveHabit(_editing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current emoji display + custom input
        Row(
          children: [
            GestureDetector(
              onTap: () => _showGrid(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(selected,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Or type any emoji…',
                  prefixIcon: Icon(Icons.emoji_emotions_outlined),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty) onSelected(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.quickEmojis.map((e) {
            final isSelected = e == selected;
            return GestureDetector(
              onTap: () => onSelected(e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 20)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showGrid(BuildContext context) {
    // The inline grid is already visible; no additional dialog needed.
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppColors.habitColors.map((color) {
        final isSelected = color.value == selected;
        return GestureDetector(
          onTap: () => onSelected(color.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.selected, required this.onChanged});
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  static const _dayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1; // 1=Mon…7=Sun
        final isOn = selected.contains(day);
        return GestureDetector(
          onTap: () {
            final next = isOn
                ? selected.where((d) => d != day).toList()
                : [...selected, day]..sort();
            onChanged(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOn
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _dayShort[i],
              style: TextStyle(
                color: isOn
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/habit_category.dart';
import '../controllers/category_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/confirm_dialog.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🗂️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first category',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppConstants.screenPadding,
                16,
                AppConstants.screenPadding,
                MediaQuery.of(context).padding.bottom + 80,
              ),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final cat = categories[i];
                return _CategoryTile(
                  category: cat,
                  onEdit: () => _showCategoryDialog(context, ref, cat),
                  onDelete: () => _confirmDelete(context, ref, cat),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref, null),
        tooltip: 'New category',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    HabitCategory? existing,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _CategoryDialog(
        existing: existing,
        onSave: (name, emoji, colorValue) async {
          final ctrl = ref.read(categoriesProvider.notifier);
          if (existing != null) {
            await ctrl.update(existing,
                name: name, emoji: emoji, colorValue: colorValue);
          } else {
            await ctrl.create(
                name: name, emoji: emoji, colorValue: colorValue);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HabitCategory category,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete category?',
      message:
          '"${category.name}" will be removed. Habits in this category will become uncategorized.',
    );
    if (confirmed) {
      await ref.read(categoriesProvider.notifier).delete(category.id);
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final HabitCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(category.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(category.name,
            style: Theme.of(context).textTheme.titleSmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20,
                  color: Theme.of(context).colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.existing, required this.onSave});

  final HabitCategory? existing;
  final Future<void> Function(String name, String emoji, int colorValue) onSave;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameCtrl;
  late String _emoji;
  late int _colorValue;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _emoji = widget.existing?.emoji ?? '🗂️';
    _colorValue =
        widget.existing?.colorValue ?? AppColors.habitColors[0].value;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.existing != null ? 'Edit Category' : 'New Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji + name row
          Row(
            children: [
              GestureDetector(
                onTap: _pickEmoji,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(_emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    hintText: 'e.g. Fitness',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Color picker
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Color',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppColors.habitColors.map((color) {
              final selected = color.value == _colorValue;
              return GestureDetector(
                onTap: () => setState(() => _colorValue = color.value),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickEmoji() async {
    final emojis = [
      '🗂️', '💪', '🍎', '📚', '🧘', '⚡', '🎨', '🎵', '🏃',
      '🌿', '💊', '🏠', '💼', '🎯', '🌟', '🔬', '🎭', '🚀',
    ];
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pick an emoji'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((e) {
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(e),
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
    if (picked != null) setState(() => _emoji = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(name, _emoji, _colorValue);
    if (mounted) Navigator.of(context).pop();
  }
}

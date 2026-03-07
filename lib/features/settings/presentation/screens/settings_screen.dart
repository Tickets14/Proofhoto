import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../habits/presentation/controllers/habit_controller.dart';
import '../../../proof/presentation/controllers/proof_controller.dart';
import '../controllers/settings_controller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../features/categories/presentation/screens/manage_categories_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final todayHabits = ref.watch(todayHabitsProvider);
    final completedCount = ref.watch(todayCompletedCountProvider);
    final hasIncompleteToday = todayHabits.length > completedCount;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppConstants.screenPadding,
          16,
          AppConstants.screenPadding,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        children: [
          // ── Appearance ────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Theme'),
                trailing: DropdownButton<String>(
                  value: settings.themeMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'system', child: Text('System')),
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(value: 'dark', child: Text('Dark')),
                  ],
                  onChanged: (v) {
                    if (v != null) ctrl.setThemeMode(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Notifications ─────────────────────────────────────────────
          _SectionHeader('Notifications'),
          _SettingsCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Habit reminders'),
                subtitle: const Text(
                    'Get notified when it\'s time to complete your habits'),
                value: settings.notificationsEnabled,
                onChanged: (v) => ctrl.setNotificationsEnabled(v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Streak Freezes ────────────────────────────────────────────
          _SectionHeader('Streak Freezes'),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('❄️',
                            style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${settings.streakFreezeCount} freeze${settings.streakFreezeCount == 1 ? '' : 's'} available',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            Text(
                              'Earn 1 per 7-day streak milestone',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Earn 1 freeze per 7-day streak. '
                      'Use it to protect your streak on missed days.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (settings.streakFreezeCount > 0 &&
                        !settings.usedFreezes.contains(todayStr) &&
                        hasIncompleteToday) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.ac_unit),
                        label: const Text('Use freeze for today'),
                        onPressed: () => ctrl.useStreakFreeze(todayStr),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Habits ────────────────────────────────────────────────────
          _SectionHeader('Habits'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Manage Categories'),
                subtitle: const Text('Organize habits into groups'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManageCategoriesScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Data ──────────────────────────────────────────────────────
          _SectionHeader('Data'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Export data'),
                subtitle: const Text('Save all habits as JSON'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _exportData(context, ref),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined,
                    color: Colors.red),
                title: const Text('Delete all data',
                    style: TextStyle(color: Colors.red)),
                subtitle: const Text('Permanently removes all habits and proof'),
                onTap: () => _deleteAll(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────────
          _SectionHeader('About'),
          _SettingsCard(
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version'),
                trailing: Text('1.0.0',
                    style: TextStyle(color: Colors.grey)),
              ),
              const Divider(height: 1, indent: 56),
              const ListTile(
                leading: Text('🦋', style: TextStyle(fontSize: 20)),
                title: Text('Made with Flutter'),
                subtitle: Text('100% offline, 100% yours'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final habits = ref.read(habitsProvider);
      final entries = ref.read(allProofProvider);

      final data = {
        'exportedAt': DateTime.now().toIso8601String(),
        'habits': habits.map((h) => {
          'id': h.id,
          'name': h.name,
          'emoji': h.emoji,
          'reminderDays': h.reminderDays,
          'reminderTime': h.reminderTime,
          'createdAt': h.createdAt.toIso8601String(),
        }).toList(),
        'proofEntries': entries.map((e) => {
          'id': e.id,
          'habitId': e.habitId,
          'imagePath': e.imagePath,
          'note': e.note,
          'completedAt': e.completedAt.toIso8601String(),
        }).toList(),
      };

      // Use external storage on Android so the file lands in a user-visible location;
      // fall back to app documents directory on iOS / if unavailable.
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();

      final filename =
          'proof_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported: $filename'),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final first = await showConfirmDialog(
      context,
      title: 'Delete all data?',
      message:
          'This will permanently delete all your habits, proof photos, and statistics. This cannot be undone.',
    );
    if (!first || !context.mounted) return;

    final second = await showConfirmDialog(
      context,
      title: 'Are you absolutely sure?',
      message: 'All ${ref.read(habitsProvider).length} habits and all proof photos will be gone forever.',
      confirmLabel: 'Yes, delete everything',
    );
    if (!second || !context.mounted) return;

    final habits = ref.read(habitsProvider);
    for (final h in habits) {
      await ref.read(habitsProvider.notifier).archiveHabit(h.id);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data deleted.')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

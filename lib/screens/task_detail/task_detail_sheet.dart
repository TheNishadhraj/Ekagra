import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../providers/reward_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/ai_service.dart';

class TaskDetailSheet extends StatefulWidget {
  final TaskModel task;

  const TaskDetailSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, TaskModel task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDetailSheet(task: task),
    );
  }

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  late TaskModel _task;
  late TextEditingController _notesController;
  late TextEditingController _subtaskController;
  bool _isBreakingDown = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _notesController = TextEditingController(text: _task.notes ?? '');
    _subtaskController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    final updated = _task.copyWith(notes: _notesController.text.trim());
    context.read<TaskProvider>().updateTask(updated);
    setState(() {
      _task = updated;
    });
  }

  void _addSubtask(String text) {
    if (text.trim().isEmpty) return;
    final updatedList = [..._task.subtasks, text.trim()];
    final updated = _task.copyWith(subtasks: updatedList);
    context.read<TaskProvider>().updateTask(updated);
    setState(() {
      _task = updated;
      _subtaskController.clear();
    });
  }

  void _removeSubtask(int index) {
    final updatedList = [..._task.subtasks]..removeAt(index);
    final updated = _task.copyWith(subtasks: updatedList);
    context.read<TaskProvider>().updateTask(updated);
    setState(() {
      _task = updated;
    });
  }

  Future<void> _breakDownWithAi() async {
    setState(() {
      _isBreakingDown = true;
    });
    final ai = AiService();
    final messenger = ScaffoldMessenger.of(context);
    final subtasks = await ai.breakdownTask(_task.title);
    if (!mounted) return;

    final updatedList = [..._task.subtasks, ...subtasks];
    final updated = _task.copyWith(subtasks: updatedList);
    await context.read<TaskProvider>().updateTask(updated);
    if (!mounted) return;

    setState(() {
      _task = updated;
      _isBreakingDown = false;
    });
    messenger.showSnackBar(
      const SnackBar(
        content: Text('🔨 Task broken down into small micro-steps!'),
        backgroundColor: EkagraColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final rewardProvider = context.read<RewardProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: EkagraColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EkagraRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        top: EkagraSpacing.md,
        left: EkagraSpacing.lg,
        right: EkagraSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + EkagraSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EkagraColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: EkagraSpacing.md),

            // Header Row
            Row(
              children: [
                Text(_task.emoji ?? '🎯', style: const TextStyle(fontSize: 32)),
                const SizedBox(width: EkagraSpacing.sm),
                Expanded(
                  child: Text(
                    _task.title,
                    style: EkagraTypography.h2.copyWith(fontSize: 20),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: EkagraSpacing.md),

            // Metadata Badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _badge('~${_task.estimatedMinutes ?? 15} min'),
                _badge('Energy: ${_task.energyNeeded.name}'),
                _badge('Schedule: ${_task.scheduleType.name}'),
                if (_task.category != null) _badge(_task.category!),
              ],
            ),

            const SizedBox(height: EkagraSpacing.lg),

            // Schedule Type Selector
            Text('Schedule Type', style: EkagraTypography.bodyBold.copyWith(fontSize: 14)),
            const SizedBox(height: EkagraSpacing.xs),
            Row(
              children: TaskScheduleType.values.map((st) {
                final isSel = _task.scheduleType == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(st.name),
                    selected: isSel,
                    selectedColor: EkagraColors.primary.withValues(alpha: 0.15),
                    onSelected: (selected) {
                      if (selected) {
                        final updated = _task.copyWith(scheduleType: st);
                        taskProvider.updateTask(updated);
                        setState(() => _task = updated);
                      }
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: EkagraSpacing.lg),

            // Micro-Commitment
            if (_task.microCommitment != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EkagraSpacing.md),
                decoration: BoxDecoration(
                  color: EkagraColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(EkagraRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MICRO-COMMITMENT',
                      style: EkagraTypography.tiny.copyWith(
                        color: EkagraColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"${_task.microCommitment}"',
                      style: EkagraTypography.encouragement.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EkagraSpacing.lg),
            ],

            // Subtasks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtasks (${_task.subtasks.length})',
                  style: EkagraTypography.bodyBold.copyWith(fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: _isBreakingDown ? null : _breakDownWithAi,
                  icon: _isBreakingDown
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isBreakingDown ? 'Thinking...' : 'Break this down 🔨'),
                ),
              ],
            ),

            ...List.generate(_task.subtasks.length, (index) {
              final sub = _task.subtasks[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_box_outline_blank_rounded, size: 20),
                title: Text(sub, style: EkagraTypography.body.copyWith(fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => _removeSubtask(index),
                ),
              );
            }),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: const InputDecoration(
                      hintText: 'Add a subtask...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: _addSubtask,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: EkagraColors.primary,
                  onPressed: () => _addSubtask(_subtaskController.text),
                ),
              ],
            ),

            const SizedBox(height: EkagraSpacing.lg),

            // Notes Editor
            Text('Notes', style: EkagraTypography.bodyBold.copyWith(fontSize: 14)),
            const SizedBox(height: EkagraSpacing.xs),
            TextField(
              controller: _notesController,
              maxLines: 3,
              onChanged: (_) => _saveNotes(),
              decoration: const InputDecoration(
                hintText: 'Add details, links, or notes...',
              ),
            ),

            const SizedBox(height: EkagraSpacing.xl),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.focus, arguments: _task);
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('Start Focus ⏱️'),
              ),
            ),

            const SizedBox(height: EkagraSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await taskProvider.completeTask(_task.id);
                      rewardProvider.recordTaskCompletion(_task.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded, color: EkagraColors.success),
                    label: const Text('Mark Done ✅'),
                  ),
                ),
                const SizedBox(width: EkagraSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await taskProvider.archiveTask(_task.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.archive_outlined, color: EkagraColors.textTertiary),
                    label: const Text('Archive 📦'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: EkagraColors.surfaceElevated,
        borderRadius: BorderRadius.circular(EkagraRadius.full),
        border: Border.all(
          color: EkagraColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: EkagraTypography.tiny.copyWith(
          color: EkagraColors.textSecondary,
        ),
      ),
    );
  }
}

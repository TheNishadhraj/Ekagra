import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../providers/reward_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/task_decomposer.dart';

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
  TaskDecomposer? _decomposer;
  bool _showAllSteps = false;

  Future<TaskDecomposer> _decomposerReady() async =>
      _decomposer ??= await TaskDecomposer.loadDefault();

  List<DecomposedStep> _planFor(TaskModel task) {
    return List.generate(task.subtasks.length, (i) {
      final state = i < task.stepStates.length ? task.stepStates[i] : null;
      return DecomposedStep(
        title: task.subtasks[i],
        done: state == 'done',
        skipped: state == 'skipped',
      );
    });
  }

  /// WI-3.1: spiciness picker, then deterministic local breakdown.
  /// Honest label everywhere: this is pattern matching on your phone.
  Future<void> _breakDown() async {
    final spiciness = await _pickSpiciness();
    if (spiciness == null || !mounted) return;

    final decomposer = await _decomposerReady();
    final steps = decomposer.breakdown(_task.title, spiciness);
    final updated = _task.copyWith(
      subtasks: steps.map((s) => s.title).toList(),
      stepStates: const [],
      spiciness: spiciness.name,
    );
    await context.read<TaskProvider>().updateTask(updated);
    if (!mounted) return;
    setState(() => _task = updated);

    track(Ev.taskBreakdownRequested, {
      'spiciness': spiciness.name,
      'step_count': steps.length,
      'family': decomposer.familyIdFor(_task.title) ?? 'generic',
      'engine': 'local_templates',
    });
  }

  Future<Spiciness?> _pickSpiciness() {
    return showModalBottomSheet<Spiciness>(
      context: context,
      backgroundColor: EkagraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(EkagraRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(EkagraSpacing.lg),
              child: Text('How tiny should the steps be?', style: EkagraTypography.h3),
            ),
            ...Spiciness.values.map(
              (s) => ListTile(
                leading: Text(
                  s == Spiciness.mild ? '🪵' : (s == Spiciness.medium ? '🌰' : '🌶️'),
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(s.label),
                subtitle: Text(
                  '${s.bounds.$1}–${s.bounds.$2} steps',
                  style: EkagraTypography.tiny,
                ),
                onTap: () => Navigator.pop(ctx, s),
              ),
            ),
            const SizedBox(height: EkagraSpacing.md),
            Padding(
              padding: const EdgeInsets.only(bottom: EkagraSpacing.md),
              child: Text(
                'Runs on your phone — no cloud, no account.',
                style: EkagraTypography.tiny,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveStep(int index, {required bool skipped}) async {
    final states = [..._task.stepStates];
    while (states.length < _task.subtasks.length) {
      states.add('pending');
    }
    states[index] = skipped ? 'skipped' : 'done';
    var updated = _task.copyWith(stepStates: states);
    await context.read<TaskProvider>().updateTask(updated);
    if (!mounted) return;
    setState(() => _task = updated);

    if (!skipped) {
      // Micro-tick: a quick-tier treat, inline (the real variable-ratio
      // spin stays reserved for finishing the whole task).
      await context.read<RewardProvider>().recordStepCompleted(
            updated.id,
            taskTitle: updated.title,
          );
      if (!mounted) return;
      final finished = DecompositionPlan(steps: _planFor(updated)).isFinished;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            finished ? 'All steps done — finish the task below 💛' : '🍫 Tiny win logged.',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: EkagraColors.primary,
        ),
      );
    }
  }

  Future<void> _finishWholeTask() async {
    final taskProvider = context.read<TaskProvider>();
    final rewards = context.read<RewardProvider>();
    if (_task.isCompleted) return; // exactly one completion reward, ever
    await taskProvider.completeTask(_task.id);
    rewards.recordTaskCompletion(_task.id);
    if (context.mounted) Navigator.pop(context);
  }

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

            // WI-3.1 — breakdown + one-step execution mode.
            //
            // The differentiator nobody in the category has fused with
            // rewards: ONE step at a time, a quick-tier treat per step,
            // and the real variable-ratio spin only when the task itself
            // is finished. Primary choices on this view: Done / Skip /
            // See all — Rule 1's budget of three.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Steps',
                  style: EkagraTypography.bodyBold.copyWith(fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: _breakDown,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Break it down 🌶️'),
                ),
              ],
            ),

            if (_task.subtasks.isEmpty)
              Text(
                'Stuck staring at it? Break it into tiny steps — built from patterns, runs on your phone.',
                style: EkagraTypography.caption,
              )
            else ...[
              _ExecutionStepCard(
                steps: _planFor(_task),
                showAll: _showAllSteps,
                onDone: (i) => _resolveStep(i, skipped: false),
                onSkip: (i) => _resolveStep(i, skipped: true),
                onToggleShowAll: () =>
                    setState(() => _showAllSteps = !_showAllSteps),
                onFinish: _finishWholeTask,
              ),
              if (_showAllSteps)
                ...List.generate(_task.subtasks.length, (index) {
                  final sub = _task.subtasks[index];
                  final state = index < _task.stepStates.length
                      ? _task.stepStates[index]
                      : null;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      state == 'done'
                          ? Icons.check_circle_rounded
                          : (state == 'skipped'
                              ? Icons.skip_next_rounded
                              : Icons.radio_button_unchecked_rounded),
                      size: 20,
                      color: state == 'done'
                          ? EkagraColors.success
                          : EkagraColors.textTertiary,
                    ),
                    title: Text(
                      sub,
                      style: EkagraTypography.body.copyWith(
                        fontSize: 14,
                        decoration: state == 'done'
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => _removeSubtask(index),
                    ),
                  );
                }),
            ],

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

/// One step at a time. The full list is one deliberate toggle away, never
/// the default view — overwhelm is the failure mode this exists to kill.
class _ExecutionStepCard extends StatelessWidget {
  const _ExecutionStepCard({
    required this.steps,
    required this.showAll,
    required this.onDone,
    required this.onSkip,
    required this.onToggleShowAll,
    required this.onFinish,
  });

  final List<DecomposedStep> steps;
  final bool showAll;
  final void Function(int index) onDone;
  final void Function(int index) onSkip;
  final VoidCallback onToggleShowAll;
  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    final plan = DecompositionPlan(steps: steps);
    final current = plan.currentStep;

    if (current == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EkagraSpacing.lg),
        decoration: BoxDecoration(
          color: EkagraColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(EkagraRadius.lg),
          border: Border.all(color: EkagraColors.success.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(height: EkagraSpacing.xs),
            Text('Every step done!', style: EkagraTypography.bodyBold),
            const SizedBox(height: EkagraSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EkagraColors.success,
                ),
                icon: const Icon(Icons.check_rounded, color: Colors.white),
                label: const Text('Finish the task ✅'),
              ),
            ),
          ],
        ),
      );
    }

    final index = plan.currentIndex;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EkagraSpacing.lg),
      decoration: BoxDecoration(
        color: EkagraColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(EkagraRadius.lg),
        border: Border.all(
          color: EkagraColors.primaryLight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ONE STEP AT A TIME', style: EkagraTypography.tiny),
          const SizedBox(height: EkagraSpacing.xs),
          Text(
            current.title,
            style: EkagraTypography.h3,
          ),
          const SizedBox(height: EkagraSpacing.xs),
          Text(
            '≈ 2–5 min · ${plan.resolvedCount} of ${steps.length} done',
            style: EkagraTypography.tiny,
          ),
          const SizedBox(height: EkagraSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => onDone(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: EkagraColors.success,
              ),
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text('Done with this step'),
            ),
          ),
          const SizedBox(height: EkagraSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onSkip(index),
                  child: const Text('Skip step'),
                ),
              ),
              const SizedBox(width: EkagraSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: onToggleShowAll,
                  child: Text(showAll ? 'Hide all steps' : 'See all steps'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

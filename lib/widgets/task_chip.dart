import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/task_model.dart';
import '../utils/haptic_feedback.dart';

class TaskChip extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const TaskChip({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EkagraColors.surface,
      borderRadius: BorderRadius.circular(EkagraRadius.lg),
      child: InkWell(
        onTap: () {
          EkagraHaptics.light();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(EkagraRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EkagraSpacing.md,
            vertical: EkagraSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EkagraRadius.lg),
            border: Border.all(
              color: EkagraColors.primaryLight.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Text(
                task.emoji ?? '✨',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: EkagraSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: EkagraTypography.bodyBold.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '~${task.estimatedMinutes ?? 15} min · ${task.energyNeeded.name}',
                      style: EkagraTypography.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.circle_outlined, size: 22),
                color: EkagraColors.primary,
                onPressed: () {
                  EkagraHaptics.medium();
                  onComplete?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

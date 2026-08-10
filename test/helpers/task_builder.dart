import 'package:ekagra/models/task_model.dart';

/// Helper to quickly build TaskModel instances for testing.
TaskModel makeTask({
  String? id,
  String title = 'A task',
  String? notes,
  TaskScheduleType scheduleType = TaskScheduleType.anytime,
  DeadlineType deadlineType = DeadlineType.none,
  DateTime? deadline,
  TaskStatus status = TaskStatus.notStarted,
  EnergyNeeded energyNeeded = EnergyNeeded.medium,
  int? estimatedMinutes,
  String? microCommitment,
  bool isDeleted = false,
  int skipCount = 0,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? completedAt,
}) {
  final now = DateTime.now();
  return TaskModel(
    id: id ?? 'task-$title',
    title: title,
    notes: notes,
    scheduleType: scheduleType,
    deadlineType: deadlineType,
    deadline: deadline,
    status: status,
    energyNeeded: energyNeeded,
    estimatedMinutes: estimatedMinutes,
    microCommitment: microCommitment,
    isDeleted: isDeleted,
    skipCount: skipCount,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    completedAt: completedAt,
  );
}

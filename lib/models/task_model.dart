import 'package:uuid/uuid.dart';

enum TaskScheduleType { today, thisWeek, anytime, someday }

enum DeadlineType { hard, soft, flexible, none }

enum TaskStatus { notStarted, inProgress, completed, archived }

enum EnergyNeeded { low, medium, high }

class TaskModel {
  final String id;
  final String title;
  final String? notes;
  final String? emoji;
  final TaskScheduleType scheduleType;
  final DeadlineType deadlineType;
  final DateTime? deadline;
  final TaskStatus status;
  final EnergyNeeded energyNeeded;
  final int? estimatedMinutes;
  final String? microCommitment;
  final String? category;
  final List<String> subtasks;

  /// WI-3.1/ADR-007: decomposition progress, parallel to [subtasks].
  /// Values are 'done' | 'skipped'; a missing/short list simply means
  /// "no progress recorded yet" — old payloads decode with defaults
  /// (SafeStore-compatible, additive only).
  final List<String> stepStates;

  /// Which spiciness the steps were generated at (Spiciness.name), if any.
  final String? spiciness;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? lastTouchedAt;
  final int skipCount;
  final String? recurrenceRuleId;

  const TaskModel({
    required this.id,
    required this.title,
    this.notes,
    this.emoji,
    this.scheduleType = TaskScheduleType.anytime,
    this.deadlineType = DeadlineType.none,
    this.deadline,
    this.status = TaskStatus.notStarted,
    this.energyNeeded = EnergyNeeded.medium,
    this.estimatedMinutes,
    this.microCommitment,
    this.category,
    this.subtasks = const [],
    this.stepStates = const [],
    this.spiciness,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.lastTouchedAt,
    this.skipCount = 0,
    this.recurrenceRuleId,
  });

  factory TaskModel.create({
    required String title,
    String? notes,
    String? emoji,
    TaskScheduleType scheduleType = TaskScheduleType.anytime,
    int? estimatedMinutes,
    EnergyNeeded energyNeeded = EnergyNeeded.medium,
    String? category,
  }) {
    final now = DateTime.now();
    return TaskModel(
      id: const Uuid().v4(),
      title: title.trim(),
      notes: notes,
      emoji: emoji ?? _guessEmoji(title),
      scheduleType: scheduleType,
      estimatedMinutes: estimatedMinutes ?? _guessMinutes(title),
      energyNeeded: energyNeeded,
      category: category,
      createdAt: now,
      updatedAt: now,
      lastTouchedAt: now,
    );
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isActive => !isDeleted && status != TaskStatus.archived;

  TaskModel copyWith({
    String? id,
    String? title,
    String? notes,
    String? emoji,
    TaskScheduleType? scheduleType,
    DeadlineType? deadlineType,
    DateTime? deadline,
    TaskStatus? status,
    EnergyNeeded? energyNeeded,
    int? estimatedMinutes,
    String? microCommitment,
    String? category,
    List<String>? subtasks,
    List<String>? stepStates,
    String? spiciness,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? lastTouchedAt,
    int? skipCount,
    String? recurrenceRuleId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      emoji: emoji ?? this.emoji,
      scheduleType: scheduleType ?? this.scheduleType,
      deadlineType: deadlineType ?? this.deadlineType,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      energyNeeded: energyNeeded ?? this.energyNeeded,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      microCommitment: microCommitment ?? this.microCommitment,
      category: category ?? this.category,
      subtasks: subtasks ?? this.subtasks,
      stepStates: stepStates ?? this.stepStates,
      spiciness: spiciness ?? this.spiciness,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      lastTouchedAt: lastTouchedAt ?? this.lastTouchedAt,
      skipCount: skipCount ?? this.skipCount,
      recurrenceRuleId: recurrenceRuleId ?? this.recurrenceRuleId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'emoji': emoji,
        'scheduleType': scheduleType.name,
        'deadlineType': deadlineType.name,
        'deadline': deadline?.toIso8601String(),
        'status': status.name,
        'energyNeeded': energyNeeded.name,
        'estimatedMinutes': estimatedMinutes,
        'microCommitment': microCommitment,
        'category': category,
        'subtasks': subtasks,
        'stepStates': stepStates,
        'spiciness': spiciness,
        'isDeleted': isDeleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'lastTouchedAt': lastTouchedAt?.toIso8601String(),
        'skipCount': skipCount,
        'recurrenceRuleId': recurrenceRuleId,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      emoji: json['emoji'] as String?,
      scheduleType: TaskScheduleType.values.byName(
        json['scheduleType'] as String? ?? 'anytime',
      ),
      deadlineType: DeadlineType.values.byName(
        json['deadlineType'] as String? ?? 'none',
      ),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      status: TaskStatus.values.byName(json['status'] as String? ?? 'notStarted'),
      energyNeeded: EnergyNeeded.values.byName(
        json['energyNeeded'] as String? ?? 'medium',
      ),
      estimatedMinutes: json['estimatedMinutes'] as int?,
      microCommitment: json['microCommitment'] as String?,
      category: json['category'] as String?,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      stepStates: (json['stepStates'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      spiciness: json['spiciness'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      lastTouchedAt: json['lastTouchedAt'] != null
          ? DateTime.parse(json['lastTouchedAt'] as String)
          : null,
      skipCount: json['skipCount'] as int? ?? 0,
      recurrenceRuleId: json['recurrenceRuleId'] as String?,
    );
  }

  static String _guessEmoji(String title) {
    final t = title.toLowerCase();
    if (t.contains('email') || t.contains('mail')) return '📧';
    if (t.contains('call') || t.contains('phone')) return '📞';
    if (t.contains('grocery') || t.contains('shop')) return '🛒';
    if (t.contains('water') || t.contains('drink')) return '💧';
    if (t.contains('walk') || t.contains('exercise') || t.contains('move')) {
      return '🚶';
    }
    if (t.contains('clean') || t.contains('tidy')) return '🧹';
    if (t.contains('write') || t.contains('doc')) return '📝';
    if (t.contains('read')) return '📖';
    if (t.contains('med')) return '💊';
    if (t.contains('food') || t.contains('cook') || t.contains('eat')) {
      return '🍽️';
    }
    return '✨';
  }

  static int _guessMinutes(String title) {
    final t = title.toLowerCase();
    if (t.contains('quick') || t.contains('water') || t.contains('med')) {
      return 5;
    }
    if (t.contains('email') || t.contains('call')) return 15;
    if (t.contains('grocery') || t.contains('clean')) return 30;
    return 20;
  }
}

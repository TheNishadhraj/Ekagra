import 'package:uuid/uuid.dart';

enum FocusSessionStatus { idle, running, paused, completed, abandoned }

class FocusSession {
  final String id;
  final String? taskId;
  final String? taskTitle;
  final int plannedMinutes;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final DateTime? pausedAt;
  final int accumulatedPausedSeconds;
  final FocusSessionStatus status;
  final DateTime createdAt;

  const FocusSession({
    required this.id,
    this.taskId,
    this.taskTitle,
    required this.plannedMinutes,
    this.startedAt,
    this.endsAt,
    this.pausedAt,
    this.accumulatedPausedSeconds = 0,
    this.status = FocusSessionStatus.idle,
    required this.createdAt,
  });

  factory FocusSession.create({
    String? taskId,
    String? taskTitle,
    required int plannedMinutes,
  }) {
    return FocusSession(
      id: const Uuid().v4(),
      taskId: taskId,
      taskTitle: taskTitle,
      plannedMinutes: plannedMinutes,
      createdAt: DateTime.now(),
    );
  }

  /// Bulletproof remaining time based on wall clock (Spec H3).
  Duration remaining() {
    if (status == FocusSessionStatus.idle || endsAt == null) {
      return Duration(minutes: plannedMinutes);
    }
    if (status == FocusSessionStatus.paused && pausedAt != null && endsAt != null) {
      return endsAt!.difference(pausedAt!);
    }
    if (status == FocusSessionStatus.completed) {
      return Duration.zero;
    }
    final left = endsAt!.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  double progress() {
    final total = Duration(minutes: plannedMinutes).inMilliseconds;
    if (total <= 0) return 1;
    final left = remaining().inMilliseconds;
    return ((total - left) / total).clamp(0.0, 1.0);
  }

  FocusSession copyWith({
    String? id,
    String? taskId,
    String? taskTitle,
    int? plannedMinutes,
    DateTime? startedAt,
    DateTime? endsAt,
    DateTime? pausedAt,
    int? accumulatedPausedSeconds,
    FocusSessionStatus? status,
    DateTime? createdAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      startedAt: startedAt ?? this.startedAt,
      endsAt: endsAt ?? this.endsAt,
      pausedAt: pausedAt ?? this.pausedAt,
      accumulatedPausedSeconds:
          accumulatedPausedSeconds ?? this.accumulatedPausedSeconds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'plannedMinutes': plannedMinutes,
        'startedAt': startedAt?.toIso8601String(),
        'endsAt': endsAt?.toIso8601String(),
        'pausedAt': pausedAt?.toIso8601String(),
        'accumulatedPausedSeconds': accumulatedPausedSeconds,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      taskId: json['taskId'] as String?,
      taskTitle: json['taskTitle'] as String?,
      plannedMinutes: json['plannedMinutes'] as int,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endsAt:
          json['endsAt'] != null ? DateTime.parse(json['endsAt'] as String) : null,
      pausedAt: json['pausedAt'] != null
          ? DateTime.parse(json['pausedAt'] as String)
          : null,
      accumulatedPausedSeconds: json['accumulatedPausedSeconds'] as int? ?? 0,
      status: FocusSessionStatus.values.byName(
        json['status'] as String? ?? 'idle',
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

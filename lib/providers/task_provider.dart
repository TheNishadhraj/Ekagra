import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/design_rules.dart';
import '../models/energy_log_model.dart';
import '../models/mood_log_model.dart';
import '../models/task_model.dart';
import '../services/ai_service.dart';
import '../services/analytics_service.dart';
import '../services/growth_service.dart';
import '../services/monetization_service.dart';
import '../services/nudge_service.dart';
import '../utils/safe_store.dart';

class TaskProvider extends ChangeNotifier {
  static const _tasksKey = 'ekagra_tasks';

  final AiService _ai = AiService();
  List<TaskModel> _tasks = [];
  TaskModel? _oneThing;
  final Set<String> _skippedOneThingIds = {};
  int _skipCount = 0;
  bool _loaded = false;

  List<TaskModel> get tasks =>
      _tasks.where((t) => t.isActive && !t.isDeleted).toList();
  List<TaskModel> get allIncludingDeleted => List.unmodifiable(_tasks);
  TaskModel? get oneThing => _oneThing;
  int get skipCount => _skipCount;
  bool get loaded => _loaded;

  List<TaskModel> get activeIncomplete => tasks
      .where((t) => !t.isCompleted && t.scheduleType != TaskScheduleType.someday)
      .toList();

  List<TaskModel> get somedayTasks => tasks
      .where((t) => !t.isCompleted && t.scheduleType == TaskScheduleType.someday)
      .toList();

  List<TaskModel> get completedToday {
    final now = DateTime.now();
    return tasks.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      final c = t.completedAt!;
      return c.year == now.year && c.month == now.month && c.day == now.day;
    }).toList();
  }

  List<TaskModel> get upcoming {
    return activeIncomplete
        .where((t) => t.id != _oneThing?.id)
        .take(DesignRules.maxUpcomingTasksOnHome)
        .toList();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Salvage per-record: one malformed task must never cost the user the
    // rest of their list, and must never prevent the app from starting.
    // See SafeStore for the quarantine policy.
    _tasks = SafeStore.decodeList<TaskModel>(
      raw: prefs.getString(_tasksKey),
      key: _tasksKey,
      fromJson: TaskModel.fromJson,
    );
    _loaded = true;
    refreshOneThing();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tasksKey,
      jsonEncode(_tasks.map((t) => t.toJson()).toList()),
    );
  }

  Future<TaskModel> addTask(
    String title, {
    TaskScheduleType scheduleType = TaskScheduleType.anytime,
    String? notes,
    String source = 'unknown',
  }) async {
    final task = TaskModel.create(
      title: title,
      scheduleType: scheduleType,
      notes: notes,
    );
    _tasks = [task, ..._tasks];
    await _persist();

    track(Ev.taskCreated, {
      'source': source,
      'length': title.length,
      'schedule_type': scheduleType.name,
      'active_task_count': activeIncomplete.length,
    });
    await GrowthService.instance.completeStep(ActivationStep.firstTaskCaptured);

    refreshOneThing();
    notifyListeners();
    return task;
  }

  /// Bulk add from brain dump.
  ///
  /// Returns the number actually saved. Free users are capped at the
  /// experiment-controlled ceiling, but we save everything up to the ceiling
  /// rather than rejecting the whole batch — refusing to store a user's
  /// thoughts because they exceeded a billing threshold is exactly the kind
  /// of punishment Rule 15 forbids.
  Future<int> addTasks(List<String> titles, {String source = 'brain_dump'}) async {
    final now = DateTime.now();
    final cleaned = titles.where((t) => t.trim().isNotEmpty).toList();

    final limit = MonetizationService.instance.freeTaskLimit;
    final isPro = MonetizationService.instance.isPro;
    final headroom = isPro ? cleaned.length : (limit - activeIncomplete.length);
    final accepted = headroom <= 0
        ? <String>[]
        : cleaned.take(headroom).toList();

    final created = accepted
        .map(
          (t) => TaskModel.create(title: t).copyWith(
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();
    _tasks = [...created, ..._tasks];
    await _persist();

    track(Ev.brainDumpCompleted, {
      'task_count': created.length,
      'attempted': cleaned.length,
      'truncated': cleaned.length - created.length,
      'source': source,
      'is_pro': isPro,
    });
    if (created.isNotEmpty) {
      await GrowthService.instance
          .completeStep(ActivationStep.firstTaskCaptured);
    }

    refreshOneThing();
    notifyListeners();
    return created.length;
  }

  Future<void> completeTask(
    String id, {
    bool honest = true,
    String method = 'tap',
  }) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final now = DateTime.now();
    final task = _tasks[idx];
    _tasks[idx] = task.copyWith(
      status: TaskStatus.completed,
      completedAt: now,
      updatedAt: now,
      lastTouchedAt: now,
    );

    // Completing a task cancels its pending nudges (WI-1.4): the nudge
    // sequence must never congratulate itself into an empty room.
    unawaited(NudgeService.instance.cancelTaskNudges(id));

    // North Star event: a task actually finished.
    track(Ev.taskCompleted, {
      'method': method,
      'honest': honest,
      'age_hours': now.difference(task.createdAt).inHours,
      'skip_count': task.skipCount,
      'was_one_thing': _oneThing?.id == id,
    });
    await GrowthService.instance.recordTaskCompleted();

    if (_oneThing?.id == id) {
      _oneThing = null;
      _skippedOneThingIds.clear();
      _skipCount = 0;
    }
    await _persist();
    refreshOneThing();
    notifyListeners();
  }

  /// Soft delete only (Rule 13).
  Future<void> archiveTask(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    _tasks[idx] = _tasks[idx].copyWith(
      status: TaskStatus.archived,
      isDeleted: true,
      updatedAt: DateTime.now(),
    );
    if (_oneThing?.id == id) {
      _oneThing = null;
    }
    await _persist();
    refreshOneThing();
    notifyListeners();
  }

  Future<void> updateTask(TaskModel task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx < 0) return;
    _tasks[idx] = task.copyWith(updatedAt: DateTime.now());
    await _persist();
    if (_oneThing?.id == task.id) {
      _oneThing = _tasks[idx];
    }
    notifyListeners();
  }

  void refreshOneThing({
    EnergyLevel energy = EnergyLevel.medium,
    MoodLevel mood = MoodLevel.okay,
  }) {
    _oneThing = _ai.pickOneThing(
      tasks: tasks,
      energy: energy,
      mood: mood,
      skipIds: _skippedOneThingIds,
    );
  }

  void skipOneThing({
    EnergyLevel energy = EnergyLevel.medium,
    MoodLevel mood = MoodLevel.okay,
  }) {
    if (_oneThing == null) return;
    _skippedOneThingIds.add(_oneThing!.id);
    _skipCount++;
    track(Ev.aiSelectionSkipped, {
      'times_skipped': _skipCount,
      'energy': energy.name,
      'mood': mood.name,
    });
    final idx = _tasks.indexWhere((t) => t.id == _oneThing!.id);
    if (idx >= 0) {
      _tasks[idx] = _tasks[idx].copyWith(
        skipCount: _tasks[idx].skipCount + 1,
        updatedAt: DateTime.now(),
      );
    }
    refreshOneThing(energy: energy, mood: mood);
    notifyListeners();
  }

  void resetSkips() {
    _skipCount = 0;
    _skippedOneThingIds.clear();
    refreshOneThing();
    notifyListeners();
  }

  /// True when a free user has filled their allowance.
  ///
  /// Reads the limit from [MonetizationService] (experiment-controlled)
  /// rather than the static [DesignRules.freeTierTaskLimit], which now only
  /// serves as the documented default.
  bool get atFreeTaskLimit {
    if (MonetizationService.instance.isPro) return false;
    return activeIncomplete.length >=
        MonetizationService.instance.freeTaskLimit;
  }

  /// Free allowance ceiling currently in force.
  int get effectiveTaskLimit => MonetizationService.instance.isPro
      ? -1
      : MonetizationService.instance.freeTaskLimit;

  /// How many free slots remain. Never negative.
  int get remainingFreeSlots {
    if (MonetizationService.instance.isPro) return 1 << 30;
    return (MonetizationService.instance.freeTaskLimit -
            activeIncomplete.length)
        .clamp(0, 1 << 30);
  }

  /// Kept so the static default stays referenced and auditable.
  static const int specifiedFreeTierLimit = DesignRules.freeTierTaskLimit;
}

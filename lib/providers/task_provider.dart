import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/design_rules.dart';
import '../models/energy_log_model.dart';
import '../models/mood_log_model.dart';
import '../models/task_model.dart';
import '../services/ai_service.dart';

class TaskProvider extends ChangeNotifier {
  static const _tasksKey = 'ekagra_tasks';

  final AiService _ai;
  List<TaskModel> _tasks = [];
  TaskModel? _oneThing;
  final Set<String> _skippedOneThingIds = {};
  int _skipCount = 0;
  bool _loaded = false;

  TaskProvider({AiService? aiService}) : _ai = aiService ?? AiService();

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tasksKey);
      if (raw != null) {
        try {
          final list = jsonDecode(raw);
          if (list is List) {
            _tasks = list
                .whereType<Map<String, dynamic>>()
                .map((e) {
                  try {
                    return TaskModel.fromJson(e);
                  } catch (err) {
                    debugPrint('TaskModel.fromJson item parse error: $err');
                    return null;
                  }
                })
                .whereType<TaskModel>()
                .toList();
          }
        } catch (e) {
          debugPrint('TaskProvider load failed to parse JSON: $e');
        }
      }
    } catch (e) {
      debugPrint('TaskProvider load storage error: $e');
    }
    _loaded = true;
    refreshOneThing();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _tasksKey,
        jsonEncode(_tasks.map((t) => t.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('TaskProvider _persist error: $e');
    }
  }

  Future<TaskModel> addTask(
    String title, {
    TaskScheduleType scheduleType = TaskScheduleType.anytime,
    String? notes,
  }) async {
    final task = TaskModel.create(
      title: title,
      scheduleType: scheduleType,
      notes: notes,
    );
    _tasks = [task, ..._tasks];
    await _persist();
    refreshOneThing();
    notifyListeners();
    return task;
  }

  Future<void> addTasks(List<String> titles) async {
    final now = DateTime.now();
    final created = titles
        .where((t) => t.trim().isNotEmpty)
        .map(
          (t) => TaskModel.create(title: t).copyWith(
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();
    _tasks = [...created, ..._tasks];
    await _persist();
    refreshOneThing();
    notifyListeners();
  }

  Future<void> completeTask(String id, {bool honest = true}) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final now = DateTime.now();
    _tasks[idx] = _tasks[idx].copyWith(
      status: TaskStatus.completed,
      completedAt: now,
      updatedAt: now,
      lastTouchedAt: now,
    );
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

  bool get atFreeTaskLimit =>
      activeIncomplete.length >= DesignRules.freeTierTaskLimit;
}

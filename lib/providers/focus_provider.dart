import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../models/focus_session_model.dart';
import '../models/task_model.dart';
import '../utils/date_helpers.dart';

class FocusProvider extends ChangeNotifier {
  FocusSession? _session;
  TaskModel? _currentTask;
  Timer? _ticker;
  int _todayFocusMinutes = 0;

  FocusSession? get session => _session;
  TaskModel? get currentTask => _currentTask;
  int get todayFocusMinutes => _todayFocusMinutes;
  int get todayMinutes => _todayFocusMinutes;
  bool get isRunning => _session?.status == FocusSessionStatus.running;
  bool get isPaused => _session?.status == FocusSessionStatus.paused;
  bool get isIdle => _session == null || _session?.status == FocusSessionStatus.idle || _session?.status == FocusSessionStatus.completed || _session?.status == FocusSessionStatus.abandoned;

  Duration get remaining =>
      _session?.remaining() ??
      const Duration(minutes: EkagraConstants.defaultFocusMinutes);

  String get formattedTime => DateHelpers.formatDuration(remaining);

  double get progress => _session?.progress() ?? 0;

  int get elapsedSeconds {
    if (_session == null) return 0;
    final total = _session!.plannedMinutes * 60;
    return (total - remaining.inSeconds).clamp(0, total);
  }

  void setTask(TaskModel task) {
    _currentTask = task;
    prepare(task: task);
  }

  void prepare({TaskModel? task, int? minutes}) {
    _currentTask = task ?? _currentTask;
    _session = FocusSession.create(
      taskId: _currentTask?.id,
      taskTitle: _currentTask?.title,
      plannedMinutes: minutes ??
          _currentTask?.estimatedMinutes ??
          EkagraConstants.defaultFocusMinutes,
    );
    notifyListeners();
  }

  void setDuration(int minutes) {
    if (_session == null || isRunning) {
      _session = FocusSession.create(
        taskId: _currentTask?.id,
        taskTitle: _currentTask?.title,
        plannedMinutes: minutes,
      );
    } else {
      _session = _session!.copyWith(plannedMinutes: minutes);
    }
    notifyListeners();
  }

  void startTimer(Duration duration) {
    setDuration(duration.inMinutes);
    start();
  }

  void start() {
    final planned = _session?.plannedMinutes ?? EkagraConstants.defaultFocusMinutes;
    final now = DateTime.now();
    _session = (_session ?? FocusSession.create(plannedMinutes: planned)).copyWith(
      startedAt: now,
      endsAt: now.add(Duration(minutes: planned)),
      status: FocusSessionStatus.running,
      accumulatedPausedSeconds: 0,
      pausedAt: null,
    );
    _startTicker();
    notifyListeners();
  }

  void pauseTimer() => pause();

  void pause() {
    if (_session == null || !isRunning) return;
    _session = _session!.copyWith(
      status: FocusSessionStatus.paused,
      pausedAt: DateTime.now(),
    );
    _ticker?.cancel();
    notifyListeners();
  }

  void resumeTimer() => resume();

  void resume() {
    if (_session == null || !isPaused || _session!.pausedAt == null) return;
    final pausedAt = _session!.pausedAt!;
    final pauseDuration = DateTime.now().difference(pausedAt);
    final newEnds = _session!.endsAt!.add(pauseDuration);
    _session = _session!.copyWith(
      status: FocusSessionStatus.running,
      endsAt: newEnds,
      pausedAt: null,
      accumulatedPausedSeconds:
          _session!.accumulatedPausedSeconds + pauseDuration.inSeconds,
    );
    _startTicker();
    notifyListeners();
  }

  void abandon() {
    _ticker?.cancel();
    if (_session != null) {
      _session = _session!.copyWith(status: FocusSessionStatus.abandoned);
    }
    notifyListeners();
  }

  void completeTimer() => complete();

  void complete() {
    _ticker?.cancel();
    if (_session == null) return;
    final elapsed = _session!.plannedMinutes -
        _session!.remaining().inMinutes.clamp(0, _session!.plannedMinutes);
    _todayFocusMinutes += elapsed > 0 ? elapsed : _session!.plannedMinutes;
    _session = _session!.copyWith(status: FocusSessionStatus.completed);
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _session = null;
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_session == null) return;
      if (_session!.remaining() == Duration.zero && isRunning) {
        complete();
      } else {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

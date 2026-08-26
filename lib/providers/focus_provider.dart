import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/focus_session_model.dart';
import '../models/task_model.dart';
import '../services/analytics_service.dart';
import '../services/growth_service.dart';
import '../utils/date_helpers.dart';
import '../utils/safe_store.dart';
import 'reward_provider.dart';
import 'task_provider.dart';

/// Focus timing + crash-safe persistence of the in-flight session (K20/ADR-005).
///
/// The wall-clock design (Spec H3) already made *display* drift impossible:
/// `FocusSession.remaining()` is always `endsAt - now`. What it did not
/// survive was the OS killing the process — the session, the day's minutes
/// and the reward lived only in memory, and ADHD usage patterns (force
/// quits, memory pressure, dead batteries) made that loss routine.
///
/// Every state transition now persists the session, and `reconcile()` runs
/// once at boot: a session that ended while the app was dead is completed
/// retroactively exactly once (idempotent reward), a session still inside
/// its window resumes against the wall clock — no drift by construction.
class FocusProvider extends ChangeNotifier {
  static const _sessionKey = 'ekagra_focus_session';
  static const _minutesKey = 'ekagra_focus_today_minutes';
  static const _minutesDayKey = 'ekagra_focus_minutes_day';
  static const _rewardFiredKey = 'ekagra_focus_reward_fired_for';

  FocusSession? _session;
  TaskModel? _currentTask;
  Timer? _ticker;
  int _todayFocusMinutes = 0;
  int? _reconciledMinutes;

  FocusSession? get session => _session;
  TaskModel? get currentTask => _currentTask;
  int get todayFocusMinutes => _todayFocusMinutes;
  int get todayMinutes => _todayFocusMinutes;
  bool get isRunning => _session?.status == FocusSessionStatus.running;
  bool get isPaused => _session?.status == FocusSessionStatus.paused;
  bool get isIdle =>
      _session == null ||
      _session?.status == FocusSessionStatus.idle ||
      _session?.status == FocusSessionStatus.completed ||
      _session?.status == FocusSessionStatus.abandoned;

  /// Minutes of a session that completed while the app was dead, shown once
  /// as a gentle acknowledgement on Home, then consumed.
  int? get pendingReconcileMinutes => _reconciledMinutes;

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
      plannedMinutes:
          minutes ??
          _currentTask?.estimatedMinutes ??
          EkagraConstants.defaultFocusMinutes,
    );
    _persistSession();
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
    _persistSession();
    notifyListeners();
  }

  void startTimer(Duration duration) {
    setDuration(duration.inMinutes);
    start();
  }

  void start() {
    final planned =
        _session?.plannedMinutes ?? EkagraConstants.defaultFocusMinutes;
    final now = DateTime.now();
    _session = (_session ?? FocusSession.create(plannedMinutes: planned))
        .copyWith(
          startedAt: now,
          endsAt: now.add(Duration(minutes: planned)),
          status: FocusSessionStatus.running,
          accumulatedPausedSeconds: 0,
          pausedAt: null,
        );
    _persistSession();
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
    _persistSession();
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
    _persistSession();
    _startTicker();
    notifyListeners();
  }

  void abandon() {
    _ticker?.cancel();
    if (_session != null) {
      _session = _session!.copyWith(status: FocusSessionStatus.abandoned);
    }
    _clearPersistedSession();
    notifyListeners();
  }

  void completeTimer() => complete();

  void complete() {
    _ticker?.cancel();
    if (_session == null) return;
    final elapsed =
        _session!.plannedMinutes -
        _session!.remaining().inMinutes.clamp(0, _session!.plannedMinutes);
    _todayFocusMinutes += elapsed > 0 ? elapsed : _session!.plannedMinutes;
    _session = _session!.copyWith(status: FocusSessionStatus.completed);
    _persistTodayMinutes();
    _clearPersistedSession();
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _session = null;
    _clearPersistedSession();
    notifyListeners();
  }

  /// Consume the "finished while you were away" acknowledgement.
  void consumeReconcileNotice() {
    _reconciledMinutes = null;
    notifyListeners();
  }

  // ── Boot reconciliation (ADR-005) ─────────────────────────────────────────

  /// Run once at app start, after providers have loaded.
  ///
  /// * Running + `endsAt` passed  → retro-complete once: minutes recorded,
  ///   reward fired behind an idempotency marker, `focusSessionReconciled`.
  /// * Running + time left        → restored and ticking against wall clock.
  /// * Paused                     → restored paused, no ticker.
  /// * Corrupt payload            → SafeStore quarantine path, app boots.
  Future<void> reconcile({
    required TaskProvider tasks,
    required RewardProvider rewards,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Day rollover: yesterday's minutes do not leak into today.
    if (prefs.getString(_minutesDayKey) != _dayKey(DateTime.now())) {
      _todayFocusMinutes = 0;
    } else {
      _todayFocusMinutes = prefs.getInt(_minutesKey) ?? 0;
    }

    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return;

    final map = SafeStore.decodeObject(raw: raw, key: _sessionKey);
    if (map == null) {
      await _clearPersistedSession();
      return;
    }
    final restored = SafeStore.tryBuild(
      () => FocusSession.fromJson(map),
      key: _sessionKey,
    );
    if (restored == null) {
      await _clearPersistedSession();
      return;
    }

    _currentTask = _taskById(tasks, restored.taskId);

    if (restored.status == FocusSessionStatus.running) {
      final endedWhileDead =
          restored.endsAt != null &&
          !restored.endsAt!.isAfter(DateTime.now());
      if (endedWhileDead) {
        // The marker makes the whole retro-completion idempotent: if this
        // session was already reconciled (a stale duplicate payload), it is
        // discarded without re-adding minutes or re-firing the reward.
        final alreadyReconciled = prefs.getString(_rewardFiredKey) ==
            restored.id;
        if (alreadyReconciled) {
          await _clearPersistedSession();
        } else {
          await _completeWhileAway(
            session: restored,
            prefs: prefs,
            tasks: tasks,
            rewards: rewards,
          );
        }
      } else {
        _session = restored;
        _persistSession();
        _startTicker();
        notifyListeners();
      }
    } else if (restored.status == FocusSessionStatus.paused) {
      _session = restored;
      _persistSession();
      notifyListeners();
    } else {
      await _clearPersistedSession();
    }
  }

  Future<void> _completeWhileAway({
    required FocusSession session,
    required SharedPreferences prefs,
    required TaskProvider tasks,
    required RewardProvider rewards,
  }) async {
    final minutes = session.plannedMinutes;
    _todayFocusMinutes += minutes;
    _session = session.copyWith(status: FocusSessionStatus.completed);

    // The reward fires at most once per session id, ever. Reconciliation is
    // re-entrant by design (a second boot with the same persisted payload
    // must be a no-op).
    final alreadyFired = prefs.getString(_rewardFiredKey) == session.id;
    var firedReward = false;
    if (!alreadyFired) {
      await prefs.setString(_rewardFiredKey, session.id);
      final task = _taskById(tasks, session.taskId);
      if (session.taskId != null && task != null && !task.isCompleted) {
        await rewards.recordTaskCompletion(session.taskId!);
        firedReward = true;
      }
    }

    await GrowthService.instance.recordFocusSession(minutes);
    await _persistTodayMinutes();
    await _clearPersistedSession();

    track(Ev.focusSessionReconciled, {
      'outcome': 'completed_while_away',
      'minutes': minutes,
      'reward_fired': firedReward || alreadyFired,
      'had_task': session.taskId != null,
    });

    _reconciledMinutes = minutes;
    notifyListeners();
  }

  TaskModel? _taskById(TaskProvider tasks, String? id) {
    if (id == null) return null;
    for (final t in tasks.tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ── Persistence helpers ───────────────────────────────────────────────────

  void _persistSession() {
    if (_session == null || isIdle) return;
    unawaited(_writeSession(_session!));
  }

  Future<void> _writeSession(FocusSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    } catch (_) {
      // Persistence is best-effort: the wall clock still protects the
      // in-memory session, and a failed write must never crash focus mode.
    }
  }

  void _clearPersistedSession() {
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_sessionKey);
      } catch (_) {}
    }());
  }

  void _persistTodayMinutes() {
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_minutesKey, _todayFocusMinutes);
        await prefs.setString(_minutesDayKey, _dayKey(DateTime.now()));
      } catch (_) {}
    }());
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

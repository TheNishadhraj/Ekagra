import 'package:flutter/foundation.dart';

import '../models/focus_session_model.dart';
import 'analytics_service.dart';
import 'local_notifications_adapter.dart';
import 'nudge_copy.dart';

/// The sidekick engine (WI-1.4) — the app comes to the user.
///
/// Policy in one paragraph: when a task becomes The One Thing and the user
/// walks away, up to **three** gentle nudges fire (first at +45 min, then
/// +10, then +30). Opening the app or completing the task cancels the rest.
/// After the third, the system **stops silently** — it gives up gracefully,
/// shame-free (Rule 14: no nagging forever). One optional daily brief. One
/// welcome-back nudge after a 3-day gap. Nothing else, ever.
///
/// Offline-first: 100% local scheduling, no backend, no network.
class NudgeService {
  NudgeService({
    LocalNotificationsAdapter? adapter,
    DateTime Function()? clock,
  }) : _adapter = adapter ?? FlutterLocalNotificationsAdapter(),
       _clock = clock ?? DateTime.now;

  static final NudgeService instance = NudgeService();

  /// Fixed notification ids, kept clear of the task-hash range.
  static const _dailyBriefId = 1001;
  static const _welcomeBackId = 1002;
  static const _transitionId = 2000;

  /// Per-task policy: first nudge delay, then re-nudge offsets, hard cap.
  static const firstNudgeDelay = Duration(minutes: 45);
  static const List<Duration> reNudgeDelays = [
    Duration(minutes: 10),
    Duration(minutes: 30),
  ];
  static const maxNudges = 3;
  static const welcomeBackGap = Duration(days: 3);

  final LocalNotificationsAdapter _adapter;
  final DateTime Function() _clock;
  final Set<String> _activeTaskIds = {};

  bool _initialized = false;
  bool _enabled = false;

  /// Route handler for taps: set by main() so payloads become navigation
  /// without this service knowing about BuildContext.
  void Function(String payload)? onOpenPayload;

  bool get enabled => _enabled;

  /// Initialize the platform adapter. Safe to call repeatedly.
  Future<void> init({required bool enabled}) async {
    if (_initialized) {
      this.enabledSet(enabled);
      return;
    }
    _initialized = await _adapter.initialize(_handleTap) || _initialized;
    this.enabledSet(enabled);
  }

  /// Master switch (the Settings opt-out). Turning off cancels everything
  /// and forgets pending policies — "opt-out stops all" is test-enforced.
  Future<void> enabledSet(bool value) async {
    _enabled = value;
    if (!value) {
      _activeTaskIds.clear();
      await _adapter.cancelAll();
    }
  }

  Future<bool> requestPermission() => _adapter.requestPermission();

  // ── Daily "One Thing" brief ───────────────────────────────────────────────

  /// One notification per day at [hour], rotating copy weekly.
  Future<bool> scheduleDailyBrief({int hour = 8}) {
    if (!_enabled) return Future.value(false);
    final now = _clock();
    var at = DateTime(now.year, now.month, now.day, hour);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    return _adapter.schedule(
      id: _dailyBriefId,
      title: NudgeCopy.dailyBriefTitle(now),
      body: NudgeCopy.dailyBriefBody(now),
      at: at,
      payload: 'home',
      daily: true,
    );
  }

  Future<bool> cancelDailyBrief() => _adapter.cancel(_dailyBriefId);

  // ── Per-task nudge sequence ───────────────────────────────────────────────

  /// Schedule the full capped sequence up front (robust to process death).
  Future<void> beginTaskNudges({
    required String taskId,
    required String taskTitle,
  }) async {
    if (!_enabled) return;
    await cancelTaskNudges(taskId);
    final now = _clock();
    var at = now.add(firstNudgeDelay);
    var scheduled = 0;
    for (var i = 0; i < maxNudges; i++) {
      if (scheduled > 0) {
        at = at.add(reNudgeDelays[(scheduled - 1).clamp(0, 1)]);
      }
      final ok = await _adapter.schedule(
        id: taskIdToNotificationId(taskId, i),
        title: NudgeCopy.taskTitle(now),
        body: NudgeCopy.taskBody(now, taskTitle),
        at: at,
        payload: 'task:$taskId',
      );
      if (!ok) break;
      scheduled++;
    }
    if (scheduled > 0) {
      _activeTaskIds.add(taskId);
    }
  }

  /// Cancel any remaining nudges for a task (completion or app open).
  Future<void> cancelTaskNudges(String taskId) async {
    for (var i = 0; i < maxNudges; i++) {
      await _adapter.cancel(taskIdToNotificationId(taskId, i));
    }
    _activeTaskIds.remove(taskId);
  }

  /// Cancel every armed task sequence (app resumed). Does NOT touch the
  /// daily brief or other fixed-id nudges.
  Future<void> cancelAllTaskNudges() async {
    final ids = _activeTaskIds.toList();
    _activeTaskIds.clear();
    for (final id in ids) {
      await cancelTaskNudges(id);
    }
  }

  /// Stable, collision-unlikely id for a task's nudge # [seq].
  @visibleForTesting
  static int taskIdToNotificationId(String taskId, int seq) {
    final h = taskId.hashCode & 0x7FFFFFFF;
    return 1000000 + (h % 900000) * 10 + seq;
  }

  // ── Welcome-back nudge ────────────────────────────────────────────────────

  /// One-time "nothing was lost" nudge, scheduled when the app backgrounds
  /// and cancelled on any earlier return. Fires at 10:00 local.
  Future<bool> scheduleWelcomeBack() {
    if (!_enabled) return Future.value(false);
    final now = _clock();
    var at = DateTime(
      now.year,
      now.month,
      now.day + welcomeBackGap.inDays,
      10,
    );
    return _adapter.schedule(
      id: _welcomeBackId,
      title: NudgeCopy.welcomeBackTitle(now),
      body: NudgeCopy.welcomeBackBody(now),
      at: at,
      payload: 'home',
    );
  }

  Future<bool> cancelWelcomeBack() => _adapter.cancel(_welcomeBackId);

  // ── Focus transition alert (feeds Day View / Focus Mode, WI-2.2) ─────────

  /// "15 min left" for a running session; cancelled on any transition.
  Future<bool> scheduleTransitionAlert(FocusSession session) async {
    await cancelTransitionAlert();
    if (!_enabled || session.endsAt == null) return false;
    if (session.plannedMinutes <= 15) return false;
    final at = session.endsAt!.subtract(const Duration(minutes: 15));
    if (!at.isAfter(_clock())) return false;
    return _adapter.schedule(
      id: _transitionId,
      title: NudgeCopy.transitionTitle(_clock()),
      body: NudgeCopy.transitionBody(_clock(), session.taskTitle ?? 'your session'),
      at: at,
      payload: 'focus',
    );
  }

  Future<bool> cancelTransitionAlert() => _adapter.cancel(_transitionId);

  // ── Tap routing ───────────────────────────────────────────────────────────

  void _handleTap(String payload) {
    track(Ev.notificationOpened, {'payload': payload});
    onOpenPayload?.call(payload);
  }
}

import 'dart:convert';

import 'package:ekagra/models/focus_session_model.dart';
import 'package:ekagra/models/task_model.dart';
import 'package:ekagra/providers/focus_provider.dart';
import 'package:ekagra/providers/reward_provider.dart';
import 'package:ekagra/providers/task_provider.dart';
import 'package:ekagra/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WI-1.2 / ADR-005 — the three kill scenarios.
///
/// 1. Session ENDED while the app was dead → retro-complete: minutes
///    recorded, reward fired exactly once (idempotent on re-reconcile).
/// 2. Session still RUNNING when the app died → restored, ticking against
///    the wall clock, correct remaining time.
/// 3. Corrupt persisted payload → SafeStore quarantine path, app boots,
///    no reward, no crash.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AnalyticsService.instance.resetForTest();
  });

  /// Persistence writes are deliberately fire-and-forget in production;
  /// tests must let them land before asserting on SharedPreferences.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 60));

  FocusSession persistedRunningSession({
    required DateTime endsAt,
    String? taskId,
  }) {
    return FocusSession(
      id: 'session-kill-1',
      taskId: taskId,
      taskTitle: 'Reply to landlord',
      plannedMinutes: 25,
      startedAt: endsAt.subtract(const Duration(minutes: 25)),
      endsAt: endsAt,
      status: FocusSessionStatus.running,
      createdAt: endsAt.subtract(const Duration(minutes: 26)),
    );
  }

  Future<void> seedSession(FocusSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ekagra_focus_session',
      jsonEncode(session.toJson()),
    );
  }

  test('kill scenario 1: session ended while dead — completes once, reward fires once', () async {
    final tasks = TaskProvider();
    await tasks.load();
    final task = await tasks.addTask('Reply to landlord');
    final rewards = RewardProvider();
    await rewards.load();

    await seedSession(
      persistedRunningSession(
        endsAt: DateTime.now().subtract(const Duration(minutes: 5)),
        taskId: task.id,
      ),
    );

    final focus = FocusProvider();
    await focus.reconcile(tasks: tasks, rewards: rewards);

    expect(focus.todayFocusMinutes, 25);
    expect(focus.pendingReconcileMinutes, 25);
    expect(focus.isIdle, isTrue);
    expect(rewards.history.length, 1, reason: 'reward fired once');

    // The persisted session is consumed…
    await settle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ekagra_focus_session'), isNull);

    // …so a second reconcile (another boot) is a full no-op.
    await seedSession(
      persistedRunningSession(
        endsAt: DateTime.now().subtract(const Duration(minutes: 5)),
        taskId: task.id,
      ),
    );
    await focus.reconcile(tasks: tasks, rewards: rewards);
    expect(focus.todayFocusMinutes, 25, reason: 'minutes not double-counted');
    expect(rewards.history.length, 1, reason: 'no double reward');
  });

  test('kill scenario 2: session still running — restored with wall-clock remaining', () async {
    final tasks = TaskProvider();
    await tasks.load();
    final rewards = RewardProvider();
    await rewards.load();

    final endsAt = DateTime.now().add(const Duration(minutes: 10));
    await seedSession(persistedRunningSession(endsAt: endsAt));

    final focus = FocusProvider();
    await focus.reconcile(tasks: tasks, rewards: rewards);

    expect(focus.isRunning, isTrue);
    final remaining = focus.remaining;
    expect(remaining.inMinutes, lessThanOrEqualTo(10));
    expect(remaining.inMinutes, greaterThanOrEqualTo(9));
    expect(focus.pendingReconcileMinutes, isNull,
        reason: 'nothing completed while away');

    // Ticker must not leak into other tests.
    focus.reset();
  });

  test('kill scenario 2b: paused session — restored paused, no ticker', () async {
    final tasks = TaskProvider();
    await tasks.load();
    final rewards = RewardProvider();
    await rewards.load();

    await seedSession(
      persistedRunningSession(
            endsAt: DateTime.now().add(const Duration(minutes: 20)),
          )
          .copyWith(
            status: FocusSessionStatus.paused,
            pausedAt: DateTime.now().subtract(const Duration(minutes: 3)),
          ),
    );

    final focus = FocusProvider();
    await focus.reconcile(tasks: tasks, rewards: rewards);
    expect(focus.isPaused, isTrue);
    expect(focus.todayFocusMinutes, 0);
    focus.reset();
  });

  test('kill scenario 3: corrupt session payload — SafeStore path, app boots', () async {
    final tasks = TaskProvider();
    await tasks.load();
    final rewards = RewardProvider();
    await rewards.load();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ekagra_focus_session', '{not json at all');

    final focus = FocusProvider();
    await focus.reconcile(tasks: tasks, rewards: rewards);
    await settle();

    expect(focus.isIdle, isTrue);
    expect(focus.todayFocusMinutes, 0);
    expect(rewards.history.length, 0);
    // The bad payload was quarantined, not silently discarded (ADR-001).
    expect(
      await SharedPreferences.getInstance()
          .then((p) => p.getString('ekagra_focus_session__corrupt')),
      isNotNull,
    );
  });

  test('day rollover: yesterday\'s minutes do not leak into today', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dayKey =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ekagra_focus_today_minutes', 80);
    await prefs.setString('ekagra_focus_minutes_day', dayKey);

    final tasks = TaskProvider();
    await tasks.load();
    final rewards = RewardProvider();
    await rewards.load();
    final focus = FocusProvider();
    await focus.reconcile(tasks: tasks, rewards: rewards);
    expect(focus.todayFocusMinutes, 0);
  });

  test('live path: start then complete persists and clears correctly', () async {
    final focus = FocusProvider();
    focus.prepare(task: null, minutes: 5);
    focus.start();
    await settle();
    var persisted = (await SharedPreferences.getInstance())
        .getString('ekagra_focus_session');
    expect(persisted, isNotNull, reason: 'session persisted on start');

    focus.completeTimer();
    await settle();
    persisted = (await SharedPreferences.getInstance())
        .getString('ekagra_focus_session');
    expect(persisted, isNull, reason: 'cleared on complete');
    expect(focus.todayFocusMinutes, 5);
  });
}

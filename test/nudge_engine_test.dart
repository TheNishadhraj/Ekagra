import 'package:ekagra/models/focus_session_model.dart';
import 'package:ekagra/services/local_notifications_adapter.dart';
import 'package:ekagra/services/nudge_copy.dart';
import 'package:ekagra/services/nudge_service.dart';
import 'package:ekagra/utils/rsd_safe_copy.dart';
import 'package:flutter_test/flutter_test.dart';

/// WI-1.4 — the sidekick engine's policy envelope.
///
/// Acceptance being encoded: a task produces AT MOST 3 gentle nudges,
/// completing early cancels the rest, opt-out stops everything, ids are
/// stable, scheduling is timezone-safe by construction (wall-clock
/// DateTimes handed to the adapter), and every copy string is RSD-safe.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('policy', () {
    test('a task arms at most 3 nudges at the right offsets', () async {
      final fake = _FakeAdapter();
      final now = DateTime(2026, 8, 26, 10, 0);
      final service = NudgeService(adapter: fake, clock: () => now);

      await service.init(enabled: true);
      fake.scheduled.clear();

      await service.beginTaskNudges(
        taskId: 'task-1',
        taskTitle: 'Reply to landlord',
      );

      expect(fake.scheduled.length, NudgeService.maxNudges);
      final times = fake.scheduled.map((s) => s.at).toList();
      // first at +45m, then +10m, then +30m
      expect(times[0], now.add(const Duration(minutes: 45)));
      expect(times[1], times[0].add(const Duration(minutes: 10)));
      expect(times[2], times[1].add(const Duration(minutes: 30)));
      // every payload deep-links to the task
      expect(
        fake.scheduled.every((s) => s.payload == 'task:task-1'),
        isTrue,
      );
    });

    test('completing early cancels the remaining nudges', () async {
      final fake = _FakeAdapter();
      final now = DateTime(2026, 8, 26, 10, 0);
      final service = NudgeService(adapter: fake, clock: () => now);
      await service.init(enabled: true);
      fake.scheduled.clear();
      fake.cancelled.clear();

      await service.beginTaskNudges(taskId: 'task-2', taskTitle: 'Drink water');
      await service.cancelTaskNudges('task-2');

      expect(fake.cancelled.length, NudgeService.maxNudges);
      // exactly the ids that were armed
      for (var i = 0; i < NudgeService.maxNudges; i++) {
        expect(
          fake.cancelled,
          contains(NudgeService.taskIdToNotificationId('task-2', i)),
        );
      }
      // and no lingering armed state
      await service.cancelAllTaskNudges();
      expect(fake.cancelled.length, NudgeService.maxNudges);
    });

    test('opt-out stops all: no new scheduling, everything cancelled', () async {
      final fake = _FakeAdapter();
      final service = NudgeService(
        adapter: fake,
        clock: () => DateTime(2026, 8, 26, 10, 0),
      );
      await service.init(enabled: true);
      await service.enabledSet(false);

      fake.scheduled.clear();
      fake.cancelled.clear();

      await service.beginTaskNudges(taskId: 't', taskTitle: 'x');
      await service.scheduleDailyBrief();
      await service.scheduleWelcomeBack();

      expect(fake.scheduled, isEmpty, reason: 'nothing new after opt-out');
      expect(fake.cancelAllCalled, isTrue, reason: 'pending ones cancelled');
    });

    test('task nudge ids are stable and distinct per sequence slot', () {
      final a = NudgeService.taskIdToNotificationId('same-task', 0);
      final b = NudgeService.taskIdToNotificationId('same-task', 0);
      final c = NudgeService.taskIdToNotificationId('same-task', 1);
      expect(a, b);
      expect(a, isNot(c));
      expect(a, greaterThanOrEqualTo(1000000));
    });

    test('transition alert fires only for sessions longer than 15 min',
        () async {
      final fake = _FakeAdapter();
      final now = DateTime(2026, 8, 26, 10, 0);
      final service = NudgeService(adapter: fake, clock: () => now);
      await service.init(enabled: true);
      fake.scheduled.clear();

      final long = FocusSession.create(plannedMinutes: 25).copyWith(
        startedAt: now,
        endsAt: now.add(const Duration(minutes: 25)),
        status: FocusSessionStatus.running,
        taskTitle: 'Deep work',
      );
      final ok = await service.scheduleTransitionAlert(long);
      expect(ok, isTrue);
      expect(fake.scheduled.single.at, now.add(const Duration(minutes: 10)));

      fake.scheduled.clear();
      final short = FocusSession.create(plannedMinutes: 10).copyWith(
        startedAt: now,
        endsAt: now.add(const Duration(minutes: 10)),
        status: FocusSessionStatus.running,
      );
      expect(await service.scheduleTransitionAlert(short), isFalse);
      expect(fake.scheduled, isEmpty);
    });

    test('welcome-back nudge is 3 days out at 10:00, and cancellable',
        () async {
      final fake = _FakeAdapter();
      final now = DateTime(2026, 8, 26, 22, 30);
      final service = NudgeService(adapter: fake, clock: () => now);
      await service.init(enabled: true);
      fake.scheduled.clear();

      expect(await service.scheduleWelcomeBack(), isTrue);
      expect(fake.scheduled.single.at, DateTime(2026, 8, 29, 10, 0));

      fake.cancelled.clear();
      await service.cancelWelcomeBack();
      expect(fake.cancelled, contains(1002));
    });
  });

  group('copy bank', () {
    test('every rotation of every bank passes RsdSafeCopy', () {
      for (final s in NudgeCopy.allStrings) {
        expect(
          RsdSafeCopy.isSafe(s),
          isTrue,
          reason: 'nudge copy is user-facing: "$s" must be shame-free',
        );
      }
    });

    test('titles rotate weekly and never repeat back-to-back weeks', () {
      final week1 = DateTime(2026, 8, 24); // a Monday
      final week2 = week1.add(const Duration(days: 7));
      expect(NudgeCopy.taskTitle(week1), isNot(NudgeCopy.taskTitle(week2)));
      // deterministic within a week
      expect(
        NudgeCopy.taskTitle(week1),
        NudgeCopy.taskTitle(week1.add(const Duration(days: 3))),
      );
    });

    test('titles stay within the icon + few-words evidence budget', () {
      for (final bank in [
        NudgeCopy.taskTitles,
        NudgeCopy.dailyBriefTitles,
        NudgeCopy.welcomeBackTitles,
        NudgeCopy.transitionTitles,
      ]) {
        for (final t in bank) {
          expect(t.split(' ').length, lessThanOrEqualTo(6),
              reason: '"$t" — minimal text outperforms paragraphs');
        }
      }
    });
  });
}

class _Scheduled {
  _Scheduled(this.id, this.title, this.body, this.at, this.payload);
  final int id;
  final String title;
  final String body;
  final DateTime at;
  final String? payload;
}

class _FakeAdapter implements LocalNotificationsAdapter {
  final scheduled = <_Scheduled>[];
  final cancelled = <int>[];
  bool cancelAllCalled = false;

  @override
  Future<bool> initialize(void Function(String payload)? onTap) async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
    bool daily = false,
  }) async {
    scheduled.add(_Scheduled(id, title, body, at, payload));
    return true;
  }

  @override
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    scheduled.add(_Scheduled(id, title, body, DateTime.now(), payload));
    return true;
  }

  @override
  Future<bool> cancel(int id) async {
    cancelled.add(id);
    return true;
  }

  @override
  Future<bool> cancelAll() async {
    cancelAllCalled = true;
    return true;
  }
}

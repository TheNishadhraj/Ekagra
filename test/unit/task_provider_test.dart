import 'dart:convert';

import 'package:ekagra/models/task_model.dart';
import 'package:ekagra/providers/task_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('addTask', () {
    test('adds and persists a task', () async {
      final p = TaskProvider();
      final t = await p.addTask('Reply to email');
      expect(p.tasks.map((e) => e.title), contains('Reply to email'));
      expect(p.tasks.length, 1);
      expect(t.title, 'Reply to email');
    });

    test('trims whitespace from title', () async {
      final p = TaskProvider();
      await p.addTask('  trim me  ');
      expect(p.tasks.single.title, 'trim me');
    });
  });

  group('addTasks', () {
    test('skips blank titles', () async {
      final p = TaskProvider();
      await p.addTasks(['a', '', '  ', 'b']);
      expect(p.tasks.map((e) => e.title), ['a', 'b']);
    });
  });

  group('completeTask', () {
    test('marks task completed', () async {
      final p = TaskProvider();
      final t = await p.addTask('Reply to email');
      await p.completeTask(t.id);
      final completed = p.allIncludingDeleted.firstWhere((e) => e.id == t.id);
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);
    });

    test('completing unknown id does not throw', () async {
      final p = TaskProvider();
      await p.completeTask('unknown_id');
    });

    test('completed task appears in completedToday', () async {
      final p = TaskProvider();
      final t = await p.addTask('Reply to email');
      await p.completeTask(t.id);
      expect(p.completedToday.map((e) => e.id), contains(t.id));
    });
  });

  group('archiveTask (soft delete)', () {
    test('removes task from active list but keeps record in allIncludingDeleted', () async {
      final p = TaskProvider();
      final t = await p.addTask('Reply to email');
      await p.archiveTask(t.id);
      expect(p.tasks, isEmpty);
      final archived = p.allIncludingDeleted.single;
      expect(archived.isDeleted, isTrue);
      expect(archived.status, TaskStatus.archived);
    });

    test('archiving unknown id does not throw', () async {
      final p = TaskProvider();
      await p.archiveTask('unknown_id');
    });
  });

  group('free tier limits', () {
    test('hits soft limit at 10 active incomplete tasks', () async {
      final p = TaskProvider();
      for (var i = 0; i < 10; i++) {
        await p.addTask('Task $i');
      }
      expect(p.atFreeTaskLimit, isTrue);
    });

    test('is under limit below 10 active incomplete tasks', () async {
      final p = TaskProvider();
      await p.addTask('Task 1');
      expect(p.atFreeTaskLimit, isFalse);
    });
  });

  group('skipOneThing', () {
    test('records skip and advances oneThing candidate', () async {
      final p = TaskProvider();
      await p.addTask('Reply to email');
      await p.addTask('Drink water', scheduleType: TaskScheduleType.today);
      p.refreshOneThing();
      expect(p.oneThing!.title, 'Drink water');

      p.skipOneThing();
      expect(p.skipCount, 1);
      expect(p.oneThing, isNotNull);
      expect(p.oneThing!.title, 'Reply to email');
    });
  });

  group('upcoming', () {
    test('excludes current oneThing and caps at maxUpcomingTasksOnHome', () async {
      final p = TaskProvider();
      for (var i = 0; i < 8; i++) {
        await p.addTask('anytime $i');
      }
      await p.addTask('star task', scheduleType: TaskScheduleType.today);
      p.refreshOneThing();

      expect(p.oneThing!.title, 'star task');
      expect(p.upcoming.map((e) => e.title), isNot(contains('star task')));
      expect(p.upcoming.length, 4);
    });
  });

  group('load', () {
    test('loads empty store gracefully', () async {
      SharedPreferences.setMockInitialValues({});
      final p = TaskProvider();
      await p.load();
      expect(p.tasks, isEmpty);
      expect(p.loaded, isTrue);
    });

    test('round-trips persisted tasks correctly', () async {
      final p1 = TaskProvider();
      await p1.addTask('Reply to email', scheduleType: TaskScheduleType.today, notes: 'to Sarah');
      await p1.addTask('Drink water');

      final raw = (await SharedPreferences.getInstance()).getString('ekagra_tasks')!;

      final p2 = TaskProvider();
      await p2.load();
      expect(p2.tasks.length, 2);
      expect(p2.tasks.map((e) => e.title), ['Drink water', 'Reply to email']);

      final email = p2.tasks.firstWhere((e) => e.title == 'Reply to email');
      expect(email.scheduleType, TaskScheduleType.today);
      expect(email.notes, 'to Sarah');
      expect(raw, isNotEmpty);
      expect(() => jsonDecode(raw), returnsNormally);
    });
  });
}

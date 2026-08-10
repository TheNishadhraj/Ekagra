import 'dart:convert';

import 'package:ekagra/providers/task_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RESILIENCE SUITE — Persistence failure mode analysis for TaskProvider.
/// A startup crash is a data-loss event. This test suite verifies that
/// corrupted, truncated, or malformed payloads in storage do not crash launch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TaskProvider> loadWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final provider = TaskProvider();
    await provider.load();
    return provider;
  }

  group('Persistence Recovery & Resilience', () {
    test('round-trips valid data correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final p1 = TaskProvider();
      await p1.addTask('Reply to email');
      await p1.addTask('Drink water');

      final p2 = TaskProvider();
      await p2.load();
      expect(p2.tasks.length, 2);
    });

    test('missing persisted value loads as an empty, ready store', () async {
      final p = await loadWith({});
      expect(p.tasks, isEmpty);
      expect(p.loaded, isTrue);
    });

    test('every mutation leaves a complete, parseable JSON snapshot', () async {
      SharedPreferences.setMockInitialValues({});
      final p = TaskProvider();
      for (var i = 0; i < 20; i++) {
        await p.addTask('task $i');
        final raw = (await SharedPreferences.getInstance()).getString('ekagra_tasks');
        expect(raw, isNotNull);
        expect(() => jsonDecode(raw!), returnsNormally);
      }
    });

    test('truncated / non-JSON payload does not crash load()', () async {
      final p = await loadWith({'ekagra_tasks': '{"ekagra_tasks": [{"id": "t1", "title": "Email", '});
      expect(p.tasks, isEmpty);
      expect(p.loaded, isTrue);
    });

    test('valid JSON of the wrong top-level type does not crash load()', () async {
      final p = await loadWith({'ekagra_tasks': '{"not": "a list"}'});
      expect(p.tasks, isEmpty);
      expect(p.loaded, isTrue);
    });

    test('list entries that are not objects do not crash load()', () async {
      final p = await loadWith({'ekagra_tasks': '["just a string", 123]'});
      expect(p.tasks, isEmpty);
      expect(p.loaded, isTrue);
    });

    test('a task missing required fields falls back safely without crashing', () async {
      final p = await loadWith({'ekagra_tasks': '[{"title": "orphan task"}]'});
      expect(p.tasks.length, 1);
      expect(p.tasks.first.title, 'orphan task');
      expect(p.loaded, isTrue);
    });

    test('an unknown enum value falls back safely without crashing', () async {
      final p = await loadWith({
        'ekagra_tasks':
            '[{"title":"task with bad enum","scheduleType":"somedayUnknown","createdAt":"2026-01-01T00:00:00.000"}]'
      });
      expect(p.tasks.length, 1);
      expect(p.tasks.first.title, 'task with bad enum');
      expect(p.loaded, isTrue);
    });

    test('simulated torn snapshot (mid-write exit) recovers without crashing launch', () async {
      final good = [
        {
          'id': 'a',
          'title': 'Email',
          'scheduleType': 'today',
          'status': 'notStarted',
          'energyNeeded': 'medium',
          'subtasks': [],
          'isDeleted': false,
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
          'skipCount': 0
        }
      ];
      final torn = jsonEncode(good).substring(0, jsonEncode(good).length ~/ 2);
      final p = await loadWith({'ekagra_tasks': torn});
      expect(p.tasks, isEmpty);
      expect(p.loaded, isTrue);
    });
  });
}

import 'dart:io';

import 'package:ekagra/models/task_model.dart';
import 'package:ekagra/providers/task_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rule 13 — soft delete only (quarantine-over-delete)', () {
    test('archiveTask soft-deletes: hidden from active view, preserved in storage', () async {
      SharedPreferences.setMockInitialValues({});
      final p = TaskProvider();
      final t = await p.addTask('Reply to email');

      await p.archiveTask(t.id);

      expect(p.tasks, isEmpty);
      final archived = p.allIncludingDeleted.single;
      expect(archived.isDeleted, isTrue);
      expect(archived.status, TaskStatus.archived);

      // Re-loaded from the same store, the record survives in quarantine
      final p2 = TaskProvider();
      await p2.load();
      expect(p2.allIncludingDeleted.single.isDeleted, isTrue);
    });

    test('no destructive purge primitive exists on the tasks list in TaskProvider', () {
      final src = File('lib/providers/task_provider.dart').readAsStringSync();
      final taskListPurges = RegExp(
        r'(_tasks\s*\.\s*(remove|removeAt|removeWhere|clear|removeLast|removeRange))',
      ).allMatches(src);

      expect(
        taskListPurges,
        isEmpty,
        reason:
            'Rule 13 forbids destructive hard deletes; found destructive purge calls on _tasks.',
      );
    });
  });
}

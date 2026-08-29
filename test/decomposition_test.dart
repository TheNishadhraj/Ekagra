import 'dart:convert';
import 'dart:io';

import 'package:ekagra/models/task_model.dart';
import 'package:ekagra/providers/task_provider.dart';
import 'package:ekagra/services/analytics_service.dart';
import 'package:ekagra/services/task_decomposer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WI-3.1 — decomposition + one-step execution.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TaskDecomposer decomposer;

  setUpAll(() {
    final json = File('assets/templates/task_breakdown_templates.json')
        .readAsStringSync();
    decomposer = TaskDecomposer.fromJson(json);
  });

  group('template data integrity', () {
    test('the asset is valid JSON with all three spiciness levels', () {
      final raw = jsonDecode(
        File('assets/templates/task_breakdown_templates.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(raw['version'], 1);
      final families = (raw['families'] as List).cast<Map<String, dynamic>>();
      expect(families.length, greaterThanOrEqualTo(30),
          reason: 'the work order asks for ~30 families');
      for (final f in families) {
        expect((f['steps'] as Map).keys, containsAll(['mild', 'medium', 'spicy']));
      }
    });

    test('every family is within spiciness bounds (3-5 / 6-10 / 11-20)', () {
      final raw = jsonDecode(
        File('assets/templates/task_breakdown_templates.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final offenders = <String>[];
      void check(String id, String sp, List<dynamic> steps) {
        final bounds = Spiciness.values.byName(sp).bounds;
        if (steps.length < bounds.$1 || steps.length > bounds.$2) {
          offenders.add('$id/$sp=${steps.length}');
        }
      }

      for (final f in (raw['families'] as List).cast<Map<String, dynamic>>()) {
        for (final sp in ['mild', 'medium', 'spicy']) {
          check(f['id'] as String, sp, (f['steps'] as Map)[sp] as List);
        }
      }
      expect(offenders, isEmpty, reason: 'template data drifted out of spec');
    });
  });

  group('classifier', () {
    test('recognizes the families it ships', () {
      expect(decomposer.familyIdFor('clean the kitchen'), 'kitchen');
      expect(decomposer.familyIdFor('wash the dishes'), 'kitchen');
      expect(decomposer.familyIdFor('reply to emails'), 'email');
      expect(decomposer.familyIdFor('do laundry'), 'laundry');
      expect(decomposer.familyIdFor('go for a run'), 'exercise');
      expect(decomposer.familyIdFor('write the report'), 'write');
      expect(decomposer.familyIdFor('fix the login bug'), 'code');
      expect(decomposer.familyIdFor('pay the electricity bill'), 'bills');
    });

    test('unknown tasks fall back to the 2-minute-rule scaffold', () {
      final steps = decomposer.breakdown('re-felt the pool table', Spiciness.mild);
      expect(steps.length, inInclusiveRange(3, 5));
      expect(steps.first.title, 'Open what you need');
      expect(
        steps.any((s) => s.title.contains('2 minutes')),
        isTrue,
      );
    });
  });

  group('acceptance: "clean the kitchen" at max spiciness', () {
    test('>= 10 ordered micro-steps, each a one-tap unit', () {
      final steps = decomposer.breakdown('clean the kitchen', Spiciness.spicy);
      expect(steps.length, greaterThanOrEqualTo(10));
      expect(steps.length, inInclusiveRange(11, 20));
      // Ordered: surfaces before floor is the classic kitchen sanity order.
      final titles = steps.map((s) => s.title).toList();
      expect(titles.indexOf('Wipe the left counter'),
          lessThan(titles.indexOf('Sweep the floor')));
      // Nothing pre-resolved.
      expect(steps.every((s) => !s.resolved), isTrue);
    });
  });

  group('one-step state machine', () {
    test('done and skip both advance; finished when all resolved', () {
      var steps = decomposer.breakdown('reply to emails', Spiciness.mild);
      var plan = DecompositionPlan(steps: steps);

      final first = plan.currentStep!;
      steps[0] = first.copyWith(done: true);
      plan = DecompositionPlan(steps: steps);
      expect(plan.currentStep, isNot(first.title),
          reason: 'current step advanced');
      expect(plan.resolvedCount, 1);

      final second = plan.currentStep!;
      steps[plan.currentIndex] = second.copyWith(skipped: true);
      plan = DecompositionPlan(steps: steps);
      expect(plan.resolvedCount, 2);
      expect(plan.isFinished, isFalse);

      steps[plan.currentIndex] = plan.currentStep!.copyWith(done: true);
      plan = DecompositionPlan(steps: steps);
      expect(plan.isFinished, isTrue);
      expect(plan.currentStep, isNull);
    });
  });

  group('persistence (ADR-007 additive schema)', () {
    test('old payloads (no decomposition fields) still decode', () {
      final legacy = {
        'id': 't1',
        'title': 'Old task from before decomposition',
        'createdAt': '2026-08-01T10:00:00.000',
        'updatedAt': '2026-08-01T10:00:00.000',
      };
      final task = TaskModel.fromJson(legacy);
      expect(task.stepStates, isEmpty);
      expect(task.spiciness, isNull);
      expect(task.subtasks, isEmpty);
    });

    test('step progress round-trips', () {
      final task = TaskModel.create(title: 'clean the kitchen').copyWith(
        subtasks: ['Clear one counter', 'Wash or load the dishes'],
        stepStates: ['done'],
        spiciness: 'spicy',
      );
      final back = TaskModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(jsonEncode(task.toJson())) as Map),
      );
      expect(back.stepStates, ['done']);
      expect(back.spiciness, 'spicy');
      expect(back.subtasks.length, 2);
    });
  });

  group('reward idempotency', () {
    test('completing a task twice fires exactly one completion event',
        () async {
      SharedPreferences.setMockInitialValues({});
      await AnalyticsService.instance.resetForTest();
      final tasks = TaskProvider();
      await tasks.load();
      final spy = InMemoryAnalyticsSink();
      AnalyticsService.instance.addSink(spy);

      final task = await tasks.addTask('Once is enough');
      await tasks.completeTask(task.id);
      await tasks.completeTask(task.id); // double-tap / double-path

      expect(spy.count(Ev.taskCompleted), 1,
          reason: 'exactly one completion reward, ever');
    });
  });
}

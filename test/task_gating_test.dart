import 'package:ekagra/providers/task_provider.dart';
import 'package:ekagra/services/analytics_service.dart';
import 'package:ekagra/services/experiment_service.dart';
import 'package:ekagra/services/growth_service.dart';
import 'package:ekagra/services/monetization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TaskProvider tasks;
  late MonetizationService money;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AnalyticsService.instance.resetForTest();
    await GrowthService.instance.resetForTest();
    money = MonetizationService.instance;
    await money.resetForTest();
    // Pin the limit experiment so the assertions below are deterministic.
    ExperimentService.instance.seedInstallId('gating-test');
    await ExperimentService.instance
        .setOverride(Experiments.freeTaskLimit.key, 'limit_10');
    tasks = TaskProvider();
    await tasks.load();
  });

  tearDown(() async {
    await ExperimentService.instance.clearOverrides();
  });

  group('Free tier enforcement', () {
    test('the limit is actually enforced, not merely declared', () async {
      for (var i = 0; i < 10; i++) {
        await tasks.addTask('task $i');
      }
      expect(tasks.activeIncomplete.length, 10);
      expect(tasks.atFreeTaskLimit, isTrue);
      expect(tasks.remainingFreeSlots, 0);
    });

    test('a bulk dump is truncated to the ceiling rather than rejected',
        () async {
      final saved = await tasks.addTasks(
        List.generate(25, (i) => 'dumped $i'),
      );

      // Capture is sacred: we save what we can rather than refusing the lot.
      expect(saved, 10);
      expect(tasks.activeIncomplete.length, 10);
    });

    test('Pro removes the ceiling entirely', () async {
      await money.startTrial(trigger: PaywallTrigger.taskLimit);

      final saved = await tasks.addTasks(
        List.generate(40, (i) => 'pro task $i'),
      );

      expect(saved, 40);
      expect(tasks.atFreeTaskLimit, isFalse);
    });

    test('completing tasks frees up slots again', () async {
      for (var i = 0; i < 10; i++) {
        await tasks.addTask('task $i');
      }
      expect(tasks.atFreeTaskLimit, isTrue);

      await tasks.completeTask(tasks.activeIncomplete.first.id);

      expect(tasks.atFreeTaskLimit, isFalse);
      expect(tasks.remainingFreeSlots, 1);
    });

    test('the limit experiment actually changes the ceiling', () async {
      await ExperimentService.instance
          .setOverride(Experiments.freeTaskLimit.key, 'limit_20');
      expect(money.freeTaskLimit, 20);

      final saved =
          await tasks.addTasks(List.generate(30, (i) => 'task $i'));
      expect(saved, 20);
    });
  });

  group('Core loop instrumentation', () {
    test('completing a task emits the North Star event', () async {
      final sink = InMemoryAnalyticsSink();
      AnalyticsService.instance.addSink(sink);

      final task = await tasks.addTask('write the thing');
      await tasks.completeTask(task.id);

      expect(sink.sawEvent(Ev.taskCreated), isTrue);
      expect(sink.sawEvent(Ev.taskCompleted), isTrue);
      expect(GrowthService.instance.northStarValue, 1);
    });

    test('capturing a task advances the activation ladder', () async {
      await tasks.addTask('first ever task');
      expect(
        GrowthService.instance.hasCompleted(ActivationStep.firstTaskCaptured),
        isTrue,
      );
    });
  });
}

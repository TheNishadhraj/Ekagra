import 'dart:convert';

import 'package:ekagra/providers/energy_provider.dart';
import 'package:ekagra/providers/mood_provider.dart';
import 'package:ekagra/providers/reward_provider.dart';
import 'package:ekagra/providers/settings_provider.dart';
import 'package:ekagra/providers/task_provider.dart';
import 'package:ekagra/services/analytics_service.dart';
import 'package:ekagra/utils/safe_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Startup resilience.
///
/// Every provider's `load()` is awaited in `main()` before `runApp()`. An
/// exception in any of them means the app never renders and the only user
/// remedy is uninstalling — which destroys all their data.
///
/// These tests corrupt storage in the ways it actually gets corrupted in the
/// field (partial writes from force-quits, schema drift, truncation) and
/// assert the app still boots.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AnalyticsService.instance.resetForTest();
  });

  group('Corrupt storage never blocks startup', () {
    test('truncated task JSON does not throw', () async {
      SharedPreferences.setMockInitialValues({
        'ekagra_tasks': '[{"id":"a","title":"half a tas',
      });

      final tasks = TaskProvider();
      await expectLater(tasks.load(), completes);
      expect(tasks.tasks, isEmpty);
    });

    test('a wrong-type payload does not throw', () async {
      SharedPreferences.setMockInitialValues({
        'ekagra_tasks': '{"not":"a list"}',
      });

      final tasks = TaskProvider();
      await expectLater(tasks.load(), completes);
      expect(tasks.tasks, isEmpty);
    });

    test('outright garbage does not throw', () async {
      SharedPreferences.setMockInitialValues({
        'ekagra_tasks': 'not json at all \u0000\u0001',
        'ekagra_energy_logs': '<<<>>>',
        'ekagra_mood_logs': '[[[',
        'ekagra_rewards': 'null',
        'ekagra_user': '{{{',
      });

      await expectLater(TaskProvider().load(), completes);
      await expectLater(EnergyProvider().load(), completes);
      await expectLater(MoodProvider().load(), completes);
      await expectLater(RewardProvider().load(), completes);
      await expectLater(SettingsProvider().load(), completes);
    });

    test('one bad record does not discard the good ones', () async {
      // The important case. Losing 1 of 3 tasks is survivable; losing all 3
      // because of the 1 is the bug that makes people uninstall.
      final good1 = {
        'id': 'g1',
        'title': 'real task one',
        'status': 'notStarted',
        'scheduleType': 'today',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final good2 = {
        'id': 'g2',
        'title': 'real task two',
        'status': 'notStarted',
        'scheduleType': 'today',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      // Missing required fields / unparseable date.
      final bad = {'id': 'b1', 'createdAt': 'definitely-not-a-date'};

      SharedPreferences.setMockInitialValues({
        'ekagra_tasks': jsonEncode([good1, bad, good2]),
      });

      final tasks = TaskProvider();
      await tasks.load();

      expect(
        tasks.tasks.length,
        2,
        reason: 'Both well-formed tasks must survive one corrupt sibling.',
      );
      expect(tasks.tasks.map((t) => t.title),
          containsAll(['real task one', 'real task two']));
    });

    test('a corrupt user record keeps the onboarding flag', () async {
      // Otherwise a returning user is thrown back into the welcome flow,
      // which reads as "the app forgot me" — the worst possible message for
      // an audience already primed to expect tools to let them down.
      SharedPreferences.setMockInitialValues({
        'ekagra_user': '{"id":',
        'ekagra_onboarding_complete': true,
      });

      final settings = SettingsProvider();
      await settings.load();

      expect(settings.onboardingComplete, isTrue);
    });

    test('empty and missing values are handled without quarantine',
        () async {
      SharedPreferences.setMockInitialValues({'ekagra_tasks': ''});
      final tasks = TaskProvider();
      await tasks.load();

      expect(tasks.tasks, isEmpty);
      expect(await SafeStore.hasQuarantine('ekagra_tasks'), isFalse);
    });
  });

  group('Corrupt data is preserved, not silently destroyed', () {
    test('an unreadable payload is quarantined for recovery', () async {
      const payload = '[{"id":"important-task-the-user-cared-about"';
      SharedPreferences.setMockInitialValues({'ekagra_tasks': payload});

      final tasks = TaskProvider();
      await tasks.load();
      // Quarantine is fire-and-forget and chains getInstance() -> setString,
      // so give the event loop a couple of turns to settle.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(await SafeStore.hasQuarantine('ekagra_tasks'), isTrue);
      expect(await SafeStore.readQuarantine('ekagra_tasks'), payload);
    });

    test('failures are reported rather than swallowed', () async {
      final sink = InMemoryAnalyticsSink();
      AnalyticsService.instance.addSink(sink);

      SharedPreferences.setMockInitialValues({'ekagra_tasks': 'garbage'});
      await TaskProvider().load();

      final errors = sink.named(Ev.errorOccurred);
      expect(errors, isNotEmpty);
      expect(errors.first.props['context'], 'ekagra_tasks');
    });
  });
}

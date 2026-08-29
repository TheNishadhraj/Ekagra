import 'package:ekagra/models/dopamine_menu_model.dart';
import 'package:ekagra/services/analytics_service.dart';
import 'package:ekagra/services/growth_service.dart';
import 'package:ekagra/services/menu_refresh_service.dart';
import 'package:ekagra/services/experiment_service.dart';
import 'package:ekagra/utils/rsd_safe_copy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WI-5.3 — anti-novelty-decay retention program.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('active-days milestones', () {
    test('milestone days are 7/30/100 — totals, never streaks', () {
      expect(GrowthService.milestoneDays, [7, 30, 100]);
    });

    test('legacy growth JSON (no celebratedMilestones) decodes', () async {
      SharedPreferences.setMockInitialValues({
        'ekagra_growth_state':
            '{"totalActiveDays": 12, "consecutiveActiveDays": 3}',
      });
      final growth = GrowthService.instance;
      await growth.load();
      expect(growth.totalActiveDays, 12);
      expect(growth.pendingMilestone, isNull);
      await growth.resetForTest();
    });

    test('crossing 7 arms the celebration exactly once', () async {
      SharedPreferences.setMockInitialValues({
        // Pre-seed so the loader sees day 6, then record the 7th open.
        'ekagra_growth_state':
            '{"totalActiveDays": 6, "consecutiveActiveDays": 6, '
            '"lastActiveDay": "2026-08-25T09:00:00.000"}',
      });
      final growth = GrowthService.instance;
      await growth.load();
      await growth.recordAppOpen(); // day 7
      expect(growth.pendingMilestone, 7);

      await growth.clearPendingMilestone();
      expect(growth.pendingMilestone, isNull);

      await growth.recordAppOpen(); // same day — no re-arm
      expect(growth.pendingMilestone, isNull);
      await growth.resetForTest();
    });

    test('a gap does not cost milestone progress', () async {
      SharedPreferences.setMockInitialValues({
        'ekagra_growth_state':
            '{"totalActiveDays": 6, "consecutiveActiveDays": 6, '
            '"lastActiveDay": "2026-07-01T09:00:00.000", '
            '"celebratedMilestones": [7]}',
      });
      final growth = GrowthService.instance;
      await growth.load();
      await growth.recordAppOpen(); // gap then return: total -> 7, already celebrated
      expect(growth.pendingMilestone, isNull,
          reason: 'milestone 7 celebrated once, ever');
      expect(growth.totalActiveDays, 7);
      await growth.resetForTest();
    });

    test('celebration copy is RSD-safe', () {
      const copies = [
        '7 days you showed up for yourself.',
        '30 days you showed up for yourself.',
        '100 days you showed up for yourself.',
        'Gaps included. They count too.',
        'Celebrate 🎁',
        'Just warm feelings, thanks',
      ];
      for (final c in copies) {
        expect(RsdSafeCopy.isSafe(c), isTrue, reason: '"$c"');
      }
    });
  });

  group('monthly menu refresh', () {
    test('suggestions exclude what is already selected', () {
      final now = DateTime(2026, 8, 26);
      final all = <String>{}
        ..addAll(DopamineMenuDefaults.pool['quick']!
            .map((i) => '${i.emoji} ${i.text}'))
        ..addAll(DopamineMenuDefaults.pool['medium']!
            .map((i) => '${i.emoji} ${i.text}'))
        ..addAll(DopamineMenuDefaults.pool['big']!
            .map((i) => '${i.emoji} ${i.text}'));
      final suggestions = MenuRefreshService.suggestionsFor(all, 2026, 8);
      expect(suggestions, isEmpty,
          reason: 'a user with everything gets no suggestions');

      final none = MenuRefreshService.suggestionsFor({}, now.year, now.month);
      expect(none.length, 3);
      expect(none.toSet().length, 3, reason: 'no duplicates');
    });

    test('rotation is deterministic and changes across months', () {
      final a1 = MenuRefreshService.suggestionsFor({}, 2026, 8);
      final a2 = MenuRefreshService.suggestionsFor({}, 2026, 8);
      expect(a1.map((e) => e.id).toList(), a2.map((e) => e.id).toList(),
          reason: 'same month, same suggestions');

      final b = MenuRefreshService.suggestionsFor({}, 2026, 9);
      expect(a1.map((e) => e.id).toSet(), isNot(equals(b.map((e) => e.id).toSet())),
          reason: 'next month rotates the picks');
    });

    test('every suggestion text is RSD-safe', () {
      final pool = <DopamineItem>[
        ...DopamineMenuDefaults.pool['quick']!,
        ...DopamineMenuDefaults.pool['medium']!,
        ...DopamineMenuDefaults.pool['big']!,
      ];
      for (final item in pool) {
        expect(RsdSafeCopy.isSafe(item.text), isTrue,
            reason: '"${item.text}"');
      }
    });
  });

  group('experiment registration (WI-5.3)', () {
    test('new experiments are registered with valid shapes', () {
      for (final e in [Experiments.milestoneTone, Experiments.menuRefreshCount]) {
        expect(e.variants.length, 2);
        expect(e.variants.toSet().length, 2);
        expect(e.hypothesis, isNotEmpty);
        expect(e.successMetric, isNotEmpty);
      }
    });

    test('enrollment is deterministic per install', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ExperimentService.instance;
      await service.load();
      final first = service.variantOf(Experiments.milestoneTone);
      final second = service.variantOf(Experiments.milestoneTone);
      expect(first, second);
      expect(Experiments.milestoneTone.variants.contains(first), isTrue);
    });
  });
}

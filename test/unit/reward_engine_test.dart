import 'dart:math';

import 'package:ekagra/models/dopamine_menu_model.dart';
import 'package:ekagra/services/reward_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DopamineItem item(String id, String text, RewardTier tier) => DopamineItem(
      id: id,
      emoji: '🎁',
      text: text,
      durationMinutes: 5,
      tier: tier,
      createdAt: DateTime(2026, 1, 1),
    );

DopamineMenu buildMenu({
  List<DopamineItem> quick = const [],
  List<DopamineItem> medium = const [],
  List<DopamineItem> big = const [],
}) =>
    DopamineMenu(quick: quick, medium: medium, big: big);

void main() {
  final full = buildMenu(
    quick: [
      item('q1', 'Quick 1', RewardTier.quick),
      item('q2', 'Quick 2', RewardTier.quick)
    ],
    medium: [
      item('m1', 'Medium 1', RewardTier.medium),
      item('m2', 'Medium 2', RewardTier.medium)
    ],
    big: [item('b1', 'Big 1', RewardTier.big)],
  );

  group('roll tier distribution (~70/25/5)', () {
    test('rolls approximate the configured ratio deterministically', () {
      final engine = RewardEngine(random: Random(42));
      var quick = 0;
      var medium = 0;
      var big = 0;

      for (var i = 0; i < 2000; i++) {
        final tier = engine.roll(menu: full).item.tier;
        if (tier == RewardTier.quick) {
          quick++;
        } else if (tier == RewardTier.medium) {
          medium++;
        } else {
          big++;
        }
      }

      expect(quick, inInclusiveRange(1200, 1600)); // ~70%
      expect(medium, inInclusiveRange(300, 700)); // ~25%
      expect(big, inInclusiveRange(20, 250)); // ~5%
    });
  });

  group('tier fallbacks', () {
    test('falls back to the full menu when a rolled tier is empty', () {
      final onlyMedium = buildMenu(
        medium: [item('m1', 'Medium 1', RewardTier.medium)],
      );
      final engine = RewardEngine(random: Random(1));
      final ids = <String>{};

      for (var i = 0; i < 500; i++) {
        ids.add(engine.roll(menu: onlyMedium).item.id);
      }

      // Quick and Big tiers are empty, so every roll must fall back to menu.all ('m1').
      expect(ids, {'m1'});
    });

    test('falls back to built-in defaults when the menu is completely empty', () {
      final engine = RewardEngine(random: Random(3));
      final defaultIds = DopamineMenu.defaults.all.map((e) => e.id).toSet();

      for (var i = 0; i < 200; i++) {
        final reward = engine.roll(menu: DopamineMenu());
        expect(defaultIds, contains(reward.item.id));
      }
    });
  });

  group('rare rewards and metadata', () {
    test('rare reward carries a message; non-rare never does', () {
      final engine = RewardEngine(random: Random(7));
      var rareCount = 0;

      for (var i = 0; i < 5000; i++) {
        final reward = engine.roll(menu: full);
        if (reward.isRare) {
          rareCount++;
          expect(reward.rareMessage, isNotNull);
          expect(reward.rareMessage!.isNotEmpty, isTrue);
        } else {
          expect(reward.rareMessage, isNull);
        }
      }

      expect(rareCount, greaterThan(0));
    });

    test('carries related task identity through', () {
      final engine = RewardEngine(random: Random(11));
      final reward = engine.roll(
        menu: full,
        relatedTaskId: 't-1',
        relatedTaskTitle: 'Reply to email',
      );
      expect(reward.relatedTaskId, 't-1');
      expect(reward.relatedTaskTitle, 'Reply to email');
    });
  });
}

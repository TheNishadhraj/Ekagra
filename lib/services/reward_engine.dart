import 'dart:math';

import '../models/dopamine_menu_model.dart';
import '../models/dopamine_reward_model.dart';

/// Spec I1 — Variable ratio reinforcement engine.
class RewardEngine {
  RewardEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Small-tier micro-tick for a completed decomposition step (WI-3.1).
  ///
  /// Deliberately excluded from the variable-ratio roll: steps fire often,
  /// and a surprise big reward every few steps would devalue the tasks'
  /// rolls. Steps earn a quick treat; finished TASKS earn the real spin.
  DopamineReward rollQuick({
    required DopamineMenu menu,
    String? relatedTaskId,
    String? relatedTaskTitle,
  }) {
    var pool = menu.forTier(RewardTier.quick);
    if (pool.isEmpty) pool = DopamineMenu.defaults.quick;
    final item = pool[_random.nextInt(pool.length)];
    return DopamineReward.fromItem(
      item,
      relatedTaskId: relatedTaskId,
      relatedTaskTitle: relatedTaskTitle,
    );
  }

  /// Milestone celebration roll (WI-5.3): the reward is the point, so the
  /// rare overlay is forced on — the anti-streak celebration.
  DopamineReward rollRare({
    required DopamineMenu menu,
    String? relatedTaskTitle,
  }) {
    var pool = menu.forTier(RewardTier.big);
    if (pool.isEmpty) pool = DopamineMenu.defaults.big;
    final item = pool[_random.nextInt(pool.length)];
    return DopamineReward.fromItem(
      item,
      isRare: true,
      rareMessage:
          _rareMessages[_random.nextInt(_rareMessages.length)],
      relatedTaskTitle: relatedTaskTitle,
    );
  }

  /// ~70% quick, ~25% medium, ~5% big; ~5% rare overlay.
  DopamineReward roll({
    required DopamineMenu menu,
    String? relatedTaskId,
    String? relatedTaskTitle,
  }) {
    final roll = _random.nextDouble();
    RewardTier tier;
    if (roll < 0.70) {
      tier = RewardTier.quick;
    } else if (roll < 0.95) {
      tier = RewardTier.medium;
    } else {
      tier = RewardTier.big;
    }

    var pool = menu.forTier(tier);
    if (pool.isEmpty) pool = menu.all;
    if (pool.isEmpty) pool = DopamineMenu.defaults.all;

    final item = pool[_random.nextInt(pool.length)];
    final isRare = _random.nextDouble() < 0.05;

    return DopamineReward.fromItem(
      item,
      isRare: isRare,
      rareMessage: isRare
          ? _rareMessages[_random.nextInt(_rareMessages.length)]
          : null,
      relatedTaskId: relatedTaskId,
      relatedTaskTitle: relatedTaskTitle,
    );
  }

  static const _rareMessages = [
    '✨ Rare reward unlocked — you earned something special.',
    '🌟 Jackpot energy. Enjoy this one extra hard.',
    '🎁 Surprise bonus! Your future self thanks you.',
  ];
}

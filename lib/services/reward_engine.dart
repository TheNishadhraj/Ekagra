import 'dart:math';

import '../models/dopamine_menu_model.dart';
import '../models/dopamine_reward_model.dart';

/// Spec I1 — Variable ratio reinforcement engine.
class RewardEngine {
  RewardEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

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

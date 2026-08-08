import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ekagra/providers/reward_provider.dart';
import 'package:ekagra/models/dopamine_reward_model.dart';
import 'package:ekagra/models/dopamine_menu_model.dart';

void main() {
  test('claimReward persists reward history', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = RewardProvider();

    final item = DopamineMenu.defaults.quick.first;
    final reward = DopamineReward.fromItem(item);

    await provider.claimReward(reward);

    expect(provider.latest?.id, equals(reward.id));
    expect(provider.history.isNotEmpty, isTrue);
    expect(provider.history.first.id, equals(reward.id));

    // Reload from disk to confirm persistence
    final provider2 = RewardProvider();
    await provider2.load();
    expect(provider2.history.first.id, equals(reward.id));
  });
}

import 'package:ekagra/models/dopamine_reward_model.dart';
import 'package:ekagra/models/dopamine_menu_model.dart';
import 'package:ekagra/providers/reward_provider.dart';
import 'package:ekagra/screens/rewards/reward_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Reward history shows persisted reward', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = RewardProvider();

    final item = DopamineMenu.defaults.quick.first;
    final reward = DopamineReward.fromItem(item);
    await provider.claimReward(reward);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: RewardHistoryScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(reward.title), findsOneWidget);
    expect(find.text(reward.emoji), findsOneWidget);
  });
}

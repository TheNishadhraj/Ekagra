import 'package:ekagra/app.dart';
import 'package:ekagra/providers/energy_provider.dart';
import 'package:ekagra/providers/focus_provider.dart';
import 'package:ekagra/providers/mood_provider.dart';
import 'package:ekagra/providers/reward_provider.dart';
import 'package:ekagra/providers/settings_provider.dart';
import 'package:ekagra/providers/task_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Ekagra welcome screen renders', (tester) async {
    final settings = SettingsProvider();
    final tasks = TaskProvider();
    final energy = EnergyProvider();
    final mood = MoodProvider();
    final focus = FocusProvider();
    final rewards = RewardProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: tasks),
          ChangeNotifierProvider.value(value: energy),
          ChangeNotifierProvider.value(value: mood),
          ChangeNotifierProvider.value(value: focus),
          ChangeNotifierProvider.value(value: rewards),
        ],
        child: const EkagraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hey there 👋'), findsOneWidget);
    expect(find.text("Let's go →"), findsOneWidget);
  });
}

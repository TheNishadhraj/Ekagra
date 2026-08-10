import 'package:ekagra/app.dart';
import 'package:ekagra/providers/energy_provider.dart';
import 'package:ekagra/providers/focus_provider.dart';
import 'package:ekagra/providers/mood_provider.dart';
import 'package:ekagra/providers/reward_provider.dart';
import 'package:ekagra/providers/settings_provider.dart';
import 'package:ekagra/providers/task_provider.dart';
import 'package:ekagra/services/analytics_service.dart';
import 'package:ekagra/services/experiment_service.dart';
import 'package:ekagra/services/growth_service.dart';
import 'package:ekagra/services/monetization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AnalyticsService.instance.resetForTest();
    await MonetizationService.instance.resetForTest();
    await GrowthService.instance.resetForTest();
    ExperimentService.instance.seedInstallId('widget-test-install');
  });

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
          ChangeNotifierProvider.value(value: MonetizationService.instance),
          ChangeNotifierProvider.value(value: GrowthService.instance),
          ChangeNotifierProvider.value(value: ExperimentService.instance),
        ],
        child: const EkagraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hey there 👋'), findsOneWidget);
    expect(find.text("Let's go →"), findsOneWidget);
  });

  testWidgets('opening the app fires onboarding_started', (tester) async {
    final sink = InMemoryAnalyticsSink();
    AnalyticsService.instance.addSink(sink);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: SettingsProvider()),
          ChangeNotifierProvider.value(value: TaskProvider()),
          ChangeNotifierProvider.value(value: EnergyProvider()),
          ChangeNotifierProvider.value(value: MoodProvider()),
          ChangeNotifierProvider.value(value: FocusProvider()),
          ChangeNotifierProvider.value(value: RewardProvider()),
          ChangeNotifierProvider.value(value: MonetizationService.instance),
          ChangeNotifierProvider.value(value: GrowthService.instance),
          ChangeNotifierProvider.value(value: ExperimentService.instance),
        ],
        child: const EkagraApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Instrumentation is part of the product, so it is part of the tests.
    expect(sink.sawEvent(Ev.onboardingStarted), isTrue);
  });
}

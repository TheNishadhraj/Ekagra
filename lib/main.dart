import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/energy_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/reward_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';
import 'services/analytics_service.dart';
import 'services/experiment_service.dart';
import 'services/growth_service.dart';
import 'services/monetization_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final settings = SettingsProvider();
  final tasks = TaskProvider();
  final energy = EnergyProvider();
  final mood = MoodProvider();
  final focus = FocusProvider();
  final rewards = RewardProvider();

  // Growth stack. Analytics and experiments load first so that every event
  // fired during startup already carries the correct variant assignment —
  // otherwise the first session of every install is unattributable.
  final analytics = AnalyticsService.instance;
  final experiments = ExperimentService.instance;
  final money = MonetizationService.instance;
  final growth = GrowthService.instance;

  await analytics.load();
  await experiments.load();
  analytics.addSink(DebugAnalyticsSink());
  analytics.startSession(
    DateTime.now().millisecondsSinceEpoch.toRadixString(36),
  );

  await Future.wait([
    settings.load(),
    tasks.load(),
    energy.load(),
    mood.load(),
    rewards.load(),
    money.load(),
    growth.load(),
  ]);

  // Reconcile the legacy `user.isPro` flag with the real entitlement engine.
  // Existing installs that were granted Pro by the old no-op paywall keep it;
  // everyone else is governed by MonetizationService from here on.
  if (settings.user.isPro && !money.isPro) {
    await money.purchase(
      plan: SubscriptionPlan.annual,
      trigger: PaywallTrigger.settings,
    );
  }

  await growth.recordAppOpen();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: tasks),
        ChangeNotifierProvider.value(value: energy),
        ChangeNotifierProvider.value(value: mood),
        ChangeNotifierProvider.value(value: focus),
        ChangeNotifierProvider.value(value: rewards),
        ChangeNotifierProvider.value(value: money),
        ChangeNotifierProvider.value(value: growth),
        ChangeNotifierProvider.value(value: experiments),
      ],
      child: const EkagraApp(),
    ),
  );
}

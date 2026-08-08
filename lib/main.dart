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

  await Future.wait([
    settings.load(),
    tasks.load(),
    energy.load(),
    mood.load(),
    rewards.load(),
  ]);

  runApp(
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
}

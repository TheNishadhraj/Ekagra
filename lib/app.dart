import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';

class EkagraApp extends StatelessWidget {
  const EkagraApp({super.key});

  /// Global navigator key so the nudge engine (and nothing else) can route
  /// a notification tap to a screen without holding a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final tasks = context.watch<TaskProvider>();
    final String initial;
    if (!settings.onboardingComplete) {
      initial = AppRoutes.welcome;
    } else if (settings.shouldShowWelcomeBack(
      hasContent: tasks.tasks.isNotEmpty,
    )) {
      // WI-1.3: one gentle screen per >=3-day gap — "Nothing was lost",
      // which is only ever claimed because SafeStore makes it true.
      initial = AppRoutes.welcomeBack;
    } else {
      initial = AppRoutes.main;
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Ekagra',
      debugShowCheckedModeBanner: false,
      theme: EkagraTheme.light,
      darkTheme: EkagraTheme.dark,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: initial,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}


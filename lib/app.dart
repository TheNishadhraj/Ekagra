import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/settings_provider.dart';

class EkagraApp extends StatelessWidget {
  const EkagraApp({super.key});

  /// Global navigator key so the nudge engine (and nothing else) can route
  /// a notification tap to a screen without holding a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final initial = settings.onboardingComplete
        ? AppRoutes.main
        : AppRoutes.welcome;

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


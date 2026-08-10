import 'package:flutter/material.dart';

import '../screens/body_double/body_double_screen.dart';
import '../screens/brain_dump/brain_dump_screen.dart';
import '../screens/focus/focus_complete_screen.dart';
import '../screens/focus/focus_timer_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/adhd_type_screen.dart';
import '../screens/onboarding/dopamine_menu_setup_screen.dart';
import '../screens/onboarding/notification_permission_screen.dart';
import '../screens/onboarding/paywall_screen.dart';
import '../screens/rewards/reward_reveal_screen.dart';
import '../screens/settings/growth_dashboard_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shared/main_shell.dart';
import '../screens/someday/someday_list_screen.dart';
import '../screens/timeline/day_view_screen.dart';
import '../models/task_model.dart';
import '../models/dopamine_reward_model.dart';

class AppRoutes {
  AppRoutes._();

  static const welcome = '/welcome';
  static const adhdType = '/onboarding/adhd-type';
  static const dopamineSetup = '/onboarding/dopamine';
  static const notificationPermission = '/onboarding/notifications';
  static const paywall = '/onboarding/paywall';
  static const main = '/main';
  static const home = '/home';
  static const brainDump = '/brain-dump';
  static const focus = '/focus';
  static const focusComplete = '/focus-complete';
  static const rewardReveal = '/reward-reveal';
  static const timeline = '/timeline';
  static const bodyDouble = '/body-double';
  static const someday = '/someday';
  static const settings = '/settings';
  static const growthDashboard = '/settings/growth';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case welcome:
        return _fade(const WelcomeScreen(), routeSettings);
      case adhdType:
        return _slide(const AdhdTypeScreen(), routeSettings);
      case dopamineSetup:
        return _slide(const DopamineMenuSetupScreen(), routeSettings);
      case notificationPermission:
        return _slide(const NotificationPermissionScreen(), routeSettings);
      case paywall:
        return _slide(const PaywallScreen(), routeSettings);
      case main:
        return _fade(const MainShell(), routeSettings);
      case brainDump:
        return _slideUp(const BrainDumpScreen(), routeSettings);
      case focus:
        final task = routeSettings.arguments as TaskModel?;
        return _slide(FocusTimerScreen(task: task), routeSettings);
      case focusComplete:
        final args = routeSettings.arguments as FocusCompleteArgs?;
        return _fade(
          FocusCompleteScreen(
            minutes: args?.minutes ?? 0,
            taskTitle: args?.taskTitle,
          ),
          routeSettings,
        );
      case rewardReveal:
        final reward = routeSettings.arguments as DopamineReward?;
        return _fade(RewardRevealScreen(reward: reward), routeSettings);
      case timeline:
        return _slide(const DayViewScreen(), routeSettings);
      case bodyDouble:
        return _slide(const BodyDoubleScreen(), routeSettings);
      case someday:
        return _slide(const SomedayListScreen(), routeSettings);
      case settings:
        return _slide(const SettingsScreen(), routeSettings);
      case growthDashboard:
        return _slide(const GrowthDashboardScreen(), routeSettings);
      case home:
      default:
        return _fade(const HomeScreen(), routeSettings);
    }
  }

  static PageRouteBuilder<dynamic> _fade(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder<dynamic> _slide(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  static PageRouteBuilder<dynamic> _slideUp(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

class FocusCompleteArgs {
  final int minutes;
  final String? taskTitle;

  const FocusCompleteArgs({required this.minutes, this.taskTitle});
}

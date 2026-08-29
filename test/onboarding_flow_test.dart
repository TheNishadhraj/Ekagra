import 'dart:convert';
import 'dart:io';

import 'package:ekagra/app.dart';
import 'package:ekagra/config/routes.dart';
import 'package:ekagra/providers/energy_provider.dart';
import 'package:ekagra/providers/focus_provider.dart';
import 'package:ekagra/providers/mood_provider.dart';
import 'package:ekagra/providers/reward_provider.dart';
import 'package:ekagra/providers/settings_provider.dart';
import 'package:ekagra/providers/task_provider.dart';
import 'package:ekagra/screens/onboarding/dopamine_menu_setup_screen.dart';
import 'package:ekagra/screens/onboarding/notification_permission_screen.dart';
import 'package:ekagra/screens/onboarding/welcome_back_screen.dart';
import 'package:ekagra/services/monetization_service.dart';
import 'package:ekagra/services/nudge_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WI-1.3 — onboarding reflow acceptance:
/// ≤3 effective steps, dopamine menu skippable with defaults, notifications
/// step real, no paywall reachable during onboarding, welcome-back shown
/// once per ≥3-day gap.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsProvider settings;
  late TaskProvider tasks;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsProvider();
    await settings.load();
    tasks = TaskProvider();
    await tasks.load();
    await MonetizationService.instance.resetForTest();
  });

  Widget wrap(Widget child, {NavigatorObserver? observer}) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: tasks),
          ChangeNotifierProvider(create: (_) => RewardProvider()..load()),
          ChangeNotifierProvider(create: (_) => EnergyProvider()..load()),
          ChangeNotifierProvider(create: (_) => MoodProvider()..load()),
          ChangeNotifierProvider(create: (_) => FocusProvider()),
        ],
        child: MaterialApp(
          navigatorKey: EkagraApp.navigatorKey,
          navigatorObservers: [if (observer != null) observer],
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: child,
        ),
      );

  testWidgets('dopamine menu: one tap proceeds without forcing choices',
      (tester) async {
    await tester.pumpWidget(wrap(const DopamineMenuSetupScreen()));
    await tester.pumpAndSettle();

    // The primary path is a single Continue; the picker is opt-in.
    expect(find.text('Continue →'), findsOneWidget);
    expect(find.text('Tune my menu first →'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);

    await tester.tap(find.text('Continue →'));
    await tester.pumpAndSettle();
    // Landed on the notifications step (the final step).
    expect(find.byType(NotificationPermissionScreen), findsOneWidget);
  });

  testWidgets('dopamine menu: tuning is available and saves', (tester) async {
    await tester.pumpWidget(wrap(const DopamineMenuSetupScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tune my menu first →'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsWidgets);
    expect(find.text('Save & Continue →'), findsOneWidget);
  });

  testWidgets('notifications step: skip path completes onboarding, no paywall',
      (tester) async {
    final pushes = <String>[];
    final observer = _RouteLogger(onPush: (name) => pushes.add(name));

    await tester.pumpWidget(
      wrap(const NotificationPermissionScreen(), observer: observer),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not today'));
    await tester.pumpAndSettle();

    expect(settings.onboardingComplete, isTrue);
    expect(settings.notificationsEnabled, isFalse,
        reason: 'skip leaves notifications fully off (Rule 11)');

    // The one thing the reflow must guarantee: no billing surface in the
    // onboarding flow at all.
    expect(pushes.where((p) => p.contains('paywall')), isEmpty);
  });

  test('the onboarding paywall route is gone from the route table', () {
    final source = File('lib/config/routes.dart').readAsStringSync();
    expect(source.contains('/onboarding/paywall'), isFalse,
        reason: 'onboarding must never reach a paywall (WI-1.3.4)');
    expect(source.contains('paywall_screen'), isFalse);
  });

  testWidgets('welcome-back screen acknowledges and returns home',
      (tester) async {
    await tester.pumpWidget(wrap(const WelcomeBackScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Nothing was lost.'), findsOneWidget);

    await tester.tap(find.text('Show me my one thing →'));
    await tester.pumpAndSettle();

    expect(settings.welcomeBackShownAt, isNotNull);
  });

  test('welcome-back gate: once per >=3-day gap, requires content', () async {
    // Not before onboarding completes / without content.
    expect(settings.shouldShowWelcomeBack(hasContent: false), isFalse);

    await tasks.addTask('Something to come back to');
    await settings.completeOnboarding();

    // Fresh activity: no welcome-back.
    await settings.touchLastActiveAt();
    expect(settings.shouldShowWelcomeBack(hasContent: true), isFalse);

    // Simulate a 5-day gap: a stored user last active 5 days ago.
    final stale = SettingsProvider();
    final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ekagra_user',
      jsonEncode(settings.user.copyWith(lastActiveAt: fiveDaysAgo).toJson()),
    );
    await prefs.setBool('ekagra_onboarding_complete', true);
    await stale.load();

    expect(stale.shouldShowWelcomeBack(hasContent: true), isTrue);

    // After showing once for this gap, never again for the same gap.
    await stale.markWelcomeBackShown();
    expect(stale.shouldShowWelcomeBack(hasContent: true), isFalse);
  });

  test('nudges are armed only with consent', () async {
    // Rule 11 invariant: engine disabled until the user opts in.
    expect(settings.notificationsEnabled, isFalse);
    expect(NudgeService.instance.enabled, isFalse);
  });
}

class _RouteLogger extends NavigatorObserver {
  _RouteLogger({required this.onPush});
  final void Function(String name) onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPush(route.settings.name ?? '');
  }
}

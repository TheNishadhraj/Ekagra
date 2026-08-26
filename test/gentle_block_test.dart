import 'package:ekagra/screens/shared/calm_pause_screen.dart';
import 'package:ekagra/config/feature_flags.dart';
import 'package:ekagra/services/gentle_block_gate.dart';
import 'package:ekagra/utils/rsd_safe_copy.dart';
import 'package:flutter_test/flutter_test.dart';

/// WI-5.1 — the gate is pure logic; the pause screen is inert UI until
/// the native layer lands. Both must be honest today.
void main() {
  const sessionStart = 1000000;
  const sessionEnd = sessionStart + 25 * 60 * 1000;

  test('gate is inert while the feature is unbuilt', () {
    final gate = GentleBlockGate(config: const GentleBlockConfig(), enabled: true)
      ..sessionStarted(sessionEnd);
    expect(
      gate.onAppOpened('com.instagram.android', sessionStart),
      GentleBlockDecision.allow,
      reason: 'flag not live -> never pauses, never pretends to',
    );
  });

  test('blocked app during an active session pauses with a choice', () {
    final gate = GentleBlockGate(
      config: const GentleBlockConfig(),
      enabled: true,
      maturityForTest: FeatureMaturity.live,
    )..sessionStarted(sessionEnd);
    expect(gate.onAppOpened('com.instagram.android', sessionStart),
        GentleBlockDecision.pauseWithChoice);
    expect(gate.onAppOpened('com.some.calendar.app', sessionStart),
        GentleBlockDecision.allow,
        reason: 'unlisted apps are untouched');
    expect(gate.onAppOpened('com.theNishadhraj.ekagra', sessionStart),
        GentleBlockDecision.allow,
        reason: 'never block Ekagra itself');
  });

  test('monk mode converts the choice into a session-length hold', () {
    final gate = GentleBlockGate(
      config: const GentleBlockConfig(monkMode: true),
      enabled: true,
      maturityForTest: FeatureMaturity.live,
    )..sessionStarted(sessionEnd);
    expect(gate.onAppOpened('com.google.android.youtube', sessionStart),
        GentleBlockDecision.hardPause);
  });

  test('session boundaries hold: expired session allows everything', () {
    final gate = GentleBlockGate(
      config: const GentleBlockConfig(),
      enabled: true,
      maturityForTest: FeatureMaturity.live,
    )..sessionStarted(sessionEnd);
    expect(gate.onAppOpened('com.instagram.android', sessionEnd + 1),
        GentleBlockDecision.allow);
    gate.sessionStarted(sessionEnd);
    gate.sessionEnded();
    expect(gate.onAppOpened('com.instagram.android', sessionStart),
        GentleBlockDecision.allow);
  });

  test('fallback app names are friendly', () {
    const config = GentleBlockConfig();
    expect(config.nameOf('com.instagram.android'), isNotEmpty);
    expect(config.nameOf('x.y.ab'), 'that app');
  });

  test('pause screen copy is RSD-safe', () {
    const copies = [
      'You reached for Instagram.',
      'Return to "Clean the kitchen", or take a 10-min break — your call.',
      'Monk mode is on. Your session ends at the time you set.',
      'Back to my task',
      'Take a 10-min break instead',
    ];
    for (final c in copies) {
      expect(RsdSafeCopy.isSafe(c), isTrue, reason: '"$c"');
    }
  });

  testWidgets('calm pause screen renders both choices in normal mode',
      (tester) async {
    var returned = false;
    var broke = false;
    await tester.pumpWidget(
      CalmPauseScreen(
        appName: 'Instagram',
        taskTitle: 'Clean the kitchen',
        onReturnToTask: () => returned = true,
        onTakeBreak: () => broke = true,
      ),
    );
    expect(find.text('Back to my task'), findsOneWidget);
    expect(find.text('Take a 10-min break instead'), findsOneWidget);
    await tester.tap(find.text('Back to my task'));
    await tester.tap(find.text('Take a 10-min break instead'));
    expect(returned, isTrue);
    expect(broke, isTrue);
  });

  testWidgets('monk mode hides the break option', (tester) async {
    await tester.pumpWidget(
      CalmPauseScreen(
        appName: 'YouTube',
        taskTitle: 'Reply to emails',
        monkMode: true,
        onReturnToTask: () {},
        onTakeBreak: () {},
      ),
    );
    expect(find.text('Take a 10-min break instead'), findsNothing);
    expect(find.textContaining('Monk mode is on'), findsOneWidget);
  });
}

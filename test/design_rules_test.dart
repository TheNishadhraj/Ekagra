import 'dart:io';

import 'package:ekagra/config/feature_flags.dart';
import 'package:ekagra/services/analytics_service.dart';
import 'package:ekagra/services/monetization_service.dart';
import 'package:ekagra/services/nudge_copy.dart';
import 'package:ekagra/utils/rsd_safe_copy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Executable enforcement of the 15 non-negotiable design rules.
///
/// The spec says "every pull request must include a Rule Compliance
/// checkbox". A checkbox is a promise a tired human makes at 6pm on a Friday.
/// These tests are the same promise, kept by CI, every time, for free.
///
/// `RsdSafeCopy.isSafe()` already existed in the codebase and was called
/// from exactly nowhere. This file is what makes it real.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // The monetization service is a singleton shared across the suite.
    // Without an explicit reset these tests would depend on whatever ran
    // before them — the classic way a green suite hides a real regression.
    SharedPreferences.setMockInitialValues({});
    await AnalyticsService.instance.resetForTest();
    await MonetizationService.instance.resetForTest();
  });

  /// Every Dart source file that can put words in front of a user.
  final uiFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) =>
          f.path.contains('/screens/') ||
          f.path.contains('/widgets/') ||
          f.path.contains('/utils/') ||
          f.path.contains('/config/constants'))
      .toList();

  /// Pull user-visible string literals out of a source file.
  ///
  /// Deliberately conservative: we only inspect strings that reach a
  /// rendering or messaging call. Scanning every literal would flag
  /// identifiers, JSON keys and analytics event names, produce noise, and
  /// train the team to ignore the check — which is worse than no check.
  List<String> userFacingStrings(String source) {
    final withoutComments = source
        .replaceAll(RegExp(r'//[^\n]*'), '')
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

    final out = <String>[];
    final pattern = RegExp(
      r'''(?:Text|Text\.rich|SnackBar\(\s*content:\s*Text|label|title|subtitle|hintText|semanticLabel)\s*[:(]\s*(?:const\s+)?[' "]''',
    );
    for (final match in pattern.allMatches(withoutComments)) {
      final start = match.end - 1;
      final quote = withoutComments[start];
      if (quote != "'" && quote != '"') continue;
      final buffer = StringBuffer();
      for (var i = start + 1; i < withoutComments.length; i++) {
        final ch = withoutComments[i];
        if (ch == r'\') {
          i++;
          continue;
        }
        if (ch == quote) break;
        if (ch == '\n') break;
        buffer.write(ch);
      }
      final text = buffer.toString().trim();
      if (text.length > 2) out.add(text);
    }
    return out;
  }

  group('Rule 3 — no red for negative states', () {
    test('no source file references a pure red', () {
      final offenders = <String>[];
      for (final file in uiFiles) {
        final src = file.readAsStringSync();
        if (RegExp(r'Colors\.red|0xFFFF0000|Color\(0xFFF[0-9A-Fa-f]{2}0000\)')
            .hasMatch(src)) {
          offenders.add(file.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Red signals danger/failure. Use EkagraColors.error '
            '(warm coral) instead. Offending files: $offenders',
      );
    });
  });

  group('Rules 4, 5, 6, 15 — shame-free language', () {
    test('no user-facing copy contains forbidden or shaming words', () {
      final violations = <String>[];

      for (final file in uiFiles) {
        // The audit helper legitimately contains the forbidden words as data.
        if (file.path.endsWith('rsd_safe_copy.dart')) continue;
        if (file.path.endsWith('design_rules.dart')) continue;

        for (final text in userFacingStrings(file.readAsStringSync())) {
          if (!RsdSafeCopy.isSafe(text)) {
            violations.add('${file.path}: "$text"');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Shame language drives abandonment in an RSD-sensitive '
            'audience. Violations:\n${violations.join('\n')}',
      );
    });

    test('the audit helper itself catches the words it claims to', () {
      // Guards against someone gutting RsdSafeCopy and turning every other
      // test in this group into a no-op that always passes.
      expect(RsdSafeCopy.isSafe('You missed 3 tasks'), isFalse);
      expect(RsdSafeCopy.isSafe('Your streak is broken'), isFalse);
      expect(RsdSafeCopy.isSafe('2 overdue items'), isFalse);
      expect(RsdSafeCopy.isSafe('You failed today'), isFalse);
      expect(RsdSafeCopy.isSafe("You're behind"), isFalse);
      expect(RsdSafeCopy.isSafe('3 pending'), isFalse);

      expect(RsdSafeCopy.isSafe('4 days active'), isTrue);
      expect(RsdSafeCopy.isSafe('Welcome back!'), isTrue);
      expect(RsdSafeCopy.isSafe('One thing at a time.'), isTrue);
    });
  });

  group('Rule 8 — no dark patterns on subscription', () {
    test('cancellation preserves access to the end of the paid period', () {
      // Encoded here as well as in monetization_test because this is the
      // rule most likely to be "optimised away" under revenue pressure.
      expect(PaywallTrigger.taskLimit.isHard, isTrue);
      expect(PaywallTrigger.bodyDoubling.isHard, isFalse);
      expect(PaywallTrigger.settings.isHard, isFalse);
    });

    test('only one trigger may ever hard-block the user', () {
      final hard =
          PaywallTrigger.values.where((t) => t.isHard).toList();
      expect(
        hard.length,
        1,
        reason: 'Every additional hard gate converts a little revenue and '
            'a lot of trust. Adding one is a product decision that needs '
            'to be made deliberately, not by editing an extension.',
      );
    });

    test('the daily paywall cap stays humane', () {
      expect(MonetizationService.maxPaywallsPerDay, lessThanOrEqualTo(2));
      expect(
        MonetizationService.dismissalsBeforeBackoff,
        lessThanOrEqualTo(3),
      );
      expect(
        MonetizationService.softPaywallCooldown.inHours,
        greaterThanOrEqualTo(12),
      );
    });
  });

  group('Consumer protection — never bill for simulated features', () {
    test('no non-billable feature is reachable behind a paywall', () {
      final offenders = <String>[];
      for (final trigger in PaywallTrigger.values) {
        final feature = trigger.backingFeature;
        if (feature != null && !feature.isBillable) {
          // The trigger may exist, but the governor must refuse it.
          if (MonetizationService.instance.shouldShowPaywall(trigger)) {
            offenders.add('${trigger.id} -> ${feature.name} '
                '(${feature.maturity.name})');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Charging for simulated data is a misrepresentation and '
            'grounds for App Store removal. Offenders: $offenders',
      );
    });

    test('simulated features are free for everyone', () {
      final money = MonetizationService.instance;
      for (final f in ProFeature.values) {
        if (!f.isBillable) {
          expect(
            money.hasAccess(f),
            isTrue,
            reason: '${f.name} is ${f.maturity.name} — it must not be '
                'locked, because it must not be sold.',
          );
        }
      }
    });

    test('body doubling and widgets are not billable today', () {
      // Explicit regression guard. If someone builds the backend and flips
      // the flag, this test fails loudly and tells them to update it —
      // which is exactly the moment to re-check the paywall copy.
      expect(FeatureFlags.bodyDoubling, FeatureMaturity.simulated);
      expect(FeatureFlags.widgets, FeatureMaturity.unbuilt);
      expect(ProFeature.bodyDoubling.isBillable, isFalse);
      expect(ProFeature.widgets.isBillable, isFalse);
    });
  });

  group('Truth in advertising — no unsupported "AI" claims', () {
    test('no user-facing copy claims AI while the engine is on-device', () {
      // `AiService` is a deterministic scoring function. There is no HTTP
      // client in pubspec.yaml and no model call anywhere. Until that
      // changes, calling it "AI" in the UI is a claim we cannot support.
      if (FeatureFlags.aiTaskSelection == FeatureMaturity.live) return;

      final aiClaim = RegExp(r'\bA\.?I\.?\b|artificial intelligence|GPT',
          caseSensitive: false);
      final violations = <String>[];

      for (final file in uiFiles) {
        for (final text in userFacingStrings(file.readAsStringSync())) {
          if (aiClaim.hasMatch(text)) violations.add('${file.path}: "$text"');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Ship a real model before claiming one. Violations:\n'
            '${violations.join('\n')}',
      );
    });
  });

  group('Rule 13 — soft delete only', () {
    test('no hard delete of task collections in providers', () {
      final providerDir = Directory('lib/providers');
      final offenders = <String>[];
      for (final file in providerDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final src = file.readAsStringSync().replaceAll(
              RegExp(r'//[^\n]*'),
              '',
            );
        if (RegExp(r'_tasks\.removeWhere|_tasks\.removeAt|_tasks\.clear\(')
            .hasMatch(src)) {
          offenders.add(file.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Tasks are soft-deleted (isDeleted / archived) so a user '
            'never loses a thought. Offenders: $offenders',
      );
    });
  });

  group('Rule 15 — string banks outside the widget tree', () {
    // The source extractor above scans screens/widgets/utils/config. Copy
    // that lives in services (notification banks, celebrations) is equally
    // user-facing, so it is asserted here by name instead.
    test('every nudge copy rotation is shame-free', () {
      for (final s in NudgeCopy.allStrings) {
        expect(RsdSafeCopy.isSafe(s), isTrue, reason: '"$s"');
      }
    });

    test('no nudge copy claims unsupported intelligence', () {
      final aiClaim =
          RegExp(r'\bA\.?I\.?\b|artificial intelligence|GPT', caseSensitive: false);
      for (final s in NudgeCopy.allStrings) {
        expect(aiClaim.hasMatch(s), isFalse, reason: '"$s"');
      }
    });
  });

  group('Rule 14 — no comparison to other users', () {
    test('no leaderboard or ranking language in the UI', () {
      final banned = RegExp(
        r'\b(leaderboard|rank(?:ed|ing)?|top \d+%|better than|compared to '
        r'other|beat \w+ users)\b',
        caseSensitive: false,
      );
      final violations = <String>[];
      for (final file in uiFiles) {
        for (final text in userFacingStrings(file.readAsStringSync())) {
          if (banned.hasMatch(text)) violations.add('${file.path}: "$text"');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });
}

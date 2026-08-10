import '../config/design_rules.dart';

/// Spec R5 — RSD-safe language audit helpers.
/// Rejects shame words and forbidden terms from the 15 design rules.
class RsdSafeCopy {
  RsdSafeCopy._();

  static final _forbidden = <String>{
    DesignRules.forbiddenStreakWord,
    DesignRules.forbiddenOverdueWord,
    ...DesignRules.forbiddenShameWords,
    'lazy',
    'failure',
    'broken',
    'behind',
    'should have',
    'why didn\'t you',
    'you broke',
    'start over',
    'incomplete',
    'pending',
  };

  /// Returns true if [text] appears free of shame/forbidden language.
  static bool isSafe(String text) {
    final lower = text.toLowerCase();
    for (final word in _forbidden) {
      if (lower.contains(word.toLowerCase())) return false;
    }
    return true;
  }

  /// Shame-free active-days display (Spec C8). Never says "streak".
  static String activeDaysDisplay({
    required bool isActiveToday,
    required int currentConsecutive,
    required int daysSinceLastActive,
    required int totalActiveDays,
  }) {
    if (isActiveToday) {
      return '💛 $currentConsecutive days active';
    } else if (daysSinceLastActive <= 1) {
      return '💛 Welcome back!';
    } else {
      return '💛 Welcome back! $totalActiveDays days active total.';
    }
  }

  static const networkError =
      "Looks like you're offline. No worries — your data is safe 📶";
  static const aiTimeout =
      "Hmm, that took too long. Let's pick a task the simple way.";
  static const taskLimit =
      "You've reached the free task limit. Pro removes the ceiling.";
  static const subscriptionExpired =
      'Your Pro access ended. Your data is still here! Renew to keep going.';
  static const paymentFailed =
      "Payment didn't go through. No stress — try again when you're ready.";
  static const syncError =
      "Your data had a hiccup syncing. It'll sort itself out next time.";
  static const crashRecovery =
      "Welcome back! Let's pick up where you left off.";
  static const rateLimit =
      "We're taking a quick breather. Try again in a moment.";
  static const unknownError =
      'Something unexpected happened. Your data is safe. Try again?';
}

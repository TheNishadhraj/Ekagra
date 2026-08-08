/// Non-negotiable design rules from Ekagra Spec Section A1.
/// Every PR must confirm compliance. Violations cause user abandonment.
class DesignRules {
  DesignRules._();

  /// RULE 1: No screen shows more than 3 primary choices
  static const int maxPrimaryChoices = 3;

  /// RULE 2: No action requires more than 2 taps
  static const int maxTapsPerAction = 2;

  /// RULE 3: No text uses red for negative states (warm coral only)
  static const bool allowRedForNegative = false;

  /// RULE 4: No word "streak" in the UI (use "active days")
  static const String forbiddenStreakWord = 'streak';
  static const String activeDaysLabel = 'active days';

  /// RULE 5: No word "overdue" in the UI
  static const String forbiddenOverdueWord = 'overdue';

  /// RULE 6: No word "failed" or "missed" in the UI
  static const List<String> forbiddenShameWords = ['failed', 'missed'];

  /// RULE 7: No count of "incomplete" or "pending" tasks shown
  static const bool showIncompleteCount = false;

  /// RULE 8: No dark patterns on subscription
  static const bool allowSubscriptionDarkPatterns = false;

  /// RULE 9: No forced setup before core value delivery
  static const bool requireSetupBeforeValue = false;

  /// RULE 10: No feature ships on only one platform
  static const bool requireFeatureParity = true;

  /// RULE 11: No notification without user consent
  static const bool requireNotificationConsent = true;

  /// RULE 12: No screen goes dark during focus mode
  static const bool allowScreenDarkDuringFocus = false;

  /// RULE 13: No task auto-deletes (ever) — soft delete only
  static const bool allowHardDelete = false;

  /// RULE 14: No comparison to other users
  static const bool allowUserComparison = false;

  /// RULE 15: No shame in any copy, animation, or interaction
  static const bool allowShame = false;

  /// Home shows at most this many upcoming tasks (Rule 1 + progressive disclosure)
  static const int maxUpcomingTasksOnHome = 4;

  /// Free tier task limit
  static const int freeTierTaskLimit = 10;
}

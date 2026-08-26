/// Copy bank for every nudge the engine can send (WI-1.4).
///
/// Design rules encoded here, from the notification evidence base:
/// - **Icon + few words**: titles are ≤6 words; bodies are one breath.
/// - **Rotate weekly**: habituation is the documented failure mode of
///   reminder systems, so each bank has ≥3 rotations and the pick is a
///   pure function of the ISO-ish week number.
/// - **Firm without guilt**: "still here", never "missed". Every string
///   passes `RsdSafeCopy.isSafe()` — enforced by test, not by hope.
class NudgeCopy {
  NudgeCopy._();

  static const List<String> taskTitles = [
    'Your one thing 💛',
    'Still here for you ✨',
    'A tiny start? 🌱',
  ];

  static const List<String> taskBodies = [
    '{task} is still here when you are.',
    'No rush — {task} waits warmly.',
    'Two minutes on {task} might be enough.',
  ];

  static const List<String> dailyBriefTitles = [
    'Your one thing is ready 💛',
    'One thing, that is all 🌱',
    'Fresh pick waiting ✨',
  ];

  static const List<String> dailyBriefBodies = [
    'Tap to see today\'s pick.',
    'We chose, so you do not have to.',
    'A gentle start is one tap away.',
  ];

  static const List<String> welcomeBackTitles = [
    'Nothing was lost 💛',
    'Your one thing is still here 🌈',
    'Welcome back ✨',
  ];

  static const List<String> welcomeBackBodies = [
    'Everything you saved is safe.',
    'Pick up right where you left off.',
    'One tap and you are back.',
  ];

  static const List<String> transitionTitles = [
    '15 min left ⏳',
    'Quarter hour to go 🌗',
    'Almost there 🧡',
  ];

  static const List<String> transitionBodies = [
    '{task} — 15 minutes on the clock.',
    '{task}: time to land the ending.',
    'Still with {task}? Tap to continue.',
  ];

  /// Week index used for rotation. Pure function of the date so the same
  /// calendar week always shows the same copy (no flicker), and the next
  /// week always differs (habituation resistance).
  static int weekIndex(DateTime now) {
    final days = now.difference(DateTime(2026, 1, 5)).inDays;
    return days ~/ 7;
  }

  static String _pick(List<String> bank, DateTime now) {
    final w = weekIndex(now);
    return bank[w % bank.length];
  }

  static String taskTitle(DateTime now) => _pick(taskTitles, now);
  static String taskBody(DateTime now, String taskTitleText) =>
      _pick(taskBodies, now).replaceAll('{task}', taskTitleText);
  static String dailyBriefTitle(DateTime now) => _pick(dailyBriefTitles, now);
  static String dailyBriefBody(DateTime now) => _pick(dailyBriefBodies, now);
  static String welcomeBackTitle(DateTime now) =>
      _pick(welcomeBackTitles, now);
  static String welcomeBackBody(DateTime now) =>
      _pick(welcomeBackBodies, now);
  static String transitionTitle(DateTime now) =>
      _pick(transitionTitles, now);
  static String transitionBody(DateTime now, String taskTitleText) =>
      _pick(transitionBodies, now).replaceAll('{task}', taskTitleText);

  /// Every rotation of every bank is safe — the design-rules suite asserts
  /// this whole list so a bad string cannot hide in an unrotated bank.
  static List<String> get allStrings => [
    ...taskTitles,
    ...taskBodies.map((s) => s.replaceAll('{task}', 'thing')),
    ...dailyBriefTitles,
    ...dailyBriefBodies,
    ...welcomeBackTitles,
    ...welcomeBackBodies,
    ...transitionTitles,
    ...transitionBodies.map((s) => s.replaceAll('{task}', 'thing')),
  ];
}

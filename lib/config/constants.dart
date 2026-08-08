/// App-wide constants from the Ekagra unified specification.
class EkagraConstants {
  EkagraConstants._();

  static const String appName = 'Ekagra';
  static const String appTagline = 'Your shame-free daily companion';

  // Subscription
  static const double proMonthlyPrice = 7.99;
  static const double proYearlyPrice = 49.99;
  static const int freeTrialDays = 7;

  // Focus defaults
  static const int defaultFocusMinutes = 25;
  static const List<int> focusDurationOptions = [5, 10, 15, 25, 45, 60];

  // Energy / mood re-prompt
  static const int energyRecheckHours = 4;

  // Skip limits before suggesting brain dump
  static const int maxOneThingSkips = 3;

  // Auto-pruning
  static const int pruneAfterDays = 30;

  // Notifications (defaults)
  static const int defaultMorningHour = 8;
  static const int defaultMiddayHour = 12;
  static const int defaultAfternoonHour = 15;
  static const int defaultEveningHour = 20;
  static const int defaultWakeHour = 7;
  static const int defaultSleepHour = 23;
  static const int defaultDndStartHour = 22;
  static const int defaultDndEndHour = 7;

  // Encouragements — rotate, never repeat two days in a row
  static const List<String> encouragements = [
    "You've got this today.",
    'One thing at a time. That\'s enough.',
    'Progress, not perfection.',
    'Your brain works differently. That\'s a feature, not a bug.',
    'Starting is the hardest part. You already opened the app.',
    'You don\'t have to do it all. Just do one thing.',
    'Be kind to yourself today.',
    'Small steps count as steps.',
    'You showed up. That matters.',
    'The fact that you\'re reading this means you\'re trying.',
    'Done is better than perfect.',
    'You\'re not lazy. You\'re running a different operating system.',
    'Today\'s goal: one thing. Everything else is bonus.',
    'Rest is productive too.',
    'Your best looks different every day. That\'s okay.',
  ];

  // Common brain-dump quick templates
  static const List<String> commonTaskTemplates = [
    'Reply to emails',
    'Drink water',
    'Take medication',
    'Quick tidy (10 min)',
    'Call someone',
    'Groceries',
    'Pay a bill',
    'Move body',
    'Prep tomorrow',
    'Brain rest',
  ];
}


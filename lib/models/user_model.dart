enum AdhdTrait {
  taskParalysis,
  timeBlindness,
  taskSwitching,
  energyFluctuation,
}

class EkagraNotificationSlot {
  final bool enabled;
  final int hour;
  final int minute;

  const EkagraNotificationSlot({
    this.enabled = true,
    required this.hour,
    this.minute = 0,
  });

  EkagraNotificationSlot copyWith({bool? enabled, int? hour, int? minute}) {
    return EkagraNotificationSlot(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
      };

  factory EkagraNotificationSlot.fromJson(Map<String, dynamic> json) {
    return EkagraNotificationSlot(
      enabled: json['enabled'] as bool? ?? true,
      hour: json['hour'] as int? ?? 8,
      minute: json['minute'] as int? ?? 0,
    );
  }
}

class NotificationSettings {
  final EkagraNotificationSlot morning;
  final EkagraNotificationSlot midday;
  final EkagraNotificationSlot afternoon;
  final EkagraNotificationSlot evening;
  final bool smartTiming;
  final bool inactivityNudge;
  final int dndStartHour;
  final int dndEndHour;
  final bool permissionGranted;

  const NotificationSettings({
    this.morning = const EkagraNotificationSlot(hour: 8),
    this.midday = const EkagraNotificationSlot(hour: 12),
    this.afternoon = const EkagraNotificationSlot(hour: 15),
    this.evening = const EkagraNotificationSlot(hour: 20),
    this.smartTiming = true,
    this.inactivityNudge = true,
    this.dndStartHour = 22,
    this.dndEndHour = 7,
    this.permissionGranted = false,
  });

  NotificationSettings copyWith({
    EkagraNotificationSlot? morning,
    EkagraNotificationSlot? midday,
    EkagraNotificationSlot? afternoon,
    EkagraNotificationSlot? evening,
    bool? smartTiming,
    bool? inactivityNudge,
    int? dndStartHour,
    int? dndEndHour,
    bool? permissionGranted,
  }) {
    return NotificationSettings(
      morning: morning ?? this.morning,
      midday: midday ?? this.midday,
      afternoon: afternoon ?? this.afternoon,
      evening: evening ?? this.evening,
      smartTiming: smartTiming ?? this.smartTiming,
      inactivityNudge: inactivityNudge ?? this.inactivityNudge,
      dndStartHour: dndStartHour ?? this.dndStartHour,
      dndEndHour: dndEndHour ?? this.dndEndHour,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }

  Map<String, dynamic> toJson() => {
        'morning': morning.toJson(),
        'midday': midday.toJson(),
        'afternoon': afternoon.toJson(),
        'evening': evening.toJson(),
        'smartTiming': smartTiming,
        'inactivityNudge': inactivityNudge,
        'dndStartHour': dndStartHour,
        'dndEndHour': dndEndHour,
        'permissionGranted': permissionGranted,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      morning: json['morning'] != null
          ? EkagraNotificationSlot.fromJson(
              json['morning'] as Map<String, dynamic>,
            )
          : const EkagraNotificationSlot(hour: 8),
      midday: json['midday'] != null
          ? EkagraNotificationSlot.fromJson(
              json['midday'] as Map<String, dynamic>,
            )
          : const EkagraNotificationSlot(hour: 12),
      afternoon: json['afternoon'] != null
          ? EkagraNotificationSlot.fromJson(
              json['afternoon'] as Map<String, dynamic>,
            )
          : const EkagraNotificationSlot(hour: 15),
      evening: json['evening'] != null
          ? EkagraNotificationSlot.fromJson(
              json['evening'] as Map<String, dynamic>,
            )
          : const EkagraNotificationSlot(hour: 20),
      smartTiming: json['smartTiming'] as bool? ?? true,
      inactivityNudge: json['inactivityNudge'] as bool? ?? true,
      dndStartHour: json['dndStartHour'] as int? ?? 22,
      dndEndHour: json['dndEndHour'] as int? ?? 7,
      permissionGranted: json['permissionGranted'] as bool? ?? false,
    );
  }
}

class UserModel {
  final String id;
  final String? displayName;
  final String? email;
  final List<AdhdTrait> adhdTraits;
  final int wakeHour;
  final int wakeMinute;
  final int sleepHour;
  final int sleepMinute;
  final NotificationSettings notifications;
  final bool onboardingComplete;
  final bool paywallSeen;
  final bool isPro;
  final bool isAnonymous;
  final DateTime? trialStartedAt;
  final DateTime? lastActiveAt;
  final int totalActiveDays;
  final int currentConsecutiveDays;
  final DateTime createdAt;

  /// Default trial length in days. Kept here so the legacy `isPro` path
  /// and the newer [MonetizationService] path agree on duration.
  static const int trialDays = 7;

  const UserModel({
    required this.id,
    this.displayName,
    this.email,
    this.adhdTraits = const [AdhdTrait.taskParalysis],
    this.wakeHour = 7,
    this.wakeMinute = 0,
    this.sleepHour = 23,
    this.sleepMinute = 0,
    this.notifications = const NotificationSettings(),
    this.onboardingComplete = false,
    this.paywallSeen = false,
    this.isPro = false,
    this.isAnonymous = true,
    this.trialStartedAt,
    this.lastActiveAt,
    this.totalActiveDays = 0,
    this.currentConsecutiveDays = 0,
    required this.createdAt,
  });

  factory UserModel.guest() {
    return UserModel(
      id: 'guest',
      displayName: 'friend',
      createdAt: DateTime.now(),
    );
  }

  String get name => displayName ?? 'friend';

  /// Whether the legacy `isPro` trial is currently within its window.
  /// Returns false if the user is not on a trial (paid, or never started).
  bool get isTrialActive {
    final start = trialStartedAt;
    if (start == null || isAnonymous) return false;
    return DateTime.now().difference(start).inDays < trialDays;
  }

  /// Whole days remaining on the legacy trial. Zero once expired.
  int get trialDaysRemaining {
    final start = trialStartedAt;
    if (start == null || isAnonymous) return 0;
    final elapsed = DateTime.now().difference(start).inDays;
    return (trialDays - elapsed).clamp(0, trialDays);
  }

  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    List<AdhdTrait>? adhdTraits,
    int? wakeHour,
    int? wakeMinute,
    int? sleepHour,
    int? sleepMinute,
    NotificationSettings? notifications,
    bool? onboardingComplete,
    bool? paywallSeen,
    bool? isPro,
    bool? isAnonymous,
    DateTime? trialStartedAt,
    DateTime? lastActiveAt,
    int? totalActiveDays,
    int? currentConsecutiveDays,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      adhdTraits: adhdTraits ?? this.adhdTraits,
      wakeHour: wakeHour ?? this.wakeHour,
      wakeMinute: wakeMinute ?? this.wakeMinute,
      sleepHour: sleepHour ?? this.sleepHour,
      sleepMinute: sleepMinute ?? this.sleepMinute,
      notifications: notifications ?? this.notifications,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      paywallSeen: paywallSeen ?? this.paywallSeen,
      isPro: isPro ?? this.isPro,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      currentConsecutiveDays:
          currentConsecutiveDays ?? this.currentConsecutiveDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'adhdTraits': adhdTraits.map((e) => e.name).toList(),
        'wakeHour': wakeHour,
        'wakeMinute': wakeMinute,
        'sleepHour': sleepHour,
        'sleepMinute': sleepMinute,
        'notifications': notifications.toJson(),
        'onboardingComplete': onboardingComplete,
        'paywallSeen': paywallSeen,
        'isPro': isPro,
        'isAnonymous': isAnonymous,
        'trialStartedAt': trialStartedAt?.toIso8601String(),
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'totalActiveDays': totalActiveDays,
        'currentConsecutiveDays': currentConsecutiveDays,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      adhdTraits: (json['adhdTraits'] as List<dynamic>?)
              ?.map((e) => AdhdTrait.values.byName(e as String))
              .toList() ??
          const [AdhdTrait.taskParalysis],
      wakeHour: json['wakeHour'] as int? ?? 7,
      wakeMinute: json['wakeMinute'] as int? ?? 0,
      sleepHour: json['sleepHour'] as int? ?? 23,
      sleepMinute: json['sleepMinute'] as int? ?? 0,
      notifications: json['notifications'] != null
          ? NotificationSettings.fromJson(
              json['notifications'] as Map<String, dynamic>,
            )
          : const NotificationSettings(),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      paywallSeen: json['paywallSeen'] as bool? ?? false,
      isPro: json['isPro'] as bool? ?? false,
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      trialStartedAt: json['trialStartedAt'] != null
          ? DateTime.parse(json['trialStartedAt'] as String)
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      totalActiveDays: json['totalActiveDays'] as int? ?? 0,
      currentConsecutiveDays: json['currentConsecutiveDays'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

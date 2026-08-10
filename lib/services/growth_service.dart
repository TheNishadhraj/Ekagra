import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

/// The activation ladder.
///
/// Ekagra's aha moment is NOT "signed up" and it is NOT "added a task".
/// It is **completing one focus session and receiving a dopamine reward** —
/// the first time the user experiences the loop doing for them what willpower
/// could not. Everything before that is setup cost; everything after is habit.
enum ActivationStep {
  installed,
  firstTaskCaptured,
  firstEnergyCheckin,
  firstOneThingSelected,
  firstFocusStarted,
  firstFocusCompleted,
  firstRewardClaimed,
}

extension ActivationStepX on ActivationStep {
  String get label {
    switch (this) {
      case ActivationStep.installed:
        return 'Opened Ekagra';
      case ActivationStep.firstTaskCaptured:
        return 'Got something out of your head';
      case ActivationStep.firstEnergyCheckin:
        return 'Checked in with your energy';
      case ActivationStep.firstOneThingSelected:
        return 'Found your ONE thing';
      case ActivationStep.firstFocusStarted:
        return 'Started a focus session';
      case ActivationStep.firstFocusCompleted:
        return 'Finished a focus session';
      case ActivationStep.firstRewardClaimed:
        return 'Claimed your first reward';
    }
  }

  /// The step that defines an activated user.
  static ActivationStep get ahaMoment => ActivationStep.firstRewardClaimed;
}

/// Tracks activation, habit strength and the retention loop.
///
/// This is the counterweight to the monetization service: it makes sure we
/// are measuring whether the product actually works for people, not only
/// whether it extracts money from them.
class GrowthService extends ChangeNotifier {
  GrowthService._();

  static final GrowthService instance = GrowthService._();

  static const _key = 'ekagra_growth_state';

  /// Consecutive active days after which the habit is considered formed.
  /// Chosen from habit-formation research plus the practical observation that
  /// users who return three days running rarely churn in week one.
  static const int habitThresholdDays = 3;

  Set<String> _completedSteps = {};
  DateTime? _installedAt;
  DateTime? _activatedAt;
  DateTime? _lastActiveDay;
  DateTime? _habitFormedAt;
  int _consecutiveActiveDays = 0;
  int _totalActiveDays = 0;
  int _totalFocusSessions = 0;
  int _totalFocusMinutes = 0;
  int _totalTasksCompleted = 0;
  int _totalRewardsClaimed = 0;
  bool _loaded = false;

  bool get loaded => _loaded;
  DateTime? get installedAt => _installedAt;
  DateTime? get activatedAt => _activatedAt;
  DateTime? get habitFormedAt => _habitFormedAt;

  /// Spec Rule 4: never call this a "streak" in the UI.
  int get consecutiveActiveDays => _consecutiveActiveDays;
  int get totalActiveDays => _totalActiveDays;
  int get totalFocusSessions => _totalFocusSessions;
  int get totalFocusMinutes => _totalFocusMinutes;
  int get totalTasksCompleted => _totalTasksCompleted;
  int get totalRewardsClaimed => _totalRewardsClaimed;

  bool get isActivated => _activatedAt != null;
  bool get hasHabit => _habitFormedAt != null;

  int get daysSinceInstall => _installedAt == null
      ? 0
      : DateTime.now().difference(_installedAt!).inDays;

  bool hasCompleted(ActivationStep step) => _completedSteps.contains(step.name);

  List<ActivationStep> get remainingSteps =>
      ActivationStep.values.where((s) => !hasCompleted(s)).toList();

  /// Progress through the activation ladder, 0..1. Drives the progress-effect
  /// nudge on Home ("you're 2 steps from your first reward").
  double get activationProgress =>
      _completedSteps.length / ActivationStep.values.length;

  /// THE NORTH STAR: Focused Task Completions.
  ///
  /// Not DAU, not sessions, not time-in-app. A user who opens Ekagra five
  /// times and finishes nothing got no value; a user who opens it once and
  /// finishes the thing they were avoiding got everything. This metric can
  /// only go up when the product genuinely works, which makes it safe to
  /// optimise against — it cannot be gamed by making the app stickier.
  int get northStarValue => _totalTasksCompleted;

  /// Weekly rate of the North Star, the version worth watching over time.
  double get northStarPerActiveDay =>
      _totalActiveDays == 0 ? 0 : _totalTasksCompleted / _totalActiveDays;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _completedSteps =
            ((json['steps'] as List?) ?? []).map((e) => e as String).toSet();
        _installedAt = _parse(json['installedAt']);
        _activatedAt = _parse(json['activatedAt']);
        _lastActiveDay = _parse(json['lastActiveDay']);
        _habitFormedAt = _parse(json['habitFormedAt']);
        _consecutiveActiveDays =
            (json['consecutiveActiveDays'] as num?)?.toInt() ?? 0;
        _totalActiveDays = (json['totalActiveDays'] as num?)?.toInt() ?? 0;
        _totalFocusSessions = (json['totalFocusSessions'] as num?)?.toInt() ?? 0;
        _totalFocusMinutes = (json['totalFocusMinutes'] as num?)?.toInt() ?? 0;
        _totalTasksCompleted =
            (json['totalTasksCompleted'] as num?)?.toInt() ?? 0;
        _totalRewardsClaimed =
            (json['totalRewardsClaimed'] as num?)?.toInt() ?? 0;
      } catch (_) {
        _completedSteps = {};
      }
    }

    _installedAt ??= DateTime.now();
    _loaded = true;
    notifyListeners();
  }

  DateTime? _parse(Object? v) =>
      v == null ? null : DateTime.tryParse(v as String);

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'steps': _completedSteps.toList(),
        'installedAt': _installedAt?.toIso8601String(),
        'activatedAt': _activatedAt?.toIso8601String(),
        'lastActiveDay': _lastActiveDay?.toIso8601String(),
        'habitFormedAt': _habitFormedAt?.toIso8601String(),
        'consecutiveActiveDays': _consecutiveActiveDays,
        'totalActiveDays': _totalActiveDays,
        'totalFocusSessions': _totalFocusSessions,
        'totalFocusMinutes': _totalFocusMinutes,
        'totalTasksCompleted': _totalTasksCompleted,
        'totalRewardsClaimed': _totalRewardsClaimed,
      }),
    );
  }

  /// Mark an activation step. Idempotent — the second call is a no-op, so
  /// callers can fire it freely without inflating funnel counts.
  Future<void> completeStep(ActivationStep step) async {
    if (_completedSteps.contains(step.name)) return;
    _completedSteps.add(step.name);

    track(Ev.onboardingStepCompleted, {
      'step': step.name,
      'progress': activationProgress,
      'minutes_since_install': _installedAt == null
          ? 0
          : DateTime.now().difference(_installedAt!).inMinutes,
    });

    if (step == ActivationStepX.ahaMoment && _activatedAt == null) {
      _activatedAt = DateTime.now();
      track(Ev.activationReached, {
        'minutes_to_activate': _installedAt == null
            ? 0
            : _activatedAt!.difference(_installedAt!).inMinutes,
        'days_to_activate': daysSinceInstall,
      });
    }

    await _persist();
    notifyListeners();
  }

  /// Call once per app foreground. Maintains the active-day counters that
  /// power retention reporting and the habit signal.
  Future<void> recordAppOpen() async {
    final now = DateTime.now();
    final last = _lastActiveDay;

    if (last == null) {
      _consecutiveActiveDays = 1;
      _totalActiveDays = 1;
    } else {
      final lastDay = DateTime(last.year, last.month, last.day);
      final today = DateTime(now.year, now.month, now.day);
      final gap = today.difference(lastDay).inDays;

      if (gap == 0) {
        // Same day — nothing to increment.
      } else if (gap == 1) {
        _consecutiveActiveDays++;
        _totalActiveDays++;
      } else {
        // A gap is not a failure. We reset the counter silently and never
        // surface it as loss (Spec Rules 6 & 15).
        _consecutiveActiveDays = 1;
        _totalActiveDays++;
      }
    }

    _lastActiveDay = now;

    if (_consecutiveActiveDays >= habitThresholdDays && _habitFormedAt == null) {
      _habitFormedAt = now;
      track(Ev.habitFormed, {
        'consecutive_days': _consecutiveActiveDays,
        'days_since_install': daysSinceInstall,
      });
    }

    track(Ev.appOpened, {
      'days_since_last': last == null
          ? 0
          : now.difference(last).inDays,
      'consecutive_active_days': _consecutiveActiveDays,
      'total_active_days': _totalActiveDays,
      'is_activated': isActivated,
    });

    await _persist();
    notifyListeners();
  }

  Future<void> recordTaskCompleted() async {
    _totalTasksCompleted++;
    await _persist();
    notifyListeners();
  }

  Future<void> recordFocusSession(int minutes) async {
    _totalFocusSessions++;
    _totalFocusMinutes += minutes;
    await completeStep(ActivationStep.firstFocusCompleted);
    await _persist();
    notifyListeners();
  }

  Future<void> recordRewardClaimed() async {
    _totalRewardsClaimed++;
    await completeStep(ActivationStep.firstRewardClaimed);
    await _persist();
    notifyListeners();
  }

  /// Copy for the progress nudge on Home. Returns null once activated, so the
  /// nudge disappears the moment it stops being useful rather than nagging
  /// a user who already gets it.
  String? get activationNudge {
    if (isActivated) return null;
    if (!hasCompleted(ActivationStep.firstTaskCaptured)) {
      return 'Start by dumping whatever is rattling around your head.';
    }
    if (!hasCompleted(ActivationStep.firstOneThingSelected)) {
      return 'Let Ekagra pick just ONE thing for you.';
    }
    if (!hasCompleted(ActivationStep.firstFocusCompleted)) {
      return 'One short focus session and you will see how this works.';
    }
    return 'Your first reward is waiting.';
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _completedSteps = {};
    _installedAt = DateTime.now();
    _activatedAt = null;
    _lastActiveDay = null;
    _habitFormedAt = null;
    _consecutiveActiveDays = 0;
    _totalActiveDays = 0;
    _totalFocusSessions = 0;
    _totalFocusMinutes = 0;
    _totalTasksCompleted = 0;
    _totalRewardsClaimed = 0;
    _loaded = true;
  }
}

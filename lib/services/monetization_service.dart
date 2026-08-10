import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../config/feature_flags.dart';
import 'analytics_service.dart';
import 'experiment_service.dart';

/// Everything Pro can unlock. Gating by enum rather than by scattered
/// `if (isPro)` checks means the free/Pro matrix is one file, auditable in one
/// read, and impossible to drift out of sync with the pricing page.
enum ProFeature {
  unlimitedTasks,
  aiTaskSelection,
  allFocusDurations,
  unlimitedDopamineMenu,
  bodyDoubling,
  widgets,
  allAmbientSounds,
  aiTaskBreakdown,
  energyMoodInsights,
  customThemes,
  detailedStats,
  dataExport,
}

extension ProFeatureX on ProFeature {
  /// How real this feature actually is. See [FeatureFlags].
  FeatureMaturity get maturity {
    switch (this) {
      case ProFeature.bodyDoubling:
        return FeatureFlags.bodyDoubling;
      case ProFeature.aiTaskSelection:
        return FeatureFlags.aiTaskSelection;
      case ProFeature.aiTaskBreakdown:
        return FeatureFlags.aiTaskBreakdown;
      case ProFeature.widgets:
        return FeatureFlags.widgets;
      case ProFeature.dataExport:
        return FeatureFlags.dataExport;
      case ProFeature.unlimitedTasks:
        return FeatureFlags.unlimitedTasks;
      case ProFeature.allFocusDurations:
        return FeatureFlags.allFocusDurations;
      case ProFeature.unlimitedDopamineMenu:
        return FeatureFlags.unlimitedDopamineMenu;
      case ProFeature.allAmbientSounds:
        return FeatureFlags.allAmbientSounds;
      case ProFeature.energyMoodInsights:
        return FeatureFlags.energyMoodInsights;
      case ProFeature.customThemes:
        return FeatureFlags.customThemes;
      case ProFeature.detailedStats:
        return FeatureFlags.detailedStats;
    }
  }

  /// Whether it is lawful and honest to put this behind a paywall.
  ///
  /// Charging for a feature whose data is fabricated is a misrepresentation,
  /// not a product decision. This getter is the enforcement point.
  bool get isBillable => maturity == FeatureMaturity.live;

  /// User-facing name. Used in gate sheets — never show an enum to a human.
  String get label {
    switch (this) {
      case ProFeature.unlimitedTasks:
        return 'Unlimited brain dump';
      case ProFeature.aiTaskSelection:
        return 'AI picks your ONE thing';
      case ProFeature.allFocusDurations:
        return 'Every focus length';
      case ProFeature.unlimitedDopamineMenu:
        return 'Unlimited dopamine menu';
      case ProFeature.bodyDoubling:
        return 'Body doubling rooms';
      case ProFeature.widgets:
        return 'Home screen widgets';
      case ProFeature.allAmbientSounds:
        return 'All ambient sounds';
      case ProFeature.aiTaskBreakdown:
        return 'AI task breakdown';
      case ProFeature.energyMoodInsights:
        return 'Energy & mood insights';
      case ProFeature.customThemes:
        return 'Custom themes';
      case ProFeature.detailedStats:
        return 'Detailed stats';
      case ProFeature.dataExport:
        return 'Data export';
    }
  }

  /// The *job* the feature does. Gate copy that names the user's goal
  /// converts better than copy that names our feature.
  String get benefit {
    switch (this) {
      case ProFeature.unlimitedTasks:
        return 'Get everything out of your head — no ceiling.';
      case ProFeature.aiTaskSelection:
        return 'Stop deciding. Ekagra picks the right task for your energy.';
      case ProFeature.allFocusDurations:
        return 'Five minutes on a rough day. Sixty when you are flying.';
      case ProFeature.unlimitedDopamineMenu:
        return 'Rewards that actually motivate you, not generic ones.';
      case ProFeature.bodyDoubling:
        return 'Work alongside others. Presence beats willpower.';
      case ProFeature.widgets:
        return 'Your ONE thing, visible without opening the app.';
      case ProFeature.allAmbientSounds:
        return 'Find the sound that switches your brain into gear.';
      case ProFeature.aiTaskBreakdown:
        return 'Turn a scary task into three small ones.';
      case ProFeature.energyMoodInsights:
        return 'Learn when your good hours actually are.';
      case ProFeature.customThemes:
        return 'Make it feel like yours.';
      case ProFeature.detailedStats:
        return 'See the progress you keep forgetting you made.';
      case ProFeature.dataExport:
        return 'Your data is yours. Take it anywhere.';
    }
  }
}

/// Where a paywall was raised. Attribution by trigger tells us which gate
/// earns its keep and which is just friction.
enum PaywallTrigger {
  onboarding,
  taskLimit,
  aiSelection,
  bodyDoubling,
  widgets,
  focusDuration,
  ambientSounds,
  taskBreakdown,
  insights,
  dataExport,
  settings,
  winbackOffer,
  trialExpired,
}

extension PaywallTriggerX on PaywallTrigger {
  String get id => name;

  /// The feature this trigger is trying to sell, where there is one.
  /// Used to refuse paywalls for features that are not billable.
  ProFeature? get backingFeature {
    switch (this) {
      case PaywallTrigger.taskLimit:
        return ProFeature.unlimitedTasks;
      case PaywallTrigger.aiSelection:
        return ProFeature.aiTaskSelection;
      case PaywallTrigger.bodyDoubling:
        return ProFeature.bodyDoubling;
      case PaywallTrigger.widgets:
        return ProFeature.widgets;
      case PaywallTrigger.focusDuration:
        return ProFeature.allFocusDurations;
      case PaywallTrigger.ambientSounds:
        return ProFeature.allAmbientSounds;
      case PaywallTrigger.taskBreakdown:
        return ProFeature.aiTaskBreakdown;
      case PaywallTrigger.insights:
        return ProFeature.energyMoodInsights;
      case PaywallTrigger.dataExport:
        return ProFeature.dataExport;
      // Generic surfaces sell the bundle, not one feature.
      case PaywallTrigger.onboarding:
      case PaywallTrigger.settings:
      case PaywallTrigger.winbackOffer:
      case PaywallTrigger.trialExpired:
        return null;
    }
  }

  /// Hard gates block the action. Soft gates are dismissible invitations.
  /// Only gates protecting a genuinely metered resource should be hard —
  /// everything else erodes trust faster than it earns revenue.
  bool get isHard => this == PaywallTrigger.taskLimit;
}

enum SubscriptionPlan { monthly, annual }

extension SubscriptionPlanX on SubscriptionPlan {
  double get price => this == SubscriptionPlan.monthly
      ? EkagraConstants.proMonthlyPrice
      : EkagraConstants.proYearlyPrice;

  /// What the plan costs per month, for honest comparison.
  double get effectiveMonthly =>
      this == SubscriptionPlan.monthly ? price : price / 12;

  /// Percent saved vs. paying monthly for a year.
  int get annualSavingsPercent {
    if (this == SubscriptionPlan.monthly) return 0;
    final yearOfMonthly = EkagraConstants.proMonthlyPrice * 12;
    return (((yearOfMonthly - price) / yearOfMonthly) * 100).round();
  }

  String get label => this == SubscriptionPlan.monthly ? 'Monthly' : 'Annual';
}

/// Current entitlement state, derived — never stored as a bare bool.
/// Deriving from timestamps means a trial cannot silently stay active
/// because a write failed.
enum EntitlementStatus { free, trialing, pro, expired, cancelled }

/// The revenue engine.
///
/// Owns entitlements, the trial clock, and — importantly — the paywall
/// *governor*. The governor is the difference between a monetization system
/// and a nag: it enforces cooldowns, per-day caps and permanent backoff after
/// repeated dismissals.
class MonetizationService extends ChangeNotifier {
  MonetizationService._();

  static final MonetizationService instance = MonetizationService._();

  static const _stateKey = 'ekagra_monetization_state';

  // ── Governor policy ──────────────────────────────────────────────────────
  /// Never show a soft paywall twice within this window.
  static const Duration softPaywallCooldown = Duration(hours: 20);

  /// Hard ceiling per calendar day, across all triggers.
  static const int maxPaywallsPerDay = 2;

  /// After this many dismissals of the same trigger, retire that trigger for
  /// good. A user who said no three times has told us their answer.
  static const int dismissalsBeforeBackoff = 3;

  EntitlementStatus _status = EntitlementStatus.free;
  SubscriptionPlan? _plan;
  DateTime? _trialStartedAt;
  DateTime? _trialEndsAt;
  DateTime? _subscribedAt;
  DateTime? _renewsAt;
  DateTime? _cancelledAt;
  DateTime? _lastPaywallAt;
  int _paywallsShownToday = 0;
  DateTime? _paywallDayMarker;
  Map<String, int> _dismissalsByTrigger = {};
  Set<String> _retiredTriggers = {};
  bool _hasEverTrialed = false;
  bool _loaded = false;

  // ── Read model ───────────────────────────────────────────────────────────
  EntitlementStatus get status => _status;
  SubscriptionPlan? get plan => _plan;
  DateTime? get trialEndsAt => _trialEndsAt;
  DateTime? get renewsAt => _renewsAt;
  DateTime? get cancelledAt => _cancelledAt;
  bool get loaded => _loaded;
  bool get hasEverTrialed => _hasEverTrialed;
  Map<String, int> get dismissalsByTrigger => Map.unmodifiable(_dismissalsByTrigger);

  /// Trial length is itself an experiment.
  int get trialDays =>
      ExperimentService.instance.isIn(Experiments.trialLength, 'trial_14')
          ? 14
          : EkagraConstants.freeTrialDays;

  /// Free task ceiling is itself an experiment.
  int get freeTaskLimit =>
      ExperimentService.instance.isIn(Experiments.freeTaskLimit, 'limit_20')
          ? 20
          : 10;

  /// The single source of truth for "can this user use Pro things".
  bool get isPro {
    if (_status == EntitlementStatus.pro) return true;
    if (_status == EntitlementStatus.trialing) return !isTrialExpired;
    // A cancelled subscriber keeps access until the paid period ends.
    // Yanking access the instant they cancel is the kind of punishment that
    // guarantees they never come back.
    if (_status == EntitlementStatus.cancelled) {
      return _renewsAt != null && DateTime.now().isBefore(_renewsAt!);
    }
    return false;
  }

  bool get isTrialing => _status == EntitlementStatus.trialing && !isTrialExpired;

  bool get isTrialExpired {
    if (_trialEndsAt == null) return false;
    return DateTime.now().isAfter(_trialEndsAt!);
  }

  int get trialDaysRemaining {
    if (_trialEndsAt == null) return 0;
    final diff = _trialEndsAt!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inHours ~/ 24 + (diff.inHours % 24 > 0 ? 1 : 0);
  }

  /// Whether a given feature is unlocked right now.
  ///
  /// A feature that is not [ProFeatureX.isBillable] is open to everyone,
  /// regardless of subscription state. We do not take money for simulated
  /// data, so we do not lock it either — the paywall and the product stay
  /// consistent with each other by construction rather than by discipline.
  bool hasAccess(ProFeature feature) {
    if (!feature.isBillable) return true;
    return isPro;
  }

  /// Human-readable entitlement line for Settings.
  String get statusLabel {
    switch (_status) {
      case EntitlementStatus.pro:
        return 'Ekagra Pro — ${_plan?.label ?? 'active'}';
      case EntitlementStatus.trialing:
        return isTrialExpired
            ? 'Trial ended'
            : 'Pro trial — $trialDaysRemaining ${trialDaysRemaining == 1 ? 'day' : 'days'} left';
      case EntitlementStatus.cancelled:
        return isPro ? 'Pro until ${_formatDate(_renewsAt)}' : 'Cancelled';
      case EntitlementStatus.expired:
        return 'Trial ended — Free plan';
      case EntitlementStatus.free:
        return 'Free plan';
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  // ── Persistence ──────────────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _status = EntitlementStatus.values.byName(
          json['status'] as String? ?? 'free',
        );
        final planName = json['plan'] as String?;
        _plan = planName == null
            ? null
            : SubscriptionPlan.values.byName(planName);
        _trialStartedAt = _parse(json['trialStartedAt']);
        _trialEndsAt = _parse(json['trialEndsAt']);
        _subscribedAt = _parse(json['subscribedAt']);
        _renewsAt = _parse(json['renewsAt']);
        _cancelledAt = _parse(json['cancelledAt']);
        _lastPaywallAt = _parse(json['lastPaywallAt']);
        _paywallDayMarker = _parse(json['paywallDayMarker']);
        _paywallsShownToday = (json['paywallsShownToday'] as num?)?.toInt() ?? 0;
        _hasEverTrialed = json['hasEverTrialed'] as bool? ?? false;
        _dismissalsByTrigger =
            ((json['dismissals'] as Map?) ?? {}).map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        );
        _retiredTriggers =
            ((json['retired'] as List?) ?? []).map((e) => e as String).toSet();
      } catch (_) {
        // Corrupt state must fail *open* to free, never to a phantom Pro.
        _status = EntitlementStatus.free;
      }
    }

    _rolloverPaywallDayIfNeeded();
    _expireTrialIfNeeded();
    _loaded = true;
    notifyListeners();
  }

  DateTime? _parse(Object? v) =>
      v == null ? null : DateTime.tryParse(v as String);

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _stateKey,
      jsonEncode({
        'status': _status.name,
        'plan': _plan?.name,
        'trialStartedAt': _trialStartedAt?.toIso8601String(),
        'trialEndsAt': _trialEndsAt?.toIso8601String(),
        'subscribedAt': _subscribedAt?.toIso8601String(),
        'renewsAt': _renewsAt?.toIso8601String(),
        'cancelledAt': _cancelledAt?.toIso8601String(),
        'lastPaywallAt': _lastPaywallAt?.toIso8601String(),
        'paywallDayMarker': _paywallDayMarker?.toIso8601String(),
        'paywallsShownToday': _paywallsShownToday,
        'hasEverTrialed': _hasEverTrialed,
        'dismissals': _dismissalsByTrigger,
        'retired': _retiredTriggers.toList(),
      }),
    );
  }

  void _rolloverPaywallDayIfNeeded() {
    final now = DateTime.now();
    final marker = _paywallDayMarker;
    if (marker == null ||
        marker.year != now.year ||
        marker.month != now.month ||
        marker.day != now.day) {
      _paywallsShownToday = 0;
      _paywallDayMarker = now;
    }
  }

  void _expireTrialIfNeeded() {
    if (_status == EntitlementStatus.trialing && isTrialExpired) {
      _status = EntitlementStatus.expired;
      track(Ev.trialExpired, {
        'trial_days': trialDays,
        'converted': false,
      });
    }
  }

  // ── Paywall governor ─────────────────────────────────────────────────────

  /// Should we show a paywall for [trigger] right now?
  ///
  /// This is the ethical core of the monetization system. Conversion is a
  /// function of *relevance*, not frequency — and every suppressed impression
  /// here is retention we keep.
  bool shouldShowPaywall(PaywallTrigger trigger) {
    if (isPro) return false;

    // Hard stop: never raise a paywall for a feature we cannot honestly
    // bill for. This catches the case where someone adds a trigger for a
    // half-built feature and forgets the flag.
    final backing = trigger.backingFeature;
    if (backing != null && !backing.isBillable) {
      track(Ev.paywallSuppressed, {
        'trigger': trigger.id,
        'reason': 'feature_not_billable',
        'maturity': backing.maturity.name,
      });
      return false;
    }

    _rolloverPaywallDayIfNeeded();

    // Hard gates always show: the user has hit a real, metered ceiling and
    // needs to know why the app stopped.
    if (trigger.isHard) return true;

    if (_retiredTriggers.contains(trigger.id)) {
      track(Ev.paywallSuppressed, {
        'trigger': trigger.id,
        'reason': 'trigger_retired',
      });
      return false;
    }

    if (_paywallsShownToday >= maxPaywallsPerDay) {
      track(Ev.paywallSuppressed, {
        'trigger': trigger.id,
        'reason': 'daily_cap',
      });
      return false;
    }

    if (_lastPaywallAt != null &&
        DateTime.now().difference(_lastPaywallAt!) < softPaywallCooldown) {
      track(Ev.paywallSuppressed, {
        'trigger': trigger.id,
        'reason': 'cooldown',
      });
      return false;
    }

    return true;
  }

  /// Record that a paywall was actually presented.
  Future<void> recordPaywallShown(PaywallTrigger trigger) async {
    _rolloverPaywallDayIfNeeded();
    _lastPaywallAt = DateTime.now();
    _paywallsShownToday++;
    track(Ev.paywallShown, {
      'trigger': trigger.id,
      'is_hard': trigger.isHard,
      'shown_today': _paywallsShownToday,
      'has_ever_trialed': _hasEverTrialed,
    });
    await _persist();
    notifyListeners();
  }

  Future<void> recordPaywallDismissed(PaywallTrigger trigger) async {
    final count = (_dismissalsByTrigger[trigger.id] ?? 0) + 1;
    _dismissalsByTrigger[trigger.id] = count;

    if (count >= dismissalsBeforeBackoff && !trigger.isHard) {
      _retiredTriggers.add(trigger.id);
    }

    track(Ev.paywallDismissed, {
      'trigger': trigger.id,
      'dismissal_count': count,
      'retired': _retiredTriggers.contains(trigger.id),
    });
    await _persist();
    notifyListeners();
  }

  Future<void> recordFeatureGateHit(ProFeature feature) async {
    track(Ev.featureGateHit, {'feature': feature.name});
  }

  // ── Purchase lifecycle ───────────────────────────────────────────────────

  /// Begin the free trial.
  ///
  /// In production this is where RevenueCat's `purchasePackage` result would
  /// be validated before granting the entitlement. The state machine is
  /// identical either way, which is the point: swapping in the real billing
  /// SDK touches this method and nothing else.
  Future<void> startTrial({
    required PaywallTrigger trigger,
    SubscriptionPlan plan = SubscriptionPlan.annual,
  }) async {
    final now = DateTime.now();
    _status = EntitlementStatus.trialing;
    _plan = plan;
    _trialStartedAt = now;
    _trialEndsAt = now.add(Duration(days: trialDays));
    _renewsAt = _trialEndsAt;
    _hasEverTrialed = true;
    _cancelledAt = null;

    track(Ev.trialStarted, {
      'trigger': trigger.id,
      'plan': plan.name,
      'trial_days': trialDays,
      'price': plan.price,
    });
    track(Ev.paywallConverted, {
      'trigger': trigger.id,
      'plan': plan.name,
      'trial': true,
    });

    await _persist();
    notifyListeners();
  }

  /// Convert directly to paid (or from an active trial).
  Future<void> purchase({
    required SubscriptionPlan plan,
    required PaywallTrigger trigger,
  }) async {
    final now = DateTime.now();
    final wasTrialing = _status == EntitlementStatus.trialing;

    _status = EntitlementStatus.pro;
    _plan = plan;
    _subscribedAt = now;
    _renewsAt = now.add(
      Duration(days: plan == SubscriptionPlan.annual ? 365 : 30),
    );
    _cancelledAt = null;

    if (wasTrialing) {
      track(Ev.trialConverted, {
        'plan': plan.name,
        'price': plan.price,
        'trial_days': trialDays,
      });
    }
    track(Ev.paywallConverted, {
      'trigger': trigger.id,
      'plan': plan.name,
      'trial': false,
      'price': plan.price,
    });

    await _persist();
    notifyListeners();
  }

  /// One-tap cancellation (Spec Rule 8, Section O5). Access continues to the
  /// end of the paid period — no clawback, no retention maze.
  Future<void> cancel({String reason = 'user_initiated'}) async {
    _cancelledAt = DateTime.now();
    _status = EntitlementStatus.cancelled;
    track(Ev.subscriptionCancelled, {
      'plan': _plan?.name,
      'reason': reason,
      'days_subscribed': _subscribedAt == null
          ? 0
          : DateTime.now().difference(_subscribedAt!).inDays,
    });
    await _persist();
    notifyListeners();
  }

  /// Resubscribe after cancelling, without re-entering the trial.
  Future<void> resume() async {
    if (_status != EntitlementStatus.cancelled) return;
    _status = EntitlementStatus.pro;
    _cancelledAt = null;
    _renewsAt = DateTime.now().add(
      Duration(days: _plan == SubscriptionPlan.annual ? 365 : 30),
    );
    await _persist();
    notifyListeners();
  }

  /// Full downgrade — used by Settings' "switch back to Free" and tests.
  Future<void> downgradeToFree() async {
    _status = EntitlementStatus.free;
    _plan = null;
    _trialEndsAt = null;
    _renewsAt = null;
    _cancelledAt = null;
    await _persist();
    notifyListeners();
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _status = EntitlementStatus.free;
    _plan = null;
    _trialStartedAt = null;
    _trialEndsAt = null;
    _subscribedAt = null;
    _renewsAt = null;
    _cancelledAt = null;
    _lastPaywallAt = null;
    _paywallDayMarker = null;
    _paywallsShownToday = 0;
    _dismissalsByTrigger = {};
    _retiredTriggers = {};
    _hasEverTrialed = false;
    _loaded = true;
  }

  @visibleForTesting
  void debugSetTrialEnd(DateTime when) {
    _trialEndsAt = when;
    _status = EntitlementStatus.trialing;
  }
}

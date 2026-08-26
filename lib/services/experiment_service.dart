import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

/// One controlled experiment: a name, its variants, and the traffic split.
@immutable
class Experiment {
  final String key;
  final List<String> variants;

  /// Weights parallel to [variants]. Normalised internally, so [50, 50] and
  /// [1, 1] behave identically.
  final List<double> weights;
  final String hypothesis;
  final String successMetric;

  /// Guardrails that must NOT regress. Documented in code so the person
  /// reading the experiment later knows what to check before shipping it.
  final List<String> guardrailMetrics;

  const Experiment({
    required this.key,
    required this.variants,
    required this.hypothesis,
    required this.successMetric,
    this.guardrailMetrics = const [],
    this.weights = const [],
  });

  String get control => variants.first;

  List<double> get normalisedWeights {
    if (weights.length != variants.length || weights.isEmpty) {
      return List.filled(variants.length, 1 / variants.length);
    }
    final total = weights.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return List.filled(variants.length, 1 / variants.length);
    return weights.map((w) => w / total).toList();
  }
}

/// The experiment registry.
///
/// Every monetization decision worth arguing about should live here as a
/// variant rather than as a hardcoded constant someone has to redeploy to
/// change.
class Experiments {
  Experiments._();

  /// Anchoring: does leading with annual make the monthly plan feel cheap,
  /// and does it lift blended ARPU? Annual buyers churn far less, so even a
  /// flat conversion rate with an annual mix shift is a win on LTV.
  static const paywallAnchor = Experiment(
    key: 'paywall_anchor_v1',
    variants: ['monthly_first', 'annual_first'],
    hypothesis:
        'Anchoring on the annual plan first raises annual mix and blended LTV '
        'without reducing overall trial starts.',
    successMetric: 'trial_started per paywall_shown, weighted by plan LTV',
    guardrailMetrics: ['paywall_dismissed rate', 'subscription_cancelled'],
  );

  /// When do we first ask for money? Asking during onboarding reaches 100% of
  /// users but before they have felt value. Asking after the first completed
  /// focus session reaches fewer users at a far higher intent.
  static const paywallTiming = Experiment(
    key: 'paywall_timing_v1',
    variants: ['onboarding', 'post_first_value'],
    hypothesis:
        'Deferring the first paywall until after the first completed focus '
        'session raises trial->paid conversion, because the user has already '
        'experienced the aha moment.',
    successMetric: 'trial_converted per new install (D14)',
    guardrailMetrics: ['D7 retention', 'onboarding_abandoned'],
  );

  /// WI-5.3: does a milestone celebration lift the next-week return rate?
  /// Celebration copy tone: energetic hype vs. quiet warmth. Guardrail:
  /// celebrations must never read as pressure (Rule 15).
  static const milestoneTone = Experiment(
    key: 'milestone_tone_v1',
    variants: ['energetic', 'warm'],
    hypothesis:
        'A warm-tone milestone celebration lifts D7 return after the '
        'milestone more than energetic tone, because hype fades and '
        'warmth compounds for an audience wary of being graded.',
    successMetric: 'app_opened within 7 days of active_day_milestone',
    guardrailMetrics: ['milestone dismissed without claim', 'opt-outs'],
  );

  /// WI-5.3: how many menu refresh suggestions before it reads as chores?
  static const menuRefreshCount = Experiment(
    key: 'menu_refresh_count_v1',
    variants: ['three', 'five'],
    hypothesis:
        'Three monthly reward suggestions keep novelty without decision '
        'fatigue; five adds noise and reduces adds-per-suggestion.',
    successMetric: 'menu_refresh_added per menu_refresh_suggested',
    guardrailMetrics: ['menu screen abandoned', 'suggestions ignored'],
  );

  /// Reciprocity vs. scarcity framing on the upgrade CTA.
  static const paywallFraming = Experiment(
    key: 'paywall_framing_v1',
    variants: ['value_framing', 'reciprocity_framing'],
    hypothesis:
        'Reciprocity framing ("you have already done the work") converts '
        'better than feature-list framing for an ADHD audience that is '
        'fatigued by feature grids.',
    successMetric: 'trial_started per paywall_shown',
    guardrailMetrics: ['paywall_dismissed rate'],
  );

  /// Free tier generosity. A limit that bites too early feels punitive to an
  /// audience whose whole problem is offloading a crowded head; a limit that
  /// never bites earns nothing.
  static const freeTaskLimit = Experiment(
    key: 'free_task_limit_v1',
    variants: ['limit_10', 'limit_20'],
    hypothesis:
        'A 20-task free ceiling increases D7 retention enough that total paid '
        'conversion rises despite fewer users hitting the gate.',
    successMetric: 'paid conversion at D30',
    guardrailMetrics: ['D7 retention', 'feature_gate_hit rate'],
  );

  /// Trial length. Seven days is convention; fourteen gives an inconsistent
  /// user more chances to hit the aha moment.
  static const trialLength = Experiment(
    key: 'trial_length_v1',
    variants: ['trial_7', 'trial_14'],
    hypothesis:
        'A 14-day trial converts better for ADHD users whose usage is bursty '
        'and who may lose a whole week to a low period.',
    successMetric: 'trial_converted / trial_started',
    guardrailMetrics: ['time to revenue', 'refund rate'],
  );

  static const all = <Experiment>[
    paywallAnchor,
    paywallTiming,
    paywallFraming,
    freeTaskLimit,
    trialLength,
  ];
}

/// Deterministic, offline-capable A/B assignment.
///
/// Bucketing is a pure hash of (installId, experimentKey): the same user
/// always lands in the same variant, with no network call and no flicker.
/// Crucially the hash is salted per experiment, so a user who is in the
/// treatment arm of one test is not systematically in the treatment arm of
/// the next — that correlation is what silently poisons multi-test readouts.
class ExperimentService extends ChangeNotifier {
  ExperimentService._();

  static final ExperimentService instance = ExperimentService._();

  static const _installIdKey = 'ekagra_install_id';
  static const _overridesKey = 'ekagra_experiment_overrides';

  String _installId = '';
  Map<String, String> _overrides = {};
  final Set<String> _exposed = {};
  bool _loaded = false;

  String get installId => _installId;
  bool get loaded => _loaded;
  Map<String, String> get overrides => Map.unmodifiable(_overrides);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _installId = prefs.getString(_installIdKey) ?? '';
    if (_installId.isEmpty) {
      _installId = _generateInstallId();
      await prefs.setString(_installIdKey, _installId);
    }

    final raw = prefs.getString(_overridesKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _overrides = decoded.map((k, v) => MapEntry(k, v as String));
      } catch (_) {
        _overrides = {};
      }
    }
    _loaded = true;
    notifyListeners();
  }

  String _generateInstallId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final entropy = identityHashCode(this);
    return '${micros.toRadixString(36)}${entropy.toRadixString(36)}';
  }

  /// FNV-1a. Fast, stable across platforms and Dart versions — which matters,
  /// because a hash that changes between releases would silently reshuffle
  /// every user mid-experiment and invalidate the result.
  int _hash(String input) {
    const int prime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * prime) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Assign this install to a variant. Deterministic and side-effect free
  /// apart from a one-shot exposure event.
  String variantOf(Experiment experiment) {
    final override = _overrides[experiment.key];
    if (override != null && experiment.variants.contains(override)) {
      _logExposure(experiment, override, forced: true);
      return override;
    }

    final bucket = _hash('$_installId:${experiment.key}') % 10000;
    final position = bucket / 10000;

    double cumulative = 0;
    final weights = experiment.normalisedWeights;
    for (var i = 0; i < experiment.variants.length; i++) {
      cumulative += weights[i];
      if (position < cumulative) {
        final variant = experiment.variants[i];
        _logExposure(experiment, variant);
        return variant;
      }
    }

    final fallback = experiment.variants.last;
    _logExposure(experiment, fallback);
    return fallback;
  }

  bool isIn(Experiment experiment, String variant) =>
      variantOf(experiment) == variant;

  /// Exposure fires once per session per experiment. Logging it on every
  /// read would inflate the denominator and depress every measured rate.
  void _logExposure(
    Experiment experiment,
    String variant, {
    bool forced = false,
  }) {
    final token = '${experiment.key}:$variant';
    if (_exposed.contains(token)) return;
    _exposed.add(token);
    track(Ev.experimentExposed, {
      'experiment': experiment.key,
      'variant': variant,
      'forced': forced,
    });
  }

  /// QA / demo affordance. Lets the team force a variant from Settings
  /// without reinstalling to reshuffle the hash.
  Future<void> setOverride(String experimentKey, String? variant) async {
    if (variant == null) {
      _overrides.remove(experimentKey);
    } else {
      _overrides[experimentKey] = variant;
    }
    _exposed.removeWhere((t) => t.startsWith('$experimentKey:'));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_overridesKey, jsonEncode(_overrides));
    notifyListeners();
  }

  Future<void> clearOverrides() async {
    _overrides = {};
    _exposed.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_overridesKey);
    notifyListeners();
  }

  @visibleForTesting
  void seedInstallId(String id) {
    _installId = id;
    _exposed.clear();
    _loaded = true;
  }
}

/// Sample-size maths, so nobody ships a "winner" off 40 users.
///
/// Two-proportion test at 95% confidence / 80% power. The 15.7 constant is
/// 2 * (z_{α/2} + z_β)^2 = 2 * (1.96 + 0.84)^2.
class ExperimentMath {
  ExperimentMath._();

  /// Users needed **per variant** to detect [mde] absolute lift over
  /// [baselineRate].
  ///
  /// Example: baseline 5% trial conversion, want to detect +1pp absolute →
  /// requiredSampleSize(0.05, 0.01) ≈ 7,450 per arm.
  static int requiredSampleSize(double baselineRate, double mde) {
    if (mde <= 0) return 0;
    final p = baselineRate.clamp(0.0001, 0.9999);
    final variance = p * (1 - p);
    return (15.7 * variance / (mde * mde)).ceil();
  }

  /// Days to reach significance given daily eligible traffic.
  static int estimatedDurationDays({
    required double baselineRate,
    required double mde,
    required int dailyEligibleUsers,
    int variants = 2,
  }) {
    if (dailyEligibleUsers <= 0) return 0;
    final perArm = requiredSampleSize(baselineRate, mde);
    final total = perArm * variants;
    return (total / dailyEligibleUsers).ceil();
  }

  /// Relative lift between two observed rates, as a fraction.
  static double relativeLift(double controlRate, double treatmentRate) {
    if (controlRate <= 0) return 0;
    return (treatmentRate - controlRate) / controlRate;
  }
}

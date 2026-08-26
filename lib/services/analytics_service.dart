import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Spec S1 — Event Registry.
///
/// Every string here is a contract. Renaming one breaks every dashboard,
/// funnel and experiment readout downstream, so treat these as append-only.
class Ev {
  Ev._();

  // ── Lifecycle ────────────────────────────────────────────────────────────
  static const appOpened = 'app_opened';
  static const appBackgrounded = 'app_backgrounded';
  static const errorOccurred = 'error_occurred';

  // ── Onboarding (acquisition → activation) ────────────────────────────────
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingAbandoned = 'onboarding_abandoned';
  static const accountCreated = 'account_created';

  // ── Capture ──────────────────────────────────────────────────────────────
  static const brainDumpOpened = 'brain_dump_opened';
  static const brainDumpTaskAdded = 'brain_dump_task_added';
  static const brainDumpCompleted = 'brain_dump_completed';

  // ── Check-ins ────────────────────────────────────────────────────────────
  static const moodCheckin = 'mood_checkin';
  static const energyCheckin = 'energy_checkin';

  // ── The core loop ────────────────────────────────────────────────────────
  static const aiSelectionTriggered = 'ai_selection_triggered';
  static const aiSelectionCompleted = 'ai_selection_completed';
  static const aiSelectionSkipped = 'ai_selection_skipped';
  static const focusSessionStarted = 'focus_session_started';
  static const focusSessionPaused = 'focus_session_paused';
  static const focusSessionCompleted = 'focus_session_completed';
  static const focusSessionAbandoned = 'focus_session_abandoned';

  /// Added 2026-08-26 (WI-1.2/ADR-005): a session that ended while the
  /// process was dead and was retro-completed at boot. Kept separate from
  /// [focusSessionCompleted] so dashboards can distinguish live completions
  /// from reconciled ones without redefining either.
  static const focusSessionReconciled = 'focus_session_reconciled';
  static const cantFocusTapped = 'cant_focus_tapped';
  static const cantFocusAction = 'cant_focus_action';
  static const hyperfocusDetected = 'hyperfocus_detected';

  // ── Reward loop ──────────────────────────────────────────────────────────
  static const rewardTriggered = 'reward_triggered';
  static const rewardRevealed = 'reward_revealed';
  static const rewardClaimed = 'reward_claimed';
  static const rewardShared = 'reward_shared';

  // ── Tasks ────────────────────────────────────────────────────────────────
  static const taskCreated = 'task_created';
  static const taskCompleted = 'task_completed';
  static const taskArchived = 'task_archived';
  static const taskMovedToSomeday = 'task_moved_to_someday';
  static const taskBreakdownRequested = 'task_breakdown_requested';
  static const somedayListOpened = 'someday_list_opened';
  static const autoPrunePrompted = 'auto_prune_prompted';
  static const honestCheckShown = 'honest_check_shown';
  static const honestCheckCleared = 'honest_check_cleared';

  // ── Social ───────────────────────────────────────────────────────────────
  static const bodyDoubleJoined = 'body_double_joined';
  static const bodyDoubleCheered = 'body_double_cheered';

  // ── Monetization ─────────────────────────────────────────────────────────
  static const paywallShown = 'paywall_shown';
  static const paywallDismissed = 'paywall_dismissed';
  static const paywallConverted = 'paywall_converted';
  static const paywallSuppressed = 'paywall_suppressed';
  static const trialStarted = 'trial_started';
  static const trialExpired = 'trial_expired';
  static const trialConverted = 'trial_converted';
  static const subscriptionCancelled = 'subscription_cancelled';
  static const featureGateHit = 'feature_gate_hit';

  // ── Growth ───────────────────────────────────────────────────────────────
  static const activationReached = 'activation_reached';
  static const habitFormed = 'habit_formed';
  static const shareCardGenerated = 'share_card_generated';
  static const referralInviteSent = 'referral_invite_sent';
  static const dataExported = 'data_exported';
  static const widgetAdded = 'widget_added';
  static const notificationReceived = 'notification_received';
  static const notificationOpened = 'notification_opened';

  // ── Experimentation ──────────────────────────────────────────────────────
  static const experimentExposed = 'experiment_exposed';
}

/// A single tracked interaction. Immutable and JSON-round-trippable so the
/// buffer survives a cold start (ADHD users force-quit apps constantly —
/// losing the buffer would silently bias every funnel toward short sessions).
@immutable
class AnalyticsEvent {
  final String name;
  final Map<String, Object?> props;
  final DateTime timestamp;
  final String sessionId;

  const AnalyticsEvent({
    required this.name,
    required this.props,
    required this.timestamp,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'props': props,
        'ts': timestamp.toIso8601String(),
        'sid': sessionId,
      };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'] as String,
      props: Map<String, Object?>.from(
        (json['props'] as Map?) ?? const <String, Object?>{},
      ),
      timestamp: DateTime.parse(json['ts'] as String),
      sessionId: json['sid'] as String? ?? 'unknown',
    );
  }

  @override
  String toString() => '$name ${jsonEncode(props)}';
}

/// Anything that can receive events: Firebase, Amplitude, PostHog, a test spy.
abstract class AnalyticsSink {
  void record(AnalyticsEvent event);
}

/// Prints to the debug console. Active in debug builds only.
class DebugAnalyticsSink implements AnalyticsSink {
  @override
  void record(AnalyticsEvent event) {
    if (kDebugMode) {
      debugPrint('📊 ${event.name} ${jsonEncode(event.props)}');
    }
  }
}

/// Captures events in memory. The backbone of the widget/unit test suite —
/// assert on funnels, not on pixels.
class InMemoryAnalyticsSink implements AnalyticsSink {
  final List<AnalyticsEvent> events = [];

  @override
  void record(AnalyticsEvent event) => events.add(event);

  List<AnalyticsEvent> named(String name) =>
      events.where((e) => e.name == name).toList();

  int count(String name) => named(name).length;

  bool sawEvent(String name) => count(name) > 0;

  void clear() => events.clear();
}

/// Central instrumentation bus.
///
/// Deliberately dependency-free: no vendor SDK is bolted in here. Attach a
/// vendor [AnalyticsSink] at app start and the whole product becomes
/// measurable without a single screen changing.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static const _bufferKey = 'ekagra_analytics_buffer';
  static const _countersKey = 'ekagra_analytics_counters';
  static const _maxBuffered = 500;

  final List<AnalyticsSink> _sinks = [];
  final List<AnalyticsEvent> _buffer = [];
  Map<String, int> _lifetimeCounts = {};

  String _sessionId = 'boot';
  DateTime? _sessionStartedAt;
  bool _enabled = true;
  bool _loaded = false;

  /// Privacy-first: the user can switch instrumentation off entirely and we
  /// keep functioning. Spec guardrail — no covert tracking.
  bool get enabled => _enabled;
  bool get loaded => _loaded;
  String get sessionId => _sessionId;
  List<AnalyticsEvent> get buffered => List.unmodifiable(_buffer);
  Map<String, int> get lifetimeCounts => Map.unmodifiable(_lifetimeCounts);

  void addSink(AnalyticsSink sink) => _sinks.add(sink);

  void clearSinks() => _sinks.clear();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('ekagra_analytics_enabled') ?? true;

    final rawCounts = prefs.getString(_countersKey);
    if (rawCounts != null) {
      final decoded = jsonDecode(rawCounts) as Map<String, dynamic>;
      _lifetimeCounts = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    final rawBuffer = prefs.getString(_bufferKey);
    if (rawBuffer != null) {
      try {
        final list = jsonDecode(rawBuffer) as List<dynamic>;
        _buffer
          ..clear()
          ..addAll(
            list.map(
              (e) => AnalyticsEvent.fromJson(e as Map<String, dynamic>),
            ),
          );
      } catch (_) {
        // A corrupt buffer must never block app start.
        _buffer.clear();
      }
    }

    _loaded = true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ekagra_analytics_enabled', value);
    if (!value) {
      _buffer.clear();
      await prefs.remove(_bufferKey);
    }
  }

  void startSession(String id) {
    _sessionId = id;
    _sessionStartedAt = DateTime.now();
  }

  Duration get sessionLength => _sessionStartedAt == null
      ? Duration.zero
      : DateTime.now().difference(_sessionStartedAt!);

  /// Fire an event. Never throws — instrumentation must not be able to crash
  /// the product it measures.
  void track(String name, [Map<String, Object?> props = const {}]) {
    if (!_enabled) return;
    try {
      final event = AnalyticsEvent(
        name: name,
        props: props,
        timestamp: DateTime.now(),
        sessionId: _sessionId,
      );

      _buffer.add(event);
      if (_buffer.length > _maxBuffered) {
        _buffer.removeRange(0, _buffer.length - _maxBuffered);
      }
      _lifetimeCounts[name] = (_lifetimeCounts[name] ?? 0) + 1;

      for (final sink in _sinks) {
        sink.record(event);
      }

      unawaited(_persist());
    } catch (_) {
      // Swallow. See above.
    }
  }

  /// How many times this event has ever fired for this install. Powers
  /// trigger logic like "3rd AI pick" without a server round-trip.
  int lifetimeCount(String name) => _lifetimeCounts[name] ?? 0;

  int countSince(String name, DateTime since) => _buffer
      .where((e) => e.name == name && e.timestamp.isAfter(since))
      .length;

  int countToday(String name) {
    final now = DateTime.now();
    return _buffer.where((e) {
      if (e.name != name) return false;
      return e.timestamp.year == now.year &&
          e.timestamp.month == now.month &&
          e.timestamp.day == now.day;
    }).length;
  }

  AnalyticsEvent? lastOf(String name) {
    for (var i = _buffer.length - 1; i >= 0; i--) {
      if (_buffer[i].name == name) return _buffer[i];
    }
    return null;
  }

  /// Conversion rate between two steps of a funnel, 0..1.
  /// Returns 0 when the top of the funnel has no volume (avoids NaN in UI).
  double funnelRate(String from, String to) {
    final top = lifetimeCount(from);
    if (top == 0) return 0;
    return (lifetimeCount(to) / top).clamp(0.0, 1.0);
  }

  Future<void> _persist() async {
    // Defensive: a caller can pass a non-JSON-encodable prop value. That must
    // degrade to "this event is not persisted", never to an unhandled async
    // error that crashes the app or fails an unrelated test.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _bufferKey,
        jsonEncode(_buffer.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(_countersKey, jsonEncode(_lifetimeCounts));
    } catch (_) {
      // Intentionally silent.
    }
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _buffer.clear();
    _lifetimeCounts = {};
    _sinks.clear();
    _enabled = true;
    _sessionId = 'test';
    _sessionStartedAt = DateTime.now();
  }
}

/// Convenience shorthand used across screens: `track(Ev.paywallShown, {...})`.
void track(String name, [Map<String, Object?> props = const {}]) =>
    AnalyticsService.instance.track(name, props);

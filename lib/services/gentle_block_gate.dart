import 'package:flutter/foundation.dart';

import 'feature_flags.dart';

/// WI-5.1 — the pure decision core of Gentle Block.
///
/// Platform-honest: the Android accessibility layer that feeds
/// [onAppOpened] does not exist yet, so nothing calls this gate and
/// `FeatureFlags.gentleBlock` is `unbuilt`. When the native service
/// lands, this is the ONLY decision logic it needs — kept pure so it
/// is fully testable without a device.
class GentleBlockConfig {
  const GentleBlockConfig({
    this.blockedPackages = const [
      'com.instagram.android',
      'com.google.android.youtube',
      'com.zhiliaoapp.musically',
    ],
    this.monkMode = false,
  });

  /// Android package names of the apps the user chose to be paused on.
  /// Defaults are the documented attention sink trio.
  final List<String> blockedPackages;

  /// Roots-style hard lock: when true, the pause screen offers no
  /// break escape for the session duration. Off by default — a wall is
  /// never the default posture (Rules 10/14).
  final bool monkMode;
}

/// Outcome of a foreground-app event during the gate's watch.
enum GentleBlockDecision {
  /// Not in a session, or the app is not on the list — do nothing.
  allow,

  /// Show the calm pause screen with the Return/Break choice.
  pauseWithChoice,

  /// Monk mode: session-length lock, no override offered.
  hardPause,
}

class GentleBlockGate {
  GentleBlockGate({
    required this.config,
    this.enabled = false,
    FeatureMaturity? maturityForTest,
  }) : _maturity = maturityForTest ?? FeatureFlags.gentleBlock;

  /// Only true when the real detection layer is wired AND the feature
  /// flag is live. The gate is otherwise inert by construction.
  final bool enabled;
  final GentleBlockConfig config;
  final FeatureMaturity _maturity;

  bool _sessionActive = false;
  int _sessionEndsAtMs = 0;

  /// Ekagra's own packages are never blocked (would brick the session UI).
  static const _selfPackages = {
    'com.example.ekagra',
    'com.theNishadhraj.ekagra',
  };

  void sessionStarted(int endsAtMs) {
    _sessionActive = true;
    _sessionEndsAtMs = endsAtMs;
  }

  void sessionEnded() {
    _sessionActive = false;
  }

  GentleBlockDecision onAppOpened(String package, int nowMs) {
    if (!enabled) return GentleBlockDecision.allow;
    if (_maturity != FeatureMaturity.live) {
      return GentleBlockDecision.allow;
    }
    if (!_sessionActive || nowMs >= _sessionEndsAtMs) {
      _sessionActive = false;
      return GentleBlockDecision.allow;
    }
    if (_selfPackages.contains(package)) return GentleBlockDecision.allow;
    if (!config.blockedPackages.contains(package)) {
      return GentleBlockDecision.allow;
    }
    return config.monkMode
        ? GentleBlockDecision.hardPause
        : GentleBlockDecision.pauseWithChoice;
  }
}

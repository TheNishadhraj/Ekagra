import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/analytics_service.dart';

/// Crash-safe persistence helpers.
///
/// WHY THIS EXISTS
/// ---------------
/// Every provider used to call `jsonDecode(raw) as List<dynamic>` with no
/// guard, inside a `load()` that `main()` awaits *before* `runApp()`. One
/// malformed record — a partial write during a force-quit, a schema change,
/// an OS-level truncation — and the app throws during startup and never
/// renders. Uninstall is the only user-accessible remedy.
///
/// That is a total-data-loss bug in an app whose entire purpose is holding
/// the thoughts an ADHD user cannot hold themselves. It is also invisible in
/// testing, because test data is always well-formed.
///
/// The policy here is deliberately not "catch and return empty". Silently
/// discarding a user's tasks is the second-worst outcome after crashing.
/// Instead we **quarantine**: the bad payload is copied to a sidecar key so
/// it can be recovered or inspected, the app boots with what it can parse,
/// and the failure is reported.
class SafeStore {
  SafeStore._();

  /// Suffix for quarantined payloads. Kept forever — it is small, and a
  /// user's lost tasks are worth more than a few KB.
  static const quarantineSuffix = '__corrupt';

  /// Decode a persisted JSON list, salvaging as much as possible.
  ///
  /// Parses element-by-element so that one bad record does not discard the
  /// other 200. Returns everything that could be read.
  static List<T> decodeList<T>({
    required String? raw,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    if (raw == null || raw.isEmpty) return <T>[];

    late final List<dynamic> rawList;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _quarantine(key, raw, 'not_a_list');
        return <T>[];
      }
      rawList = decoded;
    } catch (e) {
      // The whole blob is unreadable. Keep it; return empty so the app boots.
      _quarantine(key, raw, 'malformed_json');
      return <T>[];
    }

    final out = <T>[];
    var skipped = 0;
    for (final element in rawList) {
      try {
        if (element is! Map) {
          skipped++;
          continue;
        }
        out.add(fromJson(Map<String, dynamic>.from(element)));
      } catch (_) {
        // One bad record must never cost the user the other good ones.
        skipped++;
      }
    }

    if (skipped > 0) {
      _quarantine(key, raw, 'partial_records');
      track(Ev.errorOccurred, {
        'type': 'store_partial_decode',
        'context': key,
        'recovered': out.length,
        'skipped': skipped,
        'recoverable': true,
      });
      if (kDebugMode) {
        debugPrint('SafeStore: $key recovered ${out.length}, skipped $skipped');
      }
    }

    return out;
  }

  /// Decode a persisted JSON object.
  static Map<String, dynamic>? decodeObject({
    required String? raw,
    required String key,
  }) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _quarantine(key, raw, 'not_an_object');
        return null;
      }
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      _quarantine(key, raw, 'malformed_json');
      return null;
    }
  }

  /// Run a model constructor defensively.
  ///
  /// Model `fromJson` methods use non-null casts and `DateTime.parse`, both
  /// of which throw on unexpected input. Callers get a fallback instead of a
  /// startup crash.
  static T? tryBuild<T>(T Function() build, {required String key}) {
    try {
      return build();
    } catch (e) {
      track(Ev.errorOccurred, {
        'type': 'store_build_failed',
        'context': key,
        'recoverable': true,
      });
      if (kDebugMode) debugPrint('SafeStore: could not build $key — $e');
      return null;
    }
  }

  /// Preserve an unreadable payload so support can recover it later.
  ///
  /// Fire-and-forget: quarantining must never block or fail app startup.
  static void _quarantine(String key, String raw, String reason) {
    track(Ev.errorOccurred, {
      'type': 'store_corrupt',
      'context': key,
      'reason': reason,
      'bytes': raw.length,
      'recoverable': true,
    });

    SharedPreferences.getInstance().then((prefs) {
      // Never overwrite an earlier quarantine — the first failure is usually
      // the one closest to the original good data.
      final target = '$key$quarantineSuffix';
      if (prefs.getString(target) == null) {
        prefs.setString(target, raw);
        prefs.setString(
          '${target}_meta',
          jsonEncode({
            'reason': reason,
            'at': DateTime.now().toIso8601String(),
          }),
        );
      }
    }).catchError((_) => false);

    if (kDebugMode) {
      debugPrint('SafeStore: quarantined "$key" ($reason, ${raw.length}B)');
    }
  }

  /// Whether a quarantined payload exists for [key]. Surfaced in Settings so
  /// a user who lost data can be told the truth and offered a recovery path.
  static Future<bool> hasQuarantine(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$key$quarantineSuffix') != null;
  }

  static Future<String?> readQuarantine(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$key$quarantineSuffix');
  }
}

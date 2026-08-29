import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// Crash capture on the existing analytics seam (WI-2.3, RISK-10).
///
/// Frames (`FlutterError.onError`), platform-dispatcher errors and zone
/// errors are all converted into `Ev.errorOccurred` events — which means
/// they automatically inherit every property the analytics bus already
/// guarantees: the in-app opt-out, the local crash-safe buffer, PII
/// scrubbing at the remote sink, and `kDebugMode` console output.
///
/// What this is NOT: a native crash reporter with symbolication
/// (dSYM/ProGuard mapping, out-of-heap crashes). That is the documented
/// residue in RISK-10 and the vendor brief — swapping in Sentry/Crashlytics
/// later is additive, not a rewrite.
class CrashReporter {
  CrashReporter._();

  static void install() {
    FlutterError.onError = (details) {
      // Still show the error in debug consoles and ErrorWidgets.
      FlutterError.presentError(details);
      track(
        Ev.errorOccurred,
        _payload('flutter_error', details.exception, details.stack),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      track(Ev.errorOccurred, _payload('platform_error', error, stack));
      return true;
    };
  }

  /// Zone errors from `runZonedGuarded` in `main()` land here.
  static void reportZoneError(Object error, StackTrace stack) {
    track(Ev.errorOccurred, _payload('zone_error', error, stack));
  }

  static Map<String, Object?> _payload(
    String type,
    Object error,
    StackTrace? stack,
  ) {
    return {
      'type': type,
      'error': trim(error.toString()),
      'stack': trim(stack?.toString()),
    };
  }

  /// Keep payloads small — the interesting frames are at the top.
  static String trim(String? text, {int maxChars = 2000}) {
    if (text == null) return '';
    return text.length <= maxChars ? text : text.substring(0, maxChars);
  }
}

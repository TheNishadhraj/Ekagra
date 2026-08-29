import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'analytics_service.dart';

/// Dependency-free remote analytics sink (WI-2.3, ADR-009).
///
/// WHY NO SDK
/// -----------
/// The repo treats its 8-dependency footprint as a feature, the analytics
/// bus already defines the `AnalyticsSink` seam, and the PostHog capture
/// API is one JSON POST. A hand-rolled sink keeps the app offline by
/// default, swappable by config, and impossible for a vendor SDK to
/// silently change. If the owner later prefers the vendor SDK (or a
/// different vendor), the swap is this one file.
///
/// HONESTY & PRIVACY PROPERTIES (test-enforced)
/// --------------------------------------------
/// - Respects the in-app opt-out *before* anything is queued: events only
///   reach sinks through `AnalyticsService.track`, which is gated on the
///   user's consent. `setEnabled(false)` also clears the local buffer.
/// - PII never leaves: property keys matching the scrub list are dropped
///   before queueing.
/// - Failures are silent drops, never crashes: analytics must not be able
///   to break the product it measures. The local buffer already preserves
///   events on-device for diagnostics.
class RemoteAnalyticsSink implements AnalyticsSink {
  RemoteAnalyticsSink({
    required Uri endpoint,
    required String apiKey,
    required String distinctId,
    this.sender,
    this.flushInterval = const Duration(seconds: 30),
    this.maxQueue = 40,
  }) : _endpoint = endpoint,
       _apiKey = apiKey,
       _distinctId = distinctId;

  final Uri _endpoint;
  final String _apiKey;
  final String _distinctId;

  /// Injectable transport for tests. Production path uses `HttpClient`.
  final Future<bool> Function(String body)? sender;

  final Duration flushInterval;
  final int maxQueue;

  final List<Map<String, Object?>> _batch = [];
  Timer? _timer;
  bool _closed = false;

  static final RegExp _piiKeys = RegExp(
    'email|name|phone|token|password|address|secret',
    caseSensitive: false,
  );

  /// Drop any property whose key looks like it could carry personal data.
  /// Events are behavioural by design; the pilot protocol requires "zero
  /// PII in event payload" as a tested property, not a promise.
  static Map<String, Object?> scrub(Map<String, Object?> props) {
    return {
      for (final e in props.entries)
        if (!_piiKeys.hasMatch(e.key)) e.key: e.value,
    };
  }

  @override
  void record(AnalyticsEvent event) {
    if (_closed || _apiKey.isEmpty) return;
    _batch.add({
      'event': event.name,
      'distinct_id': _distinctId,
      'properties': scrub(event.props),
      'timestamp': event.timestamp.toIso8601String(),
    });
    if (_batch.length >= maxQueue) {
      flush();
    } else {
      _ensureTimer();
    }
  }

  void _ensureTimer() {
    if (_closed) return;
    _timer ??= Timer(flushInterval, flush);
  }

  /// Ship what is queued. Fire-and-forget by design.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_batch.isEmpty || _apiKey.isEmpty) return;

    final body = jsonEncode({'api_key': _apiKey, 'batch': _batch.toList()});
    _batch.clear();

    try {
      // A silent drop on failure is the correct behaviour here — see the
      // class doc. Retry loops would double-send on timeout.
      await (sender?.call(body) ?? _post(body));
    } catch (_) {
      // Never let analytics throw.
    }
  }

  Future<bool> _post(String body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(_endpoint);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.contentLengthHeader, body.length);
      request.write(body);
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode >= 200 && response.statusCode < 300;
    } finally {
      client.close();
    }
  }

  /// Flush and stop. Called on app detach.
  Future<void> dispose() async {
    _closed = true;
    await flush();
  }
}

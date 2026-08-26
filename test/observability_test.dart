import 'dart:convert';

import 'package:ekagra/services/analytics_service.dart';
import 'package:ekagra/services/crash_reporting.dart';
import 'package:ekagra/services/remote_analytics_sink.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WI-2.3 — observability acceptance, encoded:
/// - a "crash" reaches the bus (and would reach a configured dashboard);
/// - opt-out produces ZERO remote events after the toggle;
/// - no PII key ever appears in a shipped payload;
/// - the sink is inert while unconfigured (offline-by-default build).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AnalyticsService.instance.resetForTest();
  });

  late List<String> shipped;
  RemoteAnalyticsSink makeSink({String key = 'phc_test_key'}) {
    shipped = [];
    return RemoteAnalyticsSink(
      endpoint: Uri.parse('https://example.invalid/batch/'),
      apiKey: key,
      distinctId: 'install-123',
      sender: (body) async {
        shipped.add(body);
        return true;
      },
      maxQueue: 1, // flush immediately on every event
    );
  }

  test('events reach the sink as one JSON batch per flush', () {
    final sink = makeSink();
    sink.record(
      AnalyticsEvent(
        name: 'test_event',
        props: const {'flavour': 'shame-free'},
        timestamp: DateTime(2026, 8, 26),
        sessionId: 's1',
      ),
    );

    expect(shipped.length, 1, reason: 'maxQueue=1 flushes immediately');
    final body = jsonDecode(shipped.single) as Map<String, dynamic>;
    expect(body['api_key'], 'phc_test_key');
    final batch = (body['batch'] as List).single as Map<String, dynamic>;
    expect(batch['event'], 'test_event');
    expect(batch['distinct_id'], 'install-123');
    expect((batch['properties'] as Map)['flavour'], 'shame-free');
  });

  test('the sink is inert while unconfigured (empty key)', () {
    final sink = makeSink(key: '');
    sink.record(
      AnalyticsEvent(
        name: 'anything',
        props: const {},
        timestamp: DateTime.now(),
        sessionId: 's',
      ),
    );
    // No timer armed, nothing queued, nothing shipped.
    expect(shipped, isEmpty);
  });

  test('PII keys are scrubbed before anything can leave', () {
    final scrubbed = RemoteAnalyticsSink.scrub({
      'email': 'user@example.com',
      'display_name': 'Nishadh',
      'phone': '+91...',
      'auth_token': 'x',
      'level': 'high',
      'source': 'brain_dump',
    });
    expect(scrubbed.containsKey('email'), isFalse);
    expect(scrubbed.containsKey('display_name'), isFalse);
    expect(scrubbed.containsKey('phone'), isFalse);
    expect(scrubbed.containsKey('auth_token'), isFalse);
    expect(scrubbed['level'], 'high');
    expect(scrubbed['source'], 'brain_dump');

    // End to end: a tracked PII-ish prop never appears in the shipped body.
    final sink = makeSink();
    sink.record(
      AnalyticsEvent(
        name: 'e',
        props: {'email': 'secret@example.com'},
        timestamp: DateTime.now(),
        sessionId: 's',
      ),
    );
    expect(shipped.single.contains('secret@example.com'), isFalse);
  });

  test('opt-out stops all remote events, and stays stopped', () async {
    final analytics = AnalyticsService.instance;
    analytics.addSink(makeSink());
    expect(analytics.enabled, isTrue, reason: 'default is opt-in-enabled');

    analytics.track('before_opt_out');
    expect(shipped.length, 1);

    await analytics.setEnabled(false);
    analytics.track('after_opt_out_1');
    analytics.track('after_opt_out_2');
    expect(shipped.length, 1, reason: 'zero events after the toggle');

    // The local buffer is cleared too — nothing lingers to ship later.
    expect(analytics.buffered.where((e) => e.name.startsWith('after_')),
        isEmpty);
  });

  test('a framework error reaches the bus as errorOccurred', () {
    final spy = InMemoryAnalyticsSink();
    AnalyticsService.instance.addSink(spy);

    CrashReporter.install();
    // Simulate what the framework does on a widget build exception.
    final original = FlutterError.onError;
    FlutterError.onError?.call(
      FlutterErrorDetails(
        exception: StateError('a widget exploded in a test'),
        stack: StackTrace.current,
        library: 'test',
      ),
    );
    FlutterError.onError = original;

    final errors = spy.named(Ev.errorOccurred);
    expect(errors, isNotEmpty);
    expect(errors.first.props['type'], 'flutter_error');
    expect(errors.first.props['error'], contains('exploded'));
  });

  test('zone errors are captured and payload-sized', () {
    final spy = InMemoryAnalyticsSink();
    AnalyticsService.instance.addSink(spy);

    CrashReporter.reportZoneError(
      StateError('boom'),
      StackTrace.current,
    );
    expect(spy.named(Ev.errorOccurred).single.props['type'], 'zone_error');

    final huge = 'x' * 5000;
    expect(CrashReporter.trim(huge).length, 2000);
    expect(CrashReporter.trim(null), '');
  });
}

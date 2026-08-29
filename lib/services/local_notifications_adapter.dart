import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The ONLY file that touches the notifications plugin.
///
/// Everything the nudge engine needs is behind this narrow interface so
/// that (a) tests inject a fake and never touch platform channels, and
/// (b) if the plugin's API drifts across major versions, the fix is one
/// file. Every method fails soft and returns false rather than throwing:
/// notifications are a courtesy layer, never a crash path — an app for
/// ADHD users that crashed because a reminder could not be scheduled
/// would be a very expensive joke.
abstract class LocalNotificationsAdapter {
  Future<bool> initialize(void Function(String payload)? onTap);
  Future<bool> requestPermission();
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
    bool daily = false,
  });
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
  Future<bool> cancel(int id);
  Future<bool> cancelAll();
}

/// Honest inert fallback: nothing is scheduled, nothing pretends to be.
class NoopNotificationsAdapter implements LocalNotificationsAdapter {
  @override
  Future<bool> initialize(void Function(String payload)? onTap) async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
    bool daily = false,
  }) async => false;

  @override
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async => false;

  @override
  Future<bool> cancel(int id) async => false;

  @override
  Future<bool> cancelAll() async => false;
}

/// flutter_local_notifications-backed implementation.
///
/// Deliberately uses **inexact** scheduling (`inexactAllowWhileIdle`):
/// nudges are gentle by brand, they do not promise second precision, and
/// inexact alarms avoid the Android exact-alarm permission wall entirely
/// (RISK-16 documents the trade).
class FlutterLocalNotificationsAdapter implements LocalNotificationsAdapter {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _timezonesReady = false;

  @override
  Future<bool> initialize(void Function(String payload)? onTap) async {
    try {
      if (!_timezonesReady) {
        tzdata.initializeTimeZones();
        _timezonesReady = true;
      }
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      final ok = await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onTap?.call(payload);
          }
        },
      );
      return ok ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('notifications: initialize failed: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      var granted = false;
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        granted = await android.requestPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        granted =
            await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            granted;
      }
      return granted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
    bool daily = false,
  }) async {
    try {
      if (!_timezonesReady) {
        tzdata.initializeTimeZones();
        _timezonesReady = true;
      }
      final when = at.isAfter(DateTime.now())
          ? at
          : DateTime.now().add(const Duration(minutes: 1));
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: daily ? DateTimeComponents.time : null,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('notifications: schedule $id failed: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.show(id, title, body, _details(), payload: payload);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> cancel(int id) async {
    try {
      await _plugin.cancel(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> cancelAll() async {
    try {
      await _plugin.cancelAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      'ekagra_nudges',
      'Gentle nudges',
      channelDescription:
          'A few soft reminders a day. Firm without guilt — and they give '
          'up gracefully after three tries.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmService {
  AlarmService._();

  static final AlarmService instance = AlarmService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'alarm_channel';
  static const String _channelName = 'Alarm Notifications';
  static const String _channelDescription =
      'Channel for scheduled alarm notifications';

  bool get _supportsLocalNotifications {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (!_supportsLocalNotifications) {
      return;
    }

    try {
      const AndroidInitializationSettings androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: DarwinInitializationSettings(),
      );

      final bool? initialized = await _notifications.initialize(initSettings);
      if (initialized != true) {
        throw Exception('Failed to initialize local notifications plugin.');
      }

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );

        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (error) {
      if (error is MissingPluginException ||
          error.toString().contains('LateInitializationError')) {
        return;
      }
      rethrow;
    }
  }

  Future<void> scheduleAlarm({
    required int id,
    required DateTime scheduledDateTime,
    required String title,
    required String body,
  }) async {
    if (!_supportsLocalNotifications) {
      return;
    }

    final tz.TZDateTime scheduledAt = tz.TZDateTime.from(
      scheduledDateTime,
      tz.local,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAlarm(int id) async {
    if (!_supportsLocalNotifications) {
      return;
    }
    await _notifications.cancel(id);
  }
}

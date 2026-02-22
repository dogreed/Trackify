import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings, // ✅ REQUIRED in v20
    );

    // Android 13+ permission
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder() async {
    await _notifications.zonedSchedule(
      id: 0,
      title: 'Trackify Reminder',
      body: 'Don’t forget to update your expense log today.',
      scheduledDate: _nextInstanceOf7PM(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminder',
          channelDescription: 'Daily expense reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf7PM() {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 56);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
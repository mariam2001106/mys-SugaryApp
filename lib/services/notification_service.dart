import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mysugaryapp/models/reminder_models.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationsService {
  // Singleton pattern
  static final NotificationsService _instance = NotificationsService._internal();
  
  factory NotificationsService() {
    return _instance;
  }
  
  NotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Initialize timezone database for zoned scheduling
    tzdata.initializeTimeZones();
    // Set the local timezone location - critical for tz.local to work
    // We use the device's local timezone offset to find the best matching timezone
    final currentLocation = DateTime.now().timeZoneOffset;
    final timeZoneName = currentLocation.isNegative 
        ? 'Etc/GMT+${currentLocation.inHours.abs()}'
        : 'Etc/GMT-${currentLocation.inHours}';
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback to UTC if timezone not found
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    
    _isInitialized = true;
  }

  /// Schedule reminder using exact alarms to ensure notifications fire at the specified time.
  Future<void> scheduleReminder(ReminderItemDto reminder) async {
    // Ensure the service is initialized
    await init();
    
    if (!reminder.enabled) return;

    final parts = reminder.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final id = reminder.id.hashCode;

    final now = DateTime.now();
    var base = DateTime(now.year, now.month, now.day, hour, minute);
    if (base.isBefore(now)) base = base.add(const Duration(days: 1));

    final tzBase = tz.TZDateTime.from(base, tz.local);
    final title = reminder.title;
    final body = 'Reminder at ${reminder.time}';

    switch (reminder.frequency) {
      case ReminderFrequency.daily:
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzBase,
          _details(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        break;
      case ReminderFrequency.weekly:
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzBase,
          _details(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        break;
      case ReminderFrequency.monthly:
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzBase,
          _details(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        break;
    }
  }

  Future<void> cancelReminder(ReminderItemDto reminder) async {
    // Ensure the service is initialized
    await init();
    await _plugin.cancel(reminder.id.hashCode);
  }

  Future<void> cancelReminderById(String id) async {
    // Ensure the service is initialized
    await init();
    await _plugin.cancel(id.hashCode);
  }

  Future<void> rescheduleAll(List<ReminderItemDto> reminders) async {
    // Ensure the service is initialized once before rescheduling all
    await init();
    for (final r in reminders) {
      if (r.enabled) {
        await scheduleReminder(r);
      }
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
  }
}

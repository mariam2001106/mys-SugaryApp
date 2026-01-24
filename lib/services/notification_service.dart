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
    // Set tz.local to UTC as a reference timezone
    // DateTime objects are created in device's local time and converted using tz.TZDateTime.from()
    // which preserves the actual moment in time for notification scheduling
    tz.setLocalLocation(tz.getLocation('UTC'));
    
    _isInitialized = true;
  }

  /// Schedule reminder using exact alarms to ensure notifications fire at the specified time.
  Future<void> scheduleReminder(ReminderItemDto reminder) async {
    // Ensure the service is initialized
    await init();
    
    if (!reminder.enabled) return;

    // Validate time format
    final parts = reminder.time.split(':');
    if (parts.length != 2) {
      debugPrint('Invalid time format for reminder ${reminder.id}: ${reminder.time}');
      return;
    }
    
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      debugPrint('Invalid time values for reminder ${reminder.id}: hour=$hour, minute=$minute');
      return;
    }
    
    final id = reminder.id.hashCode;

    // Create scheduled time using local DateTime first
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If the scheduled time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // Convert to TZDateTime in UTC timezone (the local DateTime already has correct local time)
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final title = reminder.title;
    final body = 'Reminder at ${reminder.time}';

    switch (reminder.frequency) {
      case ReminderFrequency.daily:
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
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
          tzScheduledDate,
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
          tzScheduledDate,
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

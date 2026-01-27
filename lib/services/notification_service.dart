import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mysugaryapp/models/reminder_models.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationsService {
  // Singleton pattern
  static final NotificationsService _instance =
      NotificationsService._internal();

  factory NotificationsService() {
    return _instance;
  }

  NotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Request notification permissions
    final notificationPermission = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    debugPrint('Notification permission granted: $notificationPermission');

    // Request exact alarm permissions (Android 12+ / API 31+)
    final exactAlarmPermission = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
    debugPrint('Exact alarm permission granted: $exactAlarmPermission');

    // Check if we can schedule exact alarms
    final canScheduleExactAlarms = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.canScheduleExactNotifications();
    debugPrint('Can schedule exact alarms: $canScheduleExactAlarms');

    if (canScheduleExactAlarms == false) {
      debugPrint(
        '⚠️ WARNING: Cannot schedule exact alarms. User must enable this in settings.',
      );
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'reminders',
      'Reminders',
      description: 'Notifications for scheduled reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
    debugPrint('Notification channel created: reminders');

    // Initialize timezone database for zoned scheduling
    tzdata.initializeTimeZones();

    // Get the device's timezone offset and set tz.local accordingly
    final deviceOffset = DateTime.now().timeZoneOffset;
    final offsetHours = deviceOffset.inHours;
    final offsetMinutes = deviceOffset.inMinutes.remainder(60);

    // Try to find a timezone that matches the device offset
    // Common timezone patterns based on offset
    String timezoneName;
    try {
      // For whole hour offsets, try standard timezone names
      if (offsetMinutes == 0) {
        // Try common timezone names based on offset
        if (offsetHours >= -12 && offsetHours <= 14) {
          // Use Etc/GMT notation (note: signs are inverted in Etc/GMT)
          // UTC+2 is Etc/GMT-2
          timezoneName = offsetHours <= 0
              ? 'Etc/GMT+${offsetHours.abs()}'
              : 'Etc/GMT-$offsetHours';
          tz.setLocalLocation(tz.getLocation(timezoneName));
          debugPrint('Timezone set to: $timezoneName (offset: $deviceOffset)');
        } else {
          // Fallback to UTC if offset is out of range
          tz.setLocalLocation(tz.getLocation('UTC'));
          debugPrint('Timezone offset out of range, using UTC');
        }
      } else {
        // For fractional offsets, fall back to UTC
        tz.setLocalLocation(tz.getLocation('UTC'));
        debugPrint('Fractional timezone offset detected, using UTC');
      }
    } catch (e) {
      // If timezone lookup fails, use UTC as fallback
      tz.setLocalLocation(tz.getLocation('UTC'));
      debugPrint('Timezone lookup failed, using UTC. Error: $e');
    }

    debugPrint('Final tz.local: ${tz.local.name}');
    debugPrint('NotificationsService initialized successfully');

    _isInitialized = true;
  }

  /// Schedule reminder using inexact modes (battery-friendly) based on frequency.
  Future<void> scheduleReminder(ReminderItemDto reminder) async {
    await init();

    if (!reminder.enabled) return;

    debugPrint('=== Scheduling Reminder ===');
    debugPrint('ID: ${reminder.id}');
    debugPrint('Title: ${reminder.title}');
    debugPrint('Time: ${reminder.time}');
    debugPrint('Enabled: ${reminder.enabled}');
    debugPrint('Frequency: ${reminder.frequency}');

    final parts = reminder.time.split(':');
    if (parts.length != 2) {
      debugPrint(
        'Invalid time format for reminder ${reminder.id}: ${reminder.time}',
      );
      return;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      debugPrint(
        'Invalid time values for reminder ${reminder.id}: hour=$hour, minute=$minute',
      );
      return;
    }

    final id = reminder.id.hashCode;
    debugPrint('Notification ID (hashCode): $id');

    // Get current time and create scheduled time directly as TZDateTime in local timezone
    final now = tz.TZDateTime.now(tz.local);
    debugPrint('Current time (TZ): $now');
    debugPrint('Local timezone: ${now.location.name}');

    // Create the scheduled time for today
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    debugPrint('Initial scheduled date (TZ): $scheduledDate');

    // If the scheduled time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      debugPrint(
        'Time has passed, rescheduled for tomorrow (TZ): $scheduledDate',
      );
    }

    debugPrint('Final TZDateTime scheduled date: $scheduledDate');
    debugPrint('TZDateTime location: ${scheduledDate.location}');
    debugPrint('TZDateTime timezone: ${scheduledDate.timeZoneName}');

    final title = reminder.title;
    final body = 'Reminder at ${reminder.time}';

    try {
      switch (reminder.frequency) {
        case ReminderFrequency.daily:
          // For daily reminders, schedule with exact mode
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            _details(),
            androidScheduleMode: AndroidScheduleMode.exact,
          );
          debugPrint(
            '✓ Daily notification scheduled successfully (using exact mode)',
          );
          debugPrint('  Will fire at: $scheduledDate');
          break;
        case ReminderFrequency.weekly:
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            _details(),
            androidScheduleMode: AndroidScheduleMode.exact,
          );
          debugPrint(
            '✓ Weekly notification scheduled successfully (using exact mode)',
          );
          debugPrint('  Will fire at: $scheduledDate');
          break;
        case ReminderFrequency.monthly:
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            _details(),
            androidScheduleMode: AndroidScheduleMode.exact,
          );
          debugPrint(
            '✓ Monthly notification scheduled successfully (using exact mode)',
          );
          debugPrint('  Will fire at: $scheduledDate');
          break;
      }
      debugPrint('=== Scheduling Complete ===\n');

      // Get pending notifications for debugging
      await getPendingNotifications();
    } catch (e, stackTrace) {
      debugPrint('✗ ERROR scheduling notification: $e');
      debugPrint('Stack trace: $stackTrace');
      // Rethrow so calling code can handle the error
      rethrow;
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

  /// Show an immediate test notification to verify the notification system works
  Future<void> showTestNotification() async {
    await init();
    await _plugin.show(
      999,
      'Test Notification',
      'If you see this, notifications are working!',
      _details(),
    );
    debugPrint('Test notification shown');
  }

  /// Check if exact alarms can be scheduled
  Future<bool> canScheduleExactAlarms() async {
    await init();
    final canSchedule = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.canScheduleExactNotifications();
    return canSchedule ?? false;
  }

  /// Get list of pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('Pending notifications count: ${pending.length}');
    for (final p in pending) {
      debugPrint('  - ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
    }
    return pending;
  }
}

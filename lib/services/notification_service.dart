import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mysugaryapp/models/reminder_models.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Handles all local notification scheduling/canceling for reminders (Android-only).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initializes the local notifications plugin, time zones, and Android permissions.
  Future<void> init() async {
    if (_initialized) return;

    // Timezone setup (uses device local zone from the tz database).
    tzdata.initializeTimeZones();
    // Set the local timezone explicitly - this is critical for scheduling to work
    final locationName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      // Fallback to UTC if the timezone name is not found
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        //TODO: navigate to reminders screen using navigatorKey if desired.
      },
    );

    // Android 13+ notification permission.
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      
      // Request exact alarm permission for Android 12+ (API 31+)
      // This is critical for scheduled notifications to work
      await androidImpl.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  /// Generates a stable integer ID for a reminder, used by the scheduler.
  int _idForReminder(ReminderItemDto r) => r.id.hashCode & 0x7fffffff;

  /// Schedules a daily notification at the reminder’s time if it’s enabled.
  Future<void> scheduleReminder(ReminderItemDto r) async {
    if (!_initialized) return;
    if (!r.enabled) return;

    final parts = r.time.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idForReminder(r),
      r.title,
      '${r.frequency} • ${r.time}',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Reminders',
          channelDescription: 'Time-based reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      payload: r.id,
    );
  }

  /// Cancels a scheduled notification for the given reminder.
  Future<void> cancelReminder(ReminderItemDto r) async {
    if (!_initialized) return;
    await _plugin.cancel(_idForReminder(r));
  }

  /// Cancels all notifications, then re-schedules all enabled reminders.
  Future<void> rescheduleAll(List<ReminderItemDto> reminders) async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    for (final r in reminders.where((e) => e.enabled)) {
      await scheduleReminder(r);
    }
  }
}
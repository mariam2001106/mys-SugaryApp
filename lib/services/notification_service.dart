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

  // Common timezone locations for efficient lookup when device has non-standard offset
  // Covers major regions globally for better timezone detection
  static const _commonTimezoneLocations = [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Sao_Paulo',
    'Europe/London',
    'Europe/Paris',
    'Africa/Cairo',
    'Asia/Dubai',
    'Asia/Kolkata',
    'Asia/Shanghai',
    'Asia/Tokyo',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];

  /// Initializes the local notifications plugin, time zones, and Android permissions.
  Future<void> init() async {
    if (_initialized) return;

    // Timezone setup (uses device local zone from the tz database).
    tzdata.initializeTimeZones();
    
    // Set the local timezone explicitly - this is critical for scheduling to work
    // Use the device's current timezone offset to find the appropriate location
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    
    try {
      final offsetHours = offset.inHours;
      // Get absolute minutes component (e.g., -330 min -> 30 min, 270 min -> 30 min)
      // We only use this to check if it's a whole hour offset
      final offsetMinutes = offset.inMinutes.abs() % 60;
      
      if (offsetHours == 0 && offsetMinutes == 0) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } else if (offsetMinutes == 0) {
        // Simple hour offset - use Etc/GMT timezone
        _setTimezoneFromHourOffset(offsetHours);
      } else {
        // For complex offsets with minutes, find a matching location
        // Look through common timezone locations first (more efficient)
        tz.Location? matchingLocation;
        for (final locationName in _commonTimezoneLocations) {
          try {
            final location = tz.getLocation(locationName);
            final time = tz.TZDateTime.now(location);
            if (time.timeZoneOffset == offset) {
              matchingLocation = location;
              break;
            }
          } catch (_) {
            continue;
          }
        }
        
        if (matchingLocation != null) {
          tz.setLocalLocation(matchingLocation);
        } else {
          // Fallback to nearest hour offset
          _setTimezoneFromHourOffset(offsetHours);
        }
      }
    } catch (e) {
      // Ultimate fallback: use UTC
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

  // Helper method to set timezone from hour offset using Etc/GMT notation
  // Note: Etc/GMT timezones have reversed signs from standard notation:
  // - Etc/GMT+X represents UTC-X (west of GMT)
  // - Etc/GMT-X represents UTC+X (east of GMT)
  // offsetHours: The timezone offset in hours from UTC (e.g., +5 for UTC+5)
  void _setTimezoneFromHourOffset(int offsetHours) {
    if (offsetHours > 0) {
      tz.setLocalLocation(tz.getLocation('Etc/GMT-$offsetHours'));
    } else if (offsetHours < 0) {
      tz.setLocalLocation(tz.getLocation('Etc/GMT+${-offsetHours}'));
    } else {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
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
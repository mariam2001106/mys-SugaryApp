import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mysugaryapp/models/reminder_models.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import '../main.dart'; // for navigatorKey

/// Handles all local notification scheduling/canceling for reminders (Android-only).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initializes the local notifications plugin, time zones, and Android permissions.
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Timezone setup (uses device local zone from the tz database).
      tzdata.initializeTimeZones();
      
      // Explicitly set the local timezone
      // This ensures notifications are scheduled correctly based on device timezone
      try {
        // Try to get the local timezone from the tz package
        final location = tz.local;
        tz.setLocalLocation(location);
        debugPrint('[NotificationService] Timezone set to: ${location.name}');
      } catch (e) {
        // If that fails, try using the device timezone name
        try {
          final String timeZoneName = DateTime.now().timeZoneName;
          tz.setLocalLocation(tz.getLocation(timeZoneName));
          debugPrint('[NotificationService] Timezone set to: $timeZoneName');
        } catch (e2) {
          // Last resort: fallback to UTC
          debugPrint('[NotificationService] Could not determine local timezone, falling back to UTC: $e2');
          tz.setLocalLocation(tz.UTC);
        }
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (resp) {
          // When tapped, open the reminders UI
          navigatorKey.currentState?.pushNamed(
            '/remainders',
            arguments: {'title': resp.payload},
          );
        },
      );

      // Android 13+ notification permission.
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      // Request exact alarm permission for Android 12+
      // This is CRITICAL for timed notifications to work properly
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();

      _initialized = true;
      debugPrint('[NotificationService] Initialization complete');
    } catch (e) {
      debugPrint('[NotificationService] Error initializing: $e');
      rethrow;
    }
  }

  /// Test notification ID - reserved to avoid conflicts with reminder IDs
  static const int _testNotificationId = 999999;

  /// Generates a stable integer ID for a reminder.
  int _idForReminder(ReminderItemDto r) => r.id.hashCode & 0x7fffffff;

  /// Immediate notification (for testing).
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Reminders',
          channelDescription: 'Time-based reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: title,
    );
  }

  /// Schedules a daily notification at the reminder’s time if it’s enabled.
  Future<void> scheduleReminder(ReminderItemDto r) async {
    print(
      '[ReminderDebug] title=${r.title} time=${r.time} enabled=${r.enabled}',
    );
    if (!_initialized) return;
    if (!r.enabled) return;

    final parts = r.time.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    print(
      '[NotificationService] scheduling id=${_idForReminder(r)} at $scheduled',
    );

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
          playSound: true,
          enableVibration: true,
          enableLights: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      // CRITICAL: Use exactAllowWhileIdle for precise timing
      // inexactAllowWhileIdle causes delays and batching
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      payload: r.title,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a scheduled notification for the given reminder.
  Future<void> cancelReminder(ReminderItemDto r) async {
    print('[NotificationService] cancel ${r.id}');
    if (!_initialized) return;
    await _plugin.cancel(_idForReminder(r));
  }

  /// Cancels all notifications, then re-schedules all enabled reminders.
  Future<void> rescheduleAll(List<ReminderItemDto> reminders) async {
    print('[NotificationService] rescheduleAll incoming=${reminders.length}');
    if (!_initialized) return;
    await _plugin.cancelAll();
    for (final r in reminders.where((e) => e.enabled)) {
      await scheduleReminder(r);
    }
  }

  /// Quick test: schedule a notification in [seconds] from now (one-time).
  Future<void> scheduleTestInSeconds({
    required String title,
    required String body,
    required int seconds,
  }) async {
    if (!_initialized) return;
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(Duration(seconds: seconds));
    debugPrint('[NotificationService] test schedule in $seconds sec at $scheduled');
    await _plugin.zonedSchedule(
      _testNotificationId,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Reminders',
          channelDescription: 'Time-based reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      // Use exact scheduling for tests too
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: title,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Gets the list of all pending notification requests (for debugging).
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) return [];
    return await _plugin.pendingNotificationRequests();
  }

  /// Checks if exact alarms permission is granted (Android 12+).
  Future<bool?> canScheduleExactAlarms() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.canScheduleExactNotifications();
  }
}

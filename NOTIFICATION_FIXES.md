# Notification Fixes for Background/Closed App Delivery

## Changes Made

This document describes the changes made to ensure local notifications are delivered even when the app is in the background or closed.

### 1. Android Permissions (AndroidManifest.xml)

Added the following critical permissions:

- `USE_EXACT_ALARM` - Required for Android 12+ to schedule exact alarms
- `RECEIVE_BOOT_COMPLETED` - Allows rescheduling notifications after device reboot
- `WAKE_LOCK` - Ensures device wakes up to deliver notifications
- `VIBRATE` - Allows notifications to vibrate the device

### 2. Broadcast Receivers (AndroidManifest.xml)

Added two broadcast receivers from the flutter_local_notifications plugin:

- `ScheduledNotificationBootReceiver` - Reschedules all notifications after device boot or app update
- `ScheduledNotificationReceiver` - Handles the actual notification delivery

These receivers ensure notifications persist across app restarts and device reboots.

### 3. NotificationService Improvements (lib/services/notification_service.dart)

#### Timezone Handling
- Explicitly sets the local timezone using `tz.setLocalLocation()`
- Falls back to UTC if timezone cannot be determined
- This ensures notifications fire at the correct local time

#### Permission Requests
- Added `requestExactAlarmsPermission()` for Android 12+ devices
- This prompts the user to allow exact alarm scheduling

#### Enhanced Notification Details
The notification configuration now includes:
- `playSound: true` - Plays notification sound
- `enableVibration: true` - Vibrates when notification appears
- `enableLights: true` - Shows LED notification light (if available)
- `visibility: NotificationVisibility.public` - Shows notification on lock screen
- `ongoing: false` - Notification can be dismissed
- `autoCancel: true` - Notification dismisses when tapped
- `uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime` - Ensures correct time interpretation

#### Debugging Methods
Added helper methods:
- `getPendingNotifications()` - Returns list of all scheduled notifications
- `canScheduleExactAlarms()` - Checks if exact alarm permission is granted

## How to Test

### 1. Install the Updated App
```bash
flutter clean
flutter pub get
flutter run
```

### 2. Test Scenarios

#### Scenario A: App in Background
1. Open the app and create a reminder for 2 minutes from now
2. Press the home button (app goes to background)
3. Wait for the scheduled time
4. **Expected**: Notification should appear even though app is in background

#### Scenario B: App Completely Closed
1. Open the app and create a reminder for 2 minutes from now
2. Swipe away the app from recent apps (force close)
3. Wait for the scheduled time
4. **Expected**: Notification should still appear

#### Scenario C: After Device Reboot
1. Create a reminder for a future time
2. Reboot the device
3. Wait for the scheduled time (without opening the app)
4. **Expected**: Notification should appear (notifications are rescheduled on boot)

### 3. Checking Permissions

On Android 12+ devices, the app will request exact alarm permissions when first initialized. If the user denies this:

1. Go to Settings > Apps > Sugary
2. Look for "Alarms & reminders" permission
3. Enable "Allow setting alarms and reminders"

### 4. Debugging

To check if notifications are properly scheduled, you can add debug logging:

```dart
// In RemindersScreen after scheduling a reminder:
final pending = await NotificationService.instance.getPendingNotifications();
print('Pending notifications: ${pending.length}');
for (final p in pending) {
  print('ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
}
```

## Common Issues and Solutions

### Issue: Notifications Not Appearing
**Solutions:**
1. Check if notification permissions are granted (Android 13+)
2. Check if exact alarm permissions are granted (Android 12+)
3. Verify the app is not in battery optimization mode
4. Check system notification settings for the app

### Issue: Notifications Appear Late
**Solution:** 
- Ensure exact alarm permissions are granted
- Check if device has battery saving modes enabled that delay notifications

### Issue: Notifications Not Rescheduled After Reboot
**Solution:**
- Verify `RECEIVE_BOOT_COMPLETED` permission is in manifest
- Check if the boot receiver is properly registered
- Ensure the app has been opened at least once after installation

## Technical Details

### Why `exactAllowWhileIdle`?

The `AndroidScheduleMode.exactAllowWhileIdle` mode is crucial because:
- It allows notifications to fire at exact times even in Doze mode
- It wakes the device if needed to deliver the notification
- It's designed for time-critical notifications like alarms and reminders

### Notification Channel

The app uses a single notification channel:
- **ID**: `reminders_channel`
- **Name**: Reminders
- **Importance**: Max (shows as heads-up notification)
- **Priority**: High

This ensures notifications are prominent and not suppressed by the system.

## References

- [flutter_local_notifications documentation](https://pub.dev/packages/flutter_local_notifications)
- [Android notification best practices](https://developer.android.com/develop/ui/views/notifications)
- [Android exact alarms](https://developer.android.com/about/versions/12/behavior-changes-12#exact-alarm-permission)

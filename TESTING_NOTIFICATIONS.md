# Timed Notifications Testing and Troubleshooting Guide

## What Was Fixed

The timed notifications were not working due to several critical issues that have been fixed:

### 1. ❌ **Wrong Scheduling Mode (CRITICAL)**
   - **Problem**: Code was using `AndroidScheduleMode.inexactAllowWhileIdle`
   - **Impact**: System could delay or batch notifications, causing them not to fire at exact times
   - **Fix**: Changed to `AndroidScheduleMode.exactAllowWhileIdle` for precise timing
   
### 2. ❌ **Missing Timezone Configuration**
   - **Problem**: Timezone was not explicitly set after initialization
   - **Impact**: Notifications could fire at wrong times if timezone detection failed
   - **Fix**: Added 3-level fallback timezone setting with logging

### 3. ❌ **Missing Permission Request**
   - **Problem**: Not requesting exact alarm permission (Android 12+)
   - **Impact**: Without this permission, exact alarms won't work on newer devices
   - **Fix**: Restored `requestExactAlarmsPermission()` call

### 4. ❌ **Insufficient Logging**
   - **Problem**: Limited debug output made troubleshooting difficult
   - **Impact**: Hard to diagnose scheduling issues
   - **Fix**: Added comprehensive `debugPrint` statements throughout

## How to Test Notifications

### Step 1: Build and Install
```bash
flutter clean
flutter pub get
flutter run --release
```

**Important**: Test in **release mode** or on a **physical device** for accurate results. Debug mode may have different behavior.

### Step 2: Grant Permissions

When you first open the app, you'll see permission requests:

1. **Notification Permission** (Android 13+)
   - Tap "Allow" when prompted
   
2. **Exact Alarm Permission** (Android 12+)
   - Tap "Allow" when prompted
   - Or go to Settings → Apps → Sugary → "Alarms & reminders" → Enable

### Step 3: Check Logs

Connect your device via USB and run:
```bash
adb logcat | grep NotificationService
```

You should see logs like:
```
[NotificationService] Timezone set to: America/New_York
[NotificationService] Initialization complete
[NotificationService] scheduleReminder: title=Take Medication time=14:30 enabled=true
[NotificationService] Scheduling notification id=123456 at 2026-01-29 14:30:00...
[NotificationService] Notification scheduled successfully
```

### Step 4: Test Immediate Notification

In your app, if there's a "Test" button, tap it. This should show a notification immediately.

**Expected behavior**: You should see a notification pop up within 5-10 seconds.

### Step 5: Test Timed Notification

1. Create a new reminder
2. Set the time to **2-3 minutes from now**
3. Make sure it's enabled (toggle switch should be ON)
4. Wait for the scheduled time

**Expected behavior**: 
- Notification should appear at the exact scheduled time
- Should work even if:
  - App is in background
  - App is completely closed
  - Screen is locked

### Step 6: Verify Scheduling

You can check pending notifications programmatically by adding debug code:

```dart
// In your reminders screen after scheduling:
final pending = await NotificationService.instance.getPendingNotifications();
debugPrint('Pending notifications: ${pending.length}');
for (final p in pending) {
  debugPrint('  ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
}
```

Or check via ADB:
```bash
adb shell dumpsys notification
```

## Common Issues and Solutions

### Issue 1: Notifications Not Appearing at All

**Possible Causes:**
1. Permissions not granted
2. Battery optimization is blocking the app
3. Do Not Disturb mode is active

**Solutions:**
1. Check Settings → Apps → Sugary → Permissions → Make sure all are allowed
2. Settings → Apps → Sugary → Battery → "Unrestricted"
3. Temporarily disable Do Not Disturb

### Issue 2: Notifications Appearing Late

**Possible Causes:**
1. Exact alarm permission not granted (Android 12+)
2. Battery saver mode active
3. Using `inexact` instead of `exact` scheduling (now fixed)

**Solutions:**
1. Settings → Apps → Sugary → "Alarms & reminders" → Enable
2. Disable battery saver temporarily for testing
3. Make sure you have the latest code with `exactAllowWhileIdle`

### Issue 3: Notifications Stop After Reboot

**Possible Causes:**
1. Boot receiver not registered (should be fixed in manifest)
2. App hasn't been opened once after installation

**Solutions:**
1. Verify `RECEIVE_BOOT_COMPLETED` permission in AndroidManifest.xml
2. Open app at least once after installation/reboot

### Issue 4: Check Logs Show "ERROR: Not initialized!"

**Possible Causes:**
1. `NotificationService.instance.init()` not called in main.dart
2. Init failed due to error

**Solutions:**
1. Verify main.dart has: `await NotificationService.instance.init();`
2. Check full logs for initialization error details

### Issue 5: Timezone Issues

**Check timezone detection in logs:**
```
[NotificationService] Timezone set to: <timezone-name>
```

If you see "falling back to UTC", the timezone detection failed but notifications should still work (just in UTC time).

## Debug Checklist

Use this checklist to troubleshoot:

- [ ] App has notification permission (Settings → Apps → Sugary → Notifications)
- [ ] App has exact alarm permission (Settings → Apps → Sugary → Alarms & reminders) 
- [ ] Battery optimization disabled for app (Settings → Apps → Sugary → Battery → Unrestricted)
- [ ] Reminder is enabled (toggle ON in app)
- [ ] Time format is correct (HH:mm, e.g., "14:30")
- [ ] Logs show "Notification scheduled successfully"
- [ ] Logs show correct timezone
- [ ] Device is not in Do Not Disturb mode
- [ ] Testing on physical device or release build

## Verify the Fix

To confirm the fix is applied, check these sections in `lib/services/notification_service.dart`:

1. **Import statements**: Should import `latest_all.dart`:
   ```dart
   import 'package:timezone/data/latest_all.dart' as tzdata;
   ```

2. **Timezone initialization section**: Should have timezone fallback logic:
   ```dart
   try {
     final location = tz.local;
     tz.setLocalLocation(location);
     ...
   ```

3. **Permission request section**: Should request exact alarm permission:
   ```dart
   await _plugin
       .resolvePlatformSpecificImplementation<...>()
       ?.requestExactAlarmsPermission();
   ```

4. **Scheduling configuration**: Should use exact scheduling:
   ```dart
   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
   ```

## Advanced Testing

### Test Daily Repetition

1. Schedule a reminder for a time that will occur soon
2. Wait for first notification
3. Next day at the same time, it should fire again

### Test Multiple Reminders

1. Create 3-4 reminders with different times
2. All should fire at their scheduled times
3. Check logs to verify all are scheduled

### Test After Force Close

1. Schedule a reminder
2. Force close the app (swipe away from recent apps)
3. Wait for scheduled time
4. Notification should still appear

### Test After Reboot

1. Schedule a reminder for several hours in the future
2. Reboot your device
3. Don't open the app
4. Wait for scheduled time
5. Notification should appear (app reschedules on boot)

## Getting Help

If notifications still don't work after following this guide:

1. **Capture full logs**:
   ```bash
   adb logcat -d > notification_logs.txt
   ```

2. **Check Android version**:
   ```bash
   adb shell getprop ro.build.version.release
   ```

3. **List granted permissions**:
   ```bash
   adb shell dumpsys package com.example.mysugaryapp | grep permission
   ```

4. **Provide this information**:
   - Android version
   - Device model
   - What you tried
   - What the logs show
   - Screenshots of permission settings

## Expected Behavior Summary

✅ **What Should Work:**
- Notifications fire at exact scheduled time
- Work when app is in background
- Work when app is completely closed
- Work after device reboot
- Repeat daily at the same time
- Show on lock screen
- Play sound and vibrate
- Can be tapped to open reminders screen

❌ **What Won't Work:**
- Very old Android versions (< API 21 / Android 5.0)
- If permissions are denied
- If battery saver aggressively kills the app
- If manufacturer-specific battery optimization interferes (Xiaomi, Huawei, OnePlus, etc.)

## Manufacturer-Specific Issues

Some manufacturers have aggressive battery optimization:

### Xiaomi MIUI
- Settings → Battery & performance → App battery saver → Sugary → "No restrictions"
- Settings → Apps → Manage apps → Sugary → "Autostart" → Enable

### Huawei EMUI
- Settings → Apps → Sugary → Battery → Launch → "Manual" and enable all three

### OnePlus OxygenOS
- Settings → Battery → Battery optimization → Sugary → "Don't optimize"
- Settings → Apps → Sugary → Advanced → Battery optimization → "Disable"

### Samsung One UI
- Settings → Apps → Sugary → Battery → "Unrestricted"
- Settings → Device care → Battery → App power management → Sugary → Turn off all restrictions

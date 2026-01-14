# mysugaryapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firestore Schema

### Reminders Collection

The app uses a doc-per-reminder structure under the reminders subcollection:

**Path:** `users/{uid}/reminders/items/list/{reminderId}`

Each reminder document contains:
- `type`: string - Type of reminder ("medication", "glucose", or "appointment")
- `title`: string - User-defined title/description
- `time`: string - Time in HH:mm format (e.g., "08:00", "14:30")
- `frequency`: string - Frequency key (e.g., "reminders.freq_daily")
- `enabled`: boolean - Whether the reminder is active
- `createdAt`: string - ISO 8601 timestamp

**SmartAssist Compatibility:**
The app also maintains legacy array-based collections for SmartAssist onboarding:

- `users/{uid}/reminders/medications` - Array of medication reminders
- `users/{uid}/reminders/glucose_checks` - Array of glucose check reminders

**SmartAssist Completion Flag:**
- `users/{uid}/smartAssistComplete` - Boolean flag indicating onboarding completion


# Proofhoto

Proofhoto is an offline-first habit tracker where a habit is marked complete only after you submit proof (photo or short video).

## Features

- Habit management: create, edit, reorder, and archive habits
- Scheduled habits by weekday with optional reminder time
- Proof capture from camera or gallery
- Video proof support (up to 15 seconds) with thumbnail generation
- Timeline view grouped by day
- Stats dashboard:
  - current and best streaks
  - last 7 days completion chart
  - monthly heatmap
  - per-habit completion trends
- Streak freeze system (earn and consume freeze tokens)
- Theme mode selection (system, light, dark)
- Local data export to JSON
- 100% local storage (Hive + app documents directory)

## Tech Stack

- Flutter + Dart
- State management: Riverpod
- Local database: Hive
- Media: image_picker, video_player, flutter_image_compress, video_compress, video_thumbnail
- Notifications: flutter_local_notifications + timezone
- Charts: fl_chart

## Project Structure

```text
lib/
  core/            # constants, router, theme, utilities
  features/
    habits/        # habit CRUD, scheduling, streak milestones
    proof/         # photo/video proof capture and storage
    timeline/      # chronological proof feed
    stats/         # streaks, charts, heatmap, trends
    settings/      # theme, notifications, freezes, export/delete actions
  shared/          # reusable widgets
```

## Getting Started

### Prerequisites

- Flutter SDK (Dart SDK `^3.4.0` as defined in `pubspec.yaml`)
- Android Studio and/or Xcode for mobile builds

### Install Dependencies

```bash
flutter pub get
```

### Generate Hive Adapters (when models change)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run the App

```bash
flutter run
```

Examples:

```bash
flutter run -d android
flutter run -d ios
flutter run -d chrome
```

## Quality Checks

```bash
flutter analyze
flutter test
```

Note: `test/widget_test.dart` is currently a placeholder test.

## Data and Storage

- Hive boxes:
  - `habits`
  - `proofEntries`
  - `settings`
- Media files are stored under the app documents directory:
  - `proof/{habitId}/...`
- Exported JSON is written to:
  - Android external app storage (when available)
  - app documents directory fallback

## Platform Permissions

Configured permissions include:

- Camera and photo/media library access
- Microphone (for video audio)
- Notifications and exact alarms (for scheduled reminders)

See:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## Development Notes

- Main app entry: `lib/main.dart`
- App shell and routes: `lib/app.dart`, `lib/core/router/app_router.dart`
- Generated files like `*.g.dart` are committed and should be regenerated after model changes.

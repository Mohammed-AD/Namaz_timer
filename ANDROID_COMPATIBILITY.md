# Android Compatibility (Android 12+)

## Build configuration

- Minimum Android version: Android 12 / API 31 (`minSdk = 31`).
- Compile SDK: API 36.
- Target SDK: API 36 (`targetSdk = 36`). This meets the Google Play target requirement for new app submissions and updates as of October 2026.
- Java bytecode target: Java 17.
- Gradle wrapper: Gradle 8.13; Android Gradle Plugin: 8.13.2; Kotlin Gradle Plugin: 2.3.10. This stable AGP 8.x configuration supports Android API 36.1 and avoids relying on AGP 9 migration compatibility flags.
- The Kotlin Gradle Plugin is explicitly applied in `android/app/build.gradle.kts` before the Flutter Gradle plugin.
- The app's package/application ID remains `com.example.namaz_app`; change it to the publisher's permanent application ID before a public release if this is not the intended ID.

## Intended OS coverage

The package is configured for Android 12 (API 31), Android 12L (API 32), Android 13 (API 33), Android 14 (API 34), Android 15 (API 35), Android 16 (API 36), and newer Android releases subject to their platform behavior and the Flutter/plugin versions used to build it.

`minSdk`, `targetSdk`, and a successful source-level configuration check do not by themselves prove device compatibility. Test actual APKs on emulators/devices for each available API level before publishing. Android 17/API 37 support depends on the installed stable Flutter/Android SDK toolchain and should be added to the device test matrix when available.

## Validation steps in a Flutter-enabled environment

Run from the project root:

```bash
flutter --version
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

Then install and smoke-test on at least API 31, 33, 34, 35, and 36; include API 32 and any newer available API level as well. Check app launch, navigation, prayer times/network fallback, settings persistence, backup/restore, Wird/Dhikr progress, timer start/pause/reset, audio, screen rotation, system bars/edge-to-edge layout, and app process recreation.

## Timer limitation

The current timer is an in-app Dart timer that plays audio while the process can execute. This project does **not** currently implement Android scheduled notifications/exact alarms for reliable ringing after the app is force-stopped or the OS terminates its process. Battery optimization and manufacturer background limits can affect background behavior. Do not advertise a guaranteed background/closed-app alarm until a native scheduled-alarm/notification implementation is added and tested on physical devices.

## Current verification status

The editing environment used to prepare this package did not have Flutter or Dart installed, so `flutter analyze`, `flutter test`, APK builds, and physical-device tests could not be run here. This file documents the required validation rather than claiming those tests passed.


Calendar / special-day changes are source-level updates included in version 1.4.3+8. Re-run the widget tests and verify calendar month navigation, moon-sighting adjustment, future-month rendering, start/end flow, and history deletion on Android API 31+ before publishing.

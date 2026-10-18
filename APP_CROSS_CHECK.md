# Namaz Timer — cross-check and Android readiness

## Changes in this handoff
- Replaced Android launcher icons in all five density buckets with a Namaz Timer-specific crescent, mosque, and timer design.
- Added Android adaptive launcher icon resources for Android 8+ launchers, including the Android 13+ themed monochrome icon hook. Existing `AndroidManifest.xml` already points to `@mipmap/ic_launcher`.
- Removed four unused legacy source files that were not referenced by the active app/tests: root `main.dart`, the old Dhikr page/provider, and old RestCard.
- Kept app identity and existing feature set intact.

## Android target configuration checked
- `minSdk = 31` (Android 12)
- `targetSdk = 36`, `compileSdk = 36`
- Java/Kotlin target 17
- Gradle wrapper 8.13 and Android Gradle Plugin 8.13.2
- Internet permission declared for prayer-time API; no unrelated location/alarm permissions requested.

## Known limitations / release gates
- This package has **not** been verified by a Flutter analyzer, test run, APK build, emulator, or physical device in this environment because Flutter/Dart are unavailable here. Do not treat source review as a successful build certification.
- Timer ringing is app-process based; it is not a guaranteed scheduled alarm when the app is killed or the OS suspends it.
- Android package ID remains `com.example.namaz_app`; replace it before a public Play Store release.
- Run these from the project root in a Flutter 3.44+ / Dart 3.12+ environment:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

- Smoke-test install, navigation, settings persistence, prayer-time network/offline fallback, timer pause/reset/ringing, backup/restore, calendar on narrow screens, text scaling, rotation, and process recreation on Android API 31, 32, 33, 34, 35, and 36. Confirm prayer times against a trusted local mosque/community before relying on them.

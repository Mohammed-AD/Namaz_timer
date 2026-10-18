# Icon and in-app logo setup

- Android launcher mipmap icons were replaced with the new blue/violet Namaz Timer artwork.
- Adaptive launcher background was updated to a matching blue.
- iOS app icon catalog, web/PWA icons, favicon, and Apple touch icon use the same artwork.
- `assets/images/app_logo.png` is registered in `pubspec.yaml` and displayed in the main app header.
- Source artwork: `namaz_timer_app_logo_source.png`.

After opening the project, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Verified on 2026-10-16: analyzer clean, all 37 tests pass, web build and Android debug/release APK builds succeed. The release web UI was smoke-tested at desktop and phone widths. Check launcher masking and splash presentation on Android 12+ devices; physical-device testing is still required before release.

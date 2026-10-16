# Namaz Timer — Feature Cross-check

Review basis: static source review of v1.4.2 project plus test-suite inspection. This is not a claim that all flows were run on a device: the review environment does not have Flutter/Dart installed, so `flutter test`, `flutter analyze`, and platform builds could not be executed. The declared SDK floor is Dart 3.12+ and Flutter 3.44+. Android minimum/target SDK and Gradle toolchain settings were hardened for Android 12+ / API 31+ in this revision.

## Feature matrix

| Area | What the project contains | Current check / remaining gap |
|---|---|---|
| Namaz tracker | Five daily prayers, tap-to-mark, future-day lock, daily progress, year heatmap, streak | Prayer-window / Qibla logic and heatmap have unit tests; end-to-end tap/persistence flow still needs runtime testing |
| Prayer times | Adhan-based city times, Hanafi/Shafi'i Asr setting, manual minute offsets and exact-time overrides | Static logic reviewed; newly added settings persistence test covers custom location and exact-time preferences, but is not yet executed |
| Makkah / Madinah times | AlAdhan API, Umm al-Qura method, 15-minute cache, manual refresh, cache/offline/local fallback | Service tests cover successful fetch, cache reuse, forced refresh, offline fallback and malformed clock values; execution pending |
| Hijri calendar | Month navigation, Gregorian date labels, Hijri offset, special-event labels | Calendar and event tests exist; verify local moon-sighting dates with a trusted calendar before publication |
| Special days | Start/end date, history, length/cycle estimates, tracking pause, qada-fast tally | Provider and calendar tests exist; user-facing estimates should remain informational, not medical advice |
| Wird / dhikr | Default items, custom Surah/dhikr entries, Arabic text, targets, daily/total counts, undo/reset, Surah picker | Core editor/counter paths are present; direct widget tests are still missing. Added name/Arabic search and day-boundary refresh |
| Timer | Presets, slider, next-prayer duration, pause, reset, +1 minute, looping sound/haptics | No timer widget/integration test. The alarm is driven by an in-app timer; do not assume reliable ringing after app suspension or process termination |
| Watch face | Four styles and live next-prayer countdown | Static source path reviewed; visual/device checks remain |
| Settings | City picker, custom coordinates, madhab, Hijri adjustment, sunset date option, theme, time editor | Custom coordinates now reject NaN/infinite/out-of-range values. UI/device checks remain |
| Backup / restore | Clipboard JSON for supported preferences and logs | Round-trip test exists; restore now rejects unsupported backup versions. Test execution pending |
| Platforms | Android, iOS, web, Linux, macOS and Windows scaffolding | No build was possible here; verify required plugin support and release signing separately |

## Changes included in this review

1. Cached Saudi prayer timings are reported as `Cached` when the current request did not contact the API; cache age also handles future timestamps safely.
2. Malformed API times such as `99:15` are rejected and trigger the existing fallback path.
3. Custom coordinates reject non-finite values such as `NaN` and infinity. Temporary text controllers are disposed after the location dialog closes.
4. Wird progress uses the shared day boundary so daily counters update after midnight, and users can search names or Arabic text.
5. Backup restore validates the supported backup version.
6. Removed four confirmed unreferenced legacy files (the old root `main.dart`, `DhikrPage`, `DhikrNotifier`, and `RestCard`) that no longer belong to the Wird/special-days implementation.
7. Added/updated tests for cache source, malformed API times, coordinate validation, backup version, and settings persistence.

## Android 12+ compatibility configuration

- `minSdk = 31` — Android 12 and newer only.
- `compileSdk = 36` and `targetSdk = 36` — aligned with the current Android 16 / Google Play target baseline as of October 2026.
- Gradle 8.13 + Android Gradle Plugin 8.13.2 + Kotlin Gradle Plugin 2.3.10; Kotlin plugin is applied before Flutter's Gradle plugin.
- The app manifest currently needs internet access only; no notification, exact-alarm, or location permissions were added because those OS-level features are not yet implemented.
- These are source/configuration checks, not proof of successful APK build or device compatibility. Flutter/Dart are unavailable in the review environment, so run the commands and device matrix in `ANDROID_COMPATIBILITY.md` before release.

## Recommended next features (priority order)

1. **Reliable prayer notifications** — scheduled local notifications with separate Adhan/reminder toggles, per-prayer lead time, quiet hours, and a clear battery/background limitation note. This is the highest-value addition, but needs platform-specific notification setup and real-device testing.
2. **Home-screen widget / quick action** — next prayer name and countdown plus a fast “namaz done” action.
3. **Monthly reports and export** — prayer completion percentage, missed-prayer trends, Wird totals, and CSV/PDF export.
4. **Location and calculation preferences** — optional GPS city detection, calculation-method selector, and timezone-aware location handling while travelling.
5. **Data portability** — scheduled reminders for backup and a safer share-file export/import flow rather than clipboard only; cloud sync only if the user explicitly opts in.

## Release checklist

- Run `dart format lib test` and `flutter analyze`.
- Run `flutter test` and fix all failures before interpreting coverage as passing.
- Build/test Android and iOS on physical devices; verify timer audio, lifecycle/background behavior, text scaling and permissions.
- Build web and desktop targets if they are intended releases.
- Confirm prayer times against the user's local mosque/authority; AlAdhan and calculated solar times are not guaranteed to match local iqama schedules.
- Replace the example Android/iOS package identifier before store publication, as noted in the README.


## v1.4.3+8 — Special Days & Calendar follow-up

- Refreshed Calendar layout around today's dual Gregorian/Hijri date, a more legible Hijri grid, date markers/legend, selected-date detail, and an agenda of upcoming major Hijri dates.
- Added visible guidance that upcoming Hijri event dates can vary by local moon sighting/community convention.
- Added Calendar start-today / finish-record actions with confirm steps and safe date bounds, and hardened start-date validation in the Namaz tab.
- Improved special-day record history, estimate wording, and deletion confirmation.
- Fixed open-ended special-day records incorrectly covering future dates in calendar/stat views.
- Added regression coverage for future-date marking and record-start validation.
- **Not run here:** Flutter analyzer, Dart tests, and APK builds. This environment has no Flutter/Dart SDK; see `SPECIAL_DAYS_CALENDAR.md` for release validation steps.

## v1.4.4+9 — Calendar overflow fix

- Reduced day-cell text and marker-strip vertical sizing and tightened text line heights.
- Calendar grid cells are slightly taller, preventing the date labels and marker row from exceeding the available height on compact displays.
- Added a 320 px wide widget regression test to detect reported Flutter layout exceptions.
- Test/build execution remains pending because Flutter/Dart SDK tools are not installed in this environment.

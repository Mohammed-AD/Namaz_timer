# Namaz Timer (v1.4.3)

Namaz tracker, Hijri calendar, Wird (surah + dhikr), timer, and live Makkah/Madinah prayer sync. State: **Riverpod**.

## Structure
```
lib/
  main.dart, app.dart          # entry + shell (top bar + 4 tabs)
  core/                        # theme (light+dark), constants, format, events, surahs, beep
  providers/                   # ALL state + logic, no UI
    settings_provider          # city, asr, theme, hijri adj, per-prayer custom times
    prayer_times_provider      # auto times -> + user offsets/exact times; Makkah/Madinah
    log_provider               # namaz log + special-day dhikr log
    rest_provider / stats      # special days, qada roze, streak
    wird_provider              # user-defined surah / dhikr with own targets
    clock_provider             # 1s ticker (top bar), 20s pulse, today
  widgets/common.dart          # AppCard, PageHeader, StatCard, ProgressRing, Pill
  features/
    shell/      top_bar (mini watch + Makkah/Madinah/your city), times_sheet
    namaz/      page, prayer tiles, special card, heatmap
    calendar/   page
    wird/       list, counter, editor, 114-surah picker
    timer/      page
    settings/   settings sheet, times_editor_page
```

## Upgrade
Replace `lib/` and `pubspec.yaml` (no new packages vs v1.1), delete old root `main.dart`,
`flutter pub get && flutter run`. Saved namaz log / city / madhab keep working.
Old dhikr counter data is replaced by the new Wird list (defaults are seeded).


## v1.3 live Makkah/Madinah timing changes

- Makkah and Madinah now use an API-first Umm al-Qura schedule (`AlAdhan`) with a 15-minute cache.
- If the network is unavailable, the app falls back to the previous local `adhan` calculation.
- Makkah/Madinah calculations are normalized to Saudi Arabia UTC+03:00 so next-prayer logic remains correct across midnight.
- The times sheet now shows live/cache/offline status and has a manual refresh action.
- `http: ^1.2.2` is the only new direct package.
- The API provider itself warns that its timings may differ from a local mosque or government authority. Do not present API timings as official Haram iqama times.


## v1.4 changes

**Fixes**
- Manual refresh in the Makkah/Madinah sheet now really re-fetches (it used to return the 15-min cache).
- Cached prayer timings are labelled as cached (not "Live") when the current load did not contact the API.
- The live-sync loop stops when its provider is disposed.
- "Ayyam al-Bidh · sunnah roza" no longer shows during Ramadan (13-15 Ramadan are obligatory fasts).
- The orphaned watch face is reachable again: tap the mini clock in the top bar (always dark, so hands stay visible).
- Removed dead code: old root `main.dart`, `rest_card.dart`, and the unused dhikr page/provider (replaced by Wird).
- App name is now "Namaz Timer" on Android, iOS and web.

**New**
- Current prayer window on the Namaz page ("Zohar ka waqt chal raha hai · 1h 20m baaki").
- Optional: Hijri date changes at Maghrib (Settings > Hijri tareekh).
- 18 more cities, searchable city picker, and a custom location (latitude / longitude).
- Qibla bearing in the times sheet.
- Backup / Restore of all app data through the clipboard (no new packages).

**Before publishing to the Play Store / App Store** change the package id `com.example.namaz_app`.

**Special days (v1.4)**
- Calendar: special days are one connected band with a sparkle icon; tap a day for "Din 3 / 6" and the start - end dates.
- Calendar: month count ("Is mahine me N special din") and a "Special days ka record" card (every run, duration, average, cycle, gentle estimate of the next one, delete wrong entries).
- Namaz tab: start from today / yesterday / any date; end by choosing the last special day; shows start date, day count and the previous duration.


## v1.4.1 review improvements

- Makkah / Madinah timing status now distinguishes a recent cached result from a response fetched live in the current load; cache age checks also handle future timestamps safely.
- Invalid API clock values are rejected so malformed responses fall back to cached/local timings.
- Custom coordinates reject non-finite values such as `NaN`.
- Wird daily counters subscribe to the app's day boundary and refresh after midnight; the Wird tab also supports searching by name or Arabic text.
- Backup restore rejects unsupported backup versions instead of silently attempting an incompatible import.

## Verification note

The included unit/widget tests were expanded for cached source labeling, malformed API times, coordinate validation, backup-version rejection, and settings persistence/manual time overrides. The review environment did not have the Flutter/Dart SDK available, so `flutter test`, `flutter analyze`, and platform builds still need to be run in a Flutter-enabled environment before release.


## v1.4.3 — Special Days + Calendar refinement

- Calendar refreshed with a clear today banner, improved Hijri month navigation, accessible day labels, and distinct markers for notable Hijri dates, prayer/dhikr activity, and recorded special days.
- Added an upcoming notable-dates agenda. Dates are explicitly described as estimates because local moon sighting and community conventions may differ.
- Selected-day details now combine Hijri/Gregorian dates, event context, special-day duration, and prayer/dhikr log.
- Added quick start/finish controls for a special-day record directly on the Calendar tab, with confirmations and date validation.
- Refined special-day history with compact summary stats, more explicit estimate wording, stronger delete confirmation, and on-device privacy/backup hints.
- Fixed an edge case where an ongoing special-day record incorrectly coloured future calendar dates as special.
- Added regression tests for future-date marking and overlapping/out-of-range records.

Build verification remains pending in a Flutter-enabled environment. See `ANDROID_COMPATIBILITY.md` and `SPECIAL_DAYS_CALENDAR.md` for exact smoke-test steps.

## v1.4.4+9 — Compact Calendar Layout Fix

- Fixed the calendar's tightly constrained day cells for small Android display widths.
- Reduced the vertical footprint of Hijri/Gregorian labels and event/progress markers.
- Made grid cells slightly taller to keep the date and indicators balanced without `RenderFlex` bottom overflow.
- Added a compact-width widget regression test (`test/calendar_layout_test.dart`).
- Flutter analyzer, tests, and APK builds must still be run in a Flutter-enabled environment before release.

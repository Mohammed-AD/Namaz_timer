# Namaz Timer (v1.4)

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
- A cache entry younger than 15 min is shown as "Live", not as a misleading offline/cached icon.
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

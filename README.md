# namaz_app (v1.3)

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

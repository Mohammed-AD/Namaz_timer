# Special Days & Calendar — v1.4.3+8

## Calendar experience

- **Today banner:** shows the current Gregorian and Hijri dates together with a one-tap jump back to today.
- **Hijri month grid:** keeps Hijri day numbers prominent and Gregorian day numbers secondary. Month navigation preserves the selected Hijri day where possible and respects the configured Hijri adjustment.
- **Calendar markers:** gold marks notable Hijri dates, violet marks saved special-day periods when the optional feature is enabled, and green markers represent logged prayer/dhikr activity. Day cells expose date/event status to accessibility services.
- **Selected-day panel:** combines both calendar systems, notable-date context, the saved special-day range/day number, and the prayer/dhikr log.
- **Upcoming agenda:** shows the next few notable dates, including a Hijri date label. A visible note explains that dates may differ due to local moon sighting/community convention; they are a guide, not an official calendar.

## Special-day tracking improvements

- The Calendar tab provides direct start-today and finish-record controls, with confirmation before writing state.
- Starting a record is prevented when a record is already active, a date is in the future, or the chosen date overlaps a saved period.
- Finishing a record uses a date picker bounded by the saved start date and today, then confirms the chosen last day. Normal prayer tracking resumes from the next day based on the stored range.
- The history list is newest-first, shows basic duration/cycle summaries, clarifies that next-date values are estimates, and asks for confirmation before deleting a record.
- An ongoing range now ends for calendar display at today. It no longer paints future days as if they were already recorded special days.
- The optional setting stays off by default. Personal dates remain local to the device unless included in a manual backup.

## QA checklist

Run in a Flutter-enabled environment from the project root:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Then manually verify:

1. Calendar today banner and Today button agree with the device date.
2. Previous/next Hijri month works across Muharram/Dhu al-Hijjah boundaries and leap-year month lengths.
3. Hijri adjustment (-1 / Auto / +1) changes displayed dates and event markers consistently.
4. Future dates in an ongoing special-day range are not marked as recorded.
5. Start today is blocked while another range is active or conflicting; canceling confirmation changes nothing.
6. Finish-record picker cannot choose before the start date or after today; canceling changes nothing.
7. Deleting a record updates calendar shading and makes the normal prayer log visible again for the deleted range.
8. Event dates are visibly qualified as approximate and upcoming entries do not overflow narrow screens.
9. Light and dark themes, small screens, large text, screen readers, and Android API 31, 32, 33, 34, 35, 36+ are checked.

## Verification note

The editing environment does not include Flutter or Dart. Source changes and project/package structure have been checked, but `flutter analyze`, `flutter test`, and APK builds have **not** been executed here. Do not treat this archive as a signed/release-ready APK until those checks pass on a Flutter SDK and the target devices.

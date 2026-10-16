# Calendar day-cell overflow fix (v1.4.4+9)

## Problem
On compact Android display widths, the calendar could report `BOTTOM OVERFLOWED BY 1.5 PIXELS` on each week row. Each cell stacked a Hijri day, Gregorian day, vertical gap, and event/progress markers inside a tightly constrained grid tile.

## Changes
- Reduced the day label from 15 to 14 px and the Gregorian sub-label from 10 to 9 px.
- Used compact, explicit text line heights so the two dates take predictable vertical space.
- Reduced the gap and marker-strip height while preserving notable-date, prayer/dhikr, and special-day markers.
- Made calendar grid tiles slightly taller (`childAspectRatio: 0.92`) to improve visual balance and fit on narrow screens.
- Added `test/calendar_layout_test.dart` to exercise the calendar at a compact 320 px width and check for Flutter layout exceptions.

## Verification
Static source review completed and the updated source package was assembled. This environment does not have the Flutter SDK available, so `flutter analyze`, `flutter test`, and an Android APK build could not be executed here. Run those commands in a Flutter 3.44+ environment before releasing.

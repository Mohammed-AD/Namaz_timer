import 'package:hijri/hijri_calendar.dart';

import 'constants.dart';

String p2(int n) => n.toString().padLeft(2, '0');

String fmt(DateTime t, {bool ampm = true}) =>
    '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${p2(t.minute)}${ampm ? (t.hour < 12 ? ' AM' : ' PM') : ''}';

/// Format an instant in a fixed UTC offset (e.g. Makkah = +180 min).
/// [offsetMin] == null means "device local time".
String fmtZ(DateTime t, int? offsetMin, {bool ampm = true}) => fmt(
    offsetMin == null ? t : t.toUtc().add(Duration(minutes: offsetMin)),
    ampm: ampm);

String dur(Duration d) => d.inHours > 0
    ? '${d.inHours}h ${d.inMinutes % 60}m'
    : (d.inMinutes < 1 ? '<1m' : '${d.inMinutes}m');

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime shift(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

/// Convert an instant to the wall-clock time in a fixed UTC offset.
/// The returned DateTime intentionally has no timezone semantics attached;
/// it is only used as a comparable display/calculation clock.
DateTime wallClockAtOffset(DateTime instant, int offsetMinutes) =>
    instant.toUtc().add(Duration(minutes: offsetMinutes));

/// The local calendar date at a fixed UTC offset.
DateTime dayAtOffset(DateTime instant, int offsetMinutes) =>
    dayOnly(wallClockAtOffset(instant, offsetMinutes));

/// Convert a wall-clock DateTime (whose fields represent a fixed-offset zone)
/// into the corresponding UTC instant.
DateTime wallClockToUtc(DateTime wall, int offsetMinutes) =>
    DateTime.utc(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
      wall.millisecond,
      wall.microsecond,
    ).subtract(Duration(minutes: offsetMinutes));

/// yyyymmdd - sorts lexicographically, so string compare == date compare.
String dayKey(DateTime d) => '${d.year}${p2(d.month)}${p2(d.day)}';
DateTime parseKey(String k) => DateTime(
    int.parse(k.substring(0, 4)),
    int.parse(k.substring(4, 6)),
    int.parse(k.substring(6, 8)));

int bits(int m) {
  var c = 0;
  while (m > 0) {
    c += m & 1;
    m >>= 1;
  }
  return c;
}

/// Hijri date with the user's moon-sighting adjustment (-1, 0, +1 day).
HijriCalendar hijriOf(DateTime d, int adj) =>
    HijriCalendar.fromDate(shift(d, adj));

String hijriText(HijriCalendar h) =>
    '${h.hDay} ${hMonths[h.hMonth - 1]} ${h.hYear} AH';

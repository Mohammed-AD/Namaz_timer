import 'dart:math' as math;

import 'constants.dart';
import 'day_times.dart';

/// Validate coordinates before they reach the prayer-time calculation engine.
/// Finite checks are important because comparisons with NaN are always false.
bool isValidCoordinates(double? latitude, double? longitude) =>
    latitude != null &&
    longitude != null &&
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

/// Initial great-circle bearing (degrees clockwise from true north, 0-360)
/// from [from] to the Kaaba in Makkah.
double qiblaBearing(City from) {
  const kLat = 21.4225, kLng = 39.8262;
  final lat1 = from.lat * math.pi / 180;
  final lat2 = kLat * math.pi / 180;
  final dLng = (kLng - from.lng) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// 8-point compass name for a bearing.
String compassName(double deg) {
  const names = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  return names[((deg % 360) / 45).round() % 8];
}

/// The prayer whose time is running right now, and when it ends.
class PrayerWindow {
  final int index; // into [prayers]
  final DateTime end;
  const PrayerWindow(this.index, this.end);
}

/// [today] = today's times, [tomorrow] = tomorrow's, [yesterday] = yesterday's.
/// Fajr ends at sunrise; every other prayer ends when the next one starts;
/// Isha ends at the next Fajr. Between sunrise and Zohar no prayer is running,
/// so this returns null.
PrayerWindow? currentWindow(
    DateTime now, DayTimes yesterday, DayTimes today, DayTimes tomorrow) {
  if (now.isBefore(today.fajr)) {
    // After midnight, still inside last night's Isha.
    return now.isBefore(yesterday.isha) ? null : PrayerWindow(4, today.fajr);
  }
  if (now.isBefore(today.sunrise)) return PrayerWindow(0, today.sunrise);
  if (now.isBefore(today.dhuhr)) return null;
  if (now.isBefore(today.asr)) return PrayerWindow(1, today.asr);
  if (now.isBefore(today.maghrib)) return PrayerWindow(2, today.maghrib);
  if (now.isBefore(today.isha)) return PrayerWindow(3, today.isha);
  return PrayerWindow(4, tomorrow.fajr);
}

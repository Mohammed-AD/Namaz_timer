
import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/day_times.dart';
import '../core/format.dart';
import 'holy_times_service.dart';
import 'prefs_provider.dart';
import 'settings_provider.dart';

/// Pure calculation. [umm] = Umm al-Qura method (used for Makkah / Madinah).
DayTimes computeTimes(City c, DateTime day,
    {required bool hanafi, bool umm = false}) {
  final params = (umm ? CalculationMethod.umm_al_qura : CalculationMethod.karachi)
      .getParameters()
    ..madhab = (hanafi && !umm) ? Madhab.hanafi : Madhab.shafi;
  final t =
      PrayerTimes(Coordinates(c.lat, c.lng), DateComponents.from(day), params);
  return DayTimes(t.fajr, t.sunrise, t.dhuhr, t.asr, t.maghrib, t.isha);
}

bool _isHolyCity(City c) => c.name == 'Makkah' || c.name == 'Madinah';

/// Calculated times for the user's city, before any manual change.
final autoTimesProvider =
    Provider.autoDispose.family<DayTimes, DateTime>((ref, day) {
  final city = ref.watch(settingsProvider.select((s) => s.city));
  final selected = cities[city];
  final hanafi = ref.watch(settingsProvider.select((s) => s.hanafi));
  return computeTimes(selected, day,
      hanafi: hanafi, umm: _isHolyCity(selected));
});

/// What the user actually sees: calculated times + their own offsets / exact
/// times (every masjid has slightly different timings).
final prayerTimesProvider =
    Provider.autoDispose.family<DayTimes, DateTime>((ref, day) {
  final auto = ref.watch(autoTimesProvider(day));
  final off = ref.watch(settingsProvider.select((s) => s.offsets));
  final fix = ref.watch(settingsProvider.select((s) => s.fixed));
  DateTime pick(int i, DateTime a) => fix[i] >= 0
      ? DateTime(day.year, day.month, day.day, fix[i] ~/ 60, fix[i] % 60)
      : a.add(Duration(minutes: off[i]));
  return DayTimes(pick(0, auto.fajr), auto.sunrise, pick(1, auto.dhuhr),
      pick(2, auto.asr), pick(3, auto.maghrib), pick(4, auto.isha));
});

/// Offline, local calculation used immediately while the live schedule loads
/// or when there is no network.
HolyTimesFetchResult localHolyTimes(DateTime day) {
  final mk = _toSaudiUtc(
      computeTimes(makkah, day, hanafi: false, umm: true));
  final md = _toSaudiUtc(
      computeTimes(madinah, day, hanafi: false, umm: true));
  return HolyTimesFetchResult(
    makkah: mk,
    madinah: md,
    source: HolyTimesSource.localCalculation,
  );
}

DayTimes _toSaudiUtc(DayTimes t) => DayTimes(
      wallClockToUtc(t.fajr, holyUtcMinutes),
      wallClockToUtc(t.sunrise, holyUtcMinutes),
      wallClockToUtc(t.dhuhr, holyUtcMinutes),
      wallClockToUtc(t.asr, holyUtcMinutes),
      wallClockToUtc(t.maghrib, holyUtcMinutes),
      wallClockToUtc(t.isha, holyUtcMinutes),
    );

/// Live Makkah / Madinah schedule.
///
/// Primary source: AlAdhan API + Umm Al-Qura method.
/// Fallback order: 15-min cache -> local adhan calculation.
final holyTimesProvider = StreamProvider.autoDispose
    .family<HolyTimesFetchResult, DateTime>((ref, day) async* {
  final client = http.Client();
  ref.onDispose(client.close);

  final service = HolyTimesService(
    ref.read(prefsProvider),
    client: client,
    localFallback: localHolyTimes,
  );

  while (true) {
    yield await service.load(day);
    await Future<void>.delayed(const Duration(minutes: 15));
  }
});

/// Synchronous fallback so the UI never has to block on the network.
final localHolyTimesProvider = Provider.autoDispose
    .family<HolyTimesFetchResult, DateTime>((ref, day) => localHolyTimes(day));

/// (index into [prayers], time) of the next prayer after [now].
(int, DateTime) nextPrayer(DateTime now, DayTimes today, DayTimes tomorrow) {
  final t = today.five;
  for (var i = 0; i < 5; i++) {
    if (t[i].isAfter(now)) return (i, t[i]);
  }
  return (0, tomorrow.fajr);
}

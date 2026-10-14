import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/prayer_times_provider.dart';
import '../../providers/settings_provider.dart';
import '../settings/settings_sheet.dart';
import '../watch/watch_page.dart';
import 'times_sheet.dart';

/// Global header: tiny watch on the left, Makkah / Madinah / your city on the
/// right (next prayer for each), settings button at the end.
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
        child: Row(children: [
          const Expanded(
              child: Align(
                  alignment: Alignment.centerLeft, child: _MiniClock())),
          const _CityStrip(),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => showSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
        ]),
      );
}

class _MiniClock extends ConsumerWidget {
  const _MiniClock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final now = ref.watch(secondProvider).value ?? DateTime.now();
    final h = ref.watch(hijriNowProvider);
    final h12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showWatchPage(context),
      child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$h12:${p2(now.minute)}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      fontFeatures: [FontFeature.tabularFigures()])),
              Text(':${p2(now.second)}',
                  style: TextStyle(
                      fontSize: 13,
                      color: p.accent,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              Text(' ${now.hour < 12 ? 'AM' : 'PM'}',
                  style: TextStyle(
                      fontSize: 11,
                      color: p.muted,
                      fontWeight: FontWeight.w700)),
            ]),
        Text('${now.day} ${months[now.month - 1]} · ${h.hDay} ${hMonths[h.hMonth - 1]}',
            style: TextStyle(fontSize: 11, color: p.muted)),
      ]),
    ));
  }
}

class _CityStrip extends ConsumerWidget {
  const _CityStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final now = ref.watch(pulseProvider).value ?? DateTime.now();

    // The user's city follows the device timezone.
    final localToday = dayOnly(now);
    final localTomorrow = shift(localToday, 1);
    final placeName = ref.watch(settingsProvider.select((s) => s.place.name));
    final mine = nextPrayer(now, ref.watch(prayerTimesProvider(localToday)),
        ref.watch(prayerTimesProvider(localTomorrow)));

    // Makkah and Madinah are fixed at Asia/Riyadh (UTC+03:00).
    // This avoids wrong "today/next prayer" results around midnight in India.
    final saudiToday = dayAtOffset(now, holyUtcMinutes);
    final saudiTomorrow = shift(saudiToday, 1);
    final liveHoly = ref.watch(holyTimesProvider(saudiToday));
    final hToday = liveHoly.asData?.value ?? localHolyTimes(saudiToday);
    final hTom = localHolyTimes(saudiTomorrow);
    final saudiNow = now.toUtc();
    final mk = nextPrayer(saudiNow, hToday.makkah, hTom.makkah);
    final md = nextPrayer(saudiNow, hToday.madinah, hTom.madinah);

    Widget line(String place, Color c, (int, DateTime) n, int? off) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 54,
              child: Text(place,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: c))),
          Text('${prayers[n.$1]} ${fmtZ(n.$2, off, ampm: false)}',
              style: TextStyle(
                  fontSize: 11,
                  color: p.muted,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ]);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showTimesSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          line('Makkah', p.gold, mk, holyUtcMinutes),
          line('Madinah', p.gold, md, holyUtcMinutes),
          line(placeName, p.accent, mine, null),
        ]),
      ),
    );
  }
}

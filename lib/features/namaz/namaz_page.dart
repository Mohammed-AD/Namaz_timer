import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/log_provider.dart';
import '../../providers/prayer_times_provider.dart';
import '../../providers/rest_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/common.dart';
import 'heat_painter.dart';
import 'prayer_tiles.dart';
import 'special_card.dart';

class NamazPage extends ConsumerStatefulWidget {
  const NamazPage({super.key});
  @override
  ConsumerState<NamazPage> createState() => _NamazState();
}

class _NamazState extends ConsumerState<NamazPage> {
  late int year = DateTime.now().year;
  late final ScrollController sc =
      ScrollController(initialScrollOffset: _target());

  double _target() {
    final now = DateTime.now();
    if (year != now.year) return 0;
    final start = DateTime(year, 1, 1);
    final w = (now.difference(start).inDays + start.weekday % 7) ~/ 7;
    return math.max(0, w * HeatPainter.cell - 160);
  }

  void _setYear(int y) {
    setState(() => year = y);
    if (sc.hasClients) {
      sc.jumpTo(math.min(_target(), sc.position.maxScrollExtent));
    }
  }

  @override
  void dispose() {
    sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final today = ref.watch(todayProvider);
    final log = ref.watch(logProvider);
    final slog = ref.watch(specialLogProvider);
    final restOn = ref.watch(restEnabledProvider);
    final rest = ref.watch(restProvider);
    final streak = ref.watch(streakProvider);
    final adj = ref.watch(settingsProvider.select((s) => s.hijriAdj));
    final hj = hijriOf(today, adj);
    final special = restOn && rest.isRest(today);
    final c = special ? slog.count(today) : log.count(today);
    final tint = special ? p.special : p.accent;

    final now = ref.watch(pulseProvider).value ?? DateTime.now();
    final nx = nextPrayer(now, ref.watch(prayerTimesProvider(today)),
        ref.watch(prayerTimesProvider(shift(today, 1))));

    String headline() {
      if (special) {
        return c == 5 ? 'MashaAllah, aaj ka dhikr poora' : 'Aaj aapka special day hai';
      }
      if (c == 0) return 'Bismillah, shuru karein';
      if (c == 5) return 'MashaAllah! Aaj ki saari namaz poori';
      return '${5 - c} namaz baaki hain';
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      PageHeader(title: 'Namaz', subtitle: hijriText(hj)),
      const SizedBox(height: 14),
      AppCard(
        radius: 28,
        padding: const EdgeInsets.all(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: .22), p.surface],
        ),
        borderColor: tint.withValues(alpha: .3),
        child: Row(children: [
          ProgressRing(
            size: 92,
            stroke: 9,
            color: tint,
            value: c / 5,
            child: special
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, color: tint, size: 18),
                    Text('$c/5',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ])
                : Text('$c/5',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(headline(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 8),
              Pill('${prayers[nx.$1]} ${fmt(nx.$2)} · ${dur(nx.$2.difference(now))}',
                  tint,
                  icon: Icons.schedule),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        StatCard('Full-day streak', '$streak days', Icons.local_fire_department_outlined),
        const SizedBox(width: 8),
        StatCard('This month', '${log.sum('${today.year}${p2(today.month)}')}',
            Icons.calendar_today_outlined),
        const SizedBox(width: 8),
        StatCard('$year total', '${log.sum('$year')}', Icons.insights_outlined),
      ]),
      const SizedBox(height: 14),
      const SpecialCard(),
      PrayerTiles(today),
      const SizedBox(height: 10),
      AppCard(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(children: [
          Row(children: [
            IconButton(
                tooltip: 'Pichla saal',
                onPressed: () => _setYear(year - 1),
                icon: const Icon(Icons.chevron_left)),
            Expanded(
                child: Center(
                    child: Text('$year overview',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)))),
            IconButton(
                tooltip: 'Agla saal',
                onPressed: () => _setYear(year + 1),
                icon: const Icon(Icons.chevron_right)),
          ]),
          SingleChildScrollView(
            controller: sc,
            scrollDirection: Axis.horizontal,
            child: RepaintBoundary(
              child: CustomPaint(
                  size: const Size(54 * HeatPainter.cell,
                      HeatPainter.top + 7 * HeatPainter.cell),
                  painter: HeatPainter(log, slog, restOn ? rest : null, year, p)),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (restOn) ...[
              _swatch(p.special.withValues(alpha: .4)),
              const SizedBox(width: 4),
              Text('Special', style: TextStyle(color: p.muted, fontSize: 12)),
              const SizedBox(width: 14),
            ],
            Text('Kam', style: TextStyle(color: p.muted, fontSize: 12)),
            const SizedBox(width: 6),
            for (var n = 0; n <= 5; n++)
              _swatch(n == 0 ? p.surface2 : p.accent.withValues(alpha: .22 + .16 * n)),
            const SizedBox(width: 6),
            Text('Zyada', style: TextStyle(color: p.muted, fontSize: 12)),
            const SizedBox(width: 8),
          ]),
        ]),
      ),
    ]);
  }

  Widget _swatch(Color c) => Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(3), color: c));
}

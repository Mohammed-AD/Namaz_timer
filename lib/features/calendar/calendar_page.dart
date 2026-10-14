import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/constants.dart';
import '../../core/events.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/log_provider.dart';
import '../../providers/rest_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';
import '../namaz/prayer_tiles.dart';
import 'special_history.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});
  @override
  ConsumerState<CalendarPage> createState() => _CalState();
}

class _CalState extends ConsumerState<CalendarPage> {
  late int hy, hm;
  DateTime sel = dayOnly(DateTime.now());
  final hc = HijriCalendar();

  int get _adj => ref.read(settingsProvider).hijriAdj;

  @override
  void initState() {
    super.initState();
    final n = HijriCalendar.now();
    hy = n.hYear;
    hm = n.hMonth;
  }

  /// Gregorian date of Hijri (hy, hm, d), corrected by the user's adjustment.
  DateTime _greg(int d) =>
      dayOnly(shift(hc.hijriToGregorian(hy, hm, d), -_adj));

  void _move(int delta) {
    setState(() {
      final selDay = hijriOf(sel, _adj).hDay;
      hm += delta;
      if (hm > 12) {
        hm = 1;
        hy++;
      }
      if (hm < 1) {
        hm = 12;
        hy--;
      }
      sel = _greg(math.min(selDay, hc.getDaysInMonth(hy, hm)));
    });
  }

  void _goToday() => setState(() {
        final t = ref.read(todayProvider);
        final h = hijriOf(t, _adj);
        hy = h.hYear;
        hm = h.hMonth;
        sel = t;
      });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final adj = ref.watch(settingsProvider.select((s) => s.hijriAdj));
    final today = ref.watch(todayProvider);
    final log = ref.watch(logProvider);
    final slog = ref.watch(specialLogProvider);
    final restOn = ref.watch(restEnabledProvider);
    final rest = ref.watch(restProvider);

    final days = hc.getDaysInMonth(hy, hm);
    final first = _greg(1);
    final last = _greg(days);
    final lead = first.weekday % 7;
    final selH = hijriOf(sel, adj);
    final ev = islamicEvent(selH.hMonth, selH.hDay);
    final selRange = restOn ? rest.rangeOf(sel) : null;
    var monthSpecial = 0;
    if (restOn) {
      for (var d = 1; d <= days; d++) {
        if (rest.isRest(_greg(d))) monthSpecial++;
      }
    }

    Widget dayCell(int d) {
      final g = _greg(d);
      final isSel = g == sel;
      final isToday = g == today;
      final isSpecial = restOn && rest.isRest(g);
      final c = isSpecial ? slog.count(g) : log.count(g);
      final e = islamicEvent(hm, d);
      final tint = isSpecial ? p.special : p.accent;
      // Special days form one connected band (rounded only at the two ends
      // of a run and at the week edges).
      final col = (lead + d - 1) % 7;
      final joinL = isSpecial && rest.isRest(shift(g, -1)) && col != 0;
      final joinR = isSpecial && rest.isRest(shift(g, 1)) && col != 6;
      final band = isSpecial && !isSel;
      final rad = band
          ? BorderRadius.horizontal(
              left: Radius.circular(joinL ? 0 : 14),
              right: Radius.circular(joinR ? 0 : 14))
          : BorderRadius.circular(14);
      return InkWell(
        borderRadius: rad,
        onTap: () => setState(() => sel = g),
        child: Container(
          margin: band
              ? EdgeInsets.fromLTRB(joinL ? 0 : 2, 2, joinR ? 0 : 2, 2)
              : const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: rad,
            color: isSel
                ? p.accent
                : isSpecial
                    ? p.special.withValues(alpha: .2)
                    : p.surface,
            border: Border.all(
                color: isToday && !isSel ? p.accent : Colors.transparent,
                width: 1.5),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$d',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isSel
                        ? p.onAccent
                        : (e?.major ?? false)
                            ? p.gold
                            : p.text)),
            Text('${g.day}',
                style: TextStyle(
                    fontSize: 10,
                    color: isSel ? p.onAccent.withValues(alpha: .7) : p.faint)),
            const SizedBox(height: 2),
            if (isSpecial)
              Icon(Icons.auto_awesome,
                  size: 10,
                  color: isSel
                      ? p.onAccent
                      : p.special.withValues(alpha: (.55 + .09 * c).clamp(0.0, 1.0)))
            else
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c == 0
                          ? Colors.transparent
                          : (isSel
                              ? p.onAccent
                              : tint.withValues(alpha: .35 + .13 * c)))),
          ]),
        ),
      );
    }

    return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const PageHeader(title: 'Calendar'),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(children: [
              Row(children: [
                IconButton(
                    tooltip: 'Pichla mahina',
                    onPressed: () => _move(-1),
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Column(children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('${hMonths[hm - 1]} $hy AH',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                          first.month == last.month
                              ? '${months[first.month - 1]} ${first.year}'
                              : '${months[first.month - 1]} - ${months[last.month - 1]} ${last.year}',
                          style: TextStyle(fontSize: 12, color: p.muted)),
                    ),
                  ]),
                ),
                IconButton(
                    tooltip: 'Aaj',
                    onPressed: _goToday,
                    icon: const Icon(Icons.today)),
                IconButton(
                    tooltip: 'Agla mahina',
                    onPressed: () => _move(1),
                    icon: const Icon(Icons.chevron_right)),
              ]),
              Row(children: [
                for (final d in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                  Expanded(
                      child: Center(
                          child: Text(d,
                              style: TextStyle(
                                  color: d == 'F' ? p.gold : p.muted,
                                  fontWeight: FontWeight.w800))))
              ]),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < lead; i++) const SizedBox(),
                  for (var d = 1; d <= days; d++) dayCell(d),
                ],
              ),
              if (restOn) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: p.special.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text('Special days · namaz tracking paused',
                        style: TextStyle(color: p.muted, fontSize: 12)),
                  ]),
                ),
                if (monthSpecial > 0) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('$monthSpecial special ${monthSpecial == 1 ? 'day' : 'days'} this month',
                        style: TextStyle(
                            color: p.special,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ]),
          ),
          const SizedBox(height: 14),
          Text(
              '${weekdays[sel.weekday - 1]}, ${sel.day} ${months[sel.month - 1]} ${sel.year}  ·  ${hijriText(selH)}',
              style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
          if (restOn && rest.isRest(sel)) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Pill('Special day · namaz tracking paused', p.special,
                  icon: Icons.auto_awesome),
            ),
          ],
          if (selRange != null) ...[
            const SizedBox(height: 8),
            AppCard(
              radius: 18,
              padding: const EdgeInsets.all(12),
              color: p.specialSoft,
              borderColor: p.special.withValues(alpha: .35),
              child: Builder(builder: (_) {
                final n = daysBetween(selRange.startDate, sel) + 1;
                final total = selRange.length(today);
                final ongoing = selRange.end == null;
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          ongoing ? 'Day $n · ongoing' : 'Day $n of $total',
                          style: TextStyle(
                              color: p.special,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                          ongoing
                          ? 'Started ${fmtDay(selRange.startDate, today)} · $total ${total == 1 ? 'day' : 'days'} so far'
                              : '${fmtDay(selRange.startDate, today)} to ${fmtDay(selRange.lastDay(today), today)} · $total ${total == 1 ? 'day' : 'days'} in total',
                          style: TextStyle(color: p.muted, fontSize: 12)),
                    ]);
              }),
            ),
          ],
          if (ev != null) ...[
            const SizedBox(height: 8),
            Align(
                alignment: Alignment.centerLeft,
                child: Pill(ev.name, p.gold,
                    icon: ev.major
                        ? Icons.star_rounded
                        : Icons.brightness_2_outlined)),
          ],
          const SizedBox(height: 10),
          PrayerTiles(sel),
          const SpecialHistoryCard(),
        ]);
  }
}

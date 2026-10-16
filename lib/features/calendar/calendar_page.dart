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
  late DateTime sel;
  final hc = HijriCalendar();

  @override
  void initState() {
    super.initState();
    sel = dayOnly(ref.read(todayProvider));
    final initial = hijriOf(sel, ref.read(settingsProvider).hijriAdj);
    hy = initial.hYear;
    hm = initial.hMonth;
  }

  /// Gregorian date for a Hijri day, adjusted to the user's moon-sighting setting.
  DateTime _greg(int day, int adj) =>
      dayOnly(shift(hc.hijriToGregorian(hy, hm, day), -adj));

  void _move(int delta, int adj) {
    setState(() {
      final selectedHijriDay = hijriOf(sel, adj).hDay;
      hm += delta;
      if (hm > 12) {
        hm = 1;
        hy++;
      } else if (hm < 1) {
        hm = 12;
        hy--;
      }
      sel = _greg(math.min(selectedHijriDay, hc.getDaysInMonth(hy, hm)), adj);
    });
  }

  void _goToday(int adj) => setState(() {
        final t = dayOnly(ref.read(todayProvider));
        final h = hijriOf(t, adj);
        hy = h.hYear;
        hm = h.hMonth;
        sel = t;
      });

  List<_UpcomingEvent> _upcomingEvents(DateTime today, int adj) {
    final result = <_UpcomingEvent>[];
    String? previousName;
    // A year-long scan makes the card useful even at the end of the Hijri year.
    // Multi-day observances are shown once, on their first day.
    for (var offset = 0; offset <= 370 && result.length < 4; offset++) {
      final date = shift(today, offset);
      final h = hijriOf(date, adj);
      final event = islamicEvent(h.hMonth, h.hDay);
      if (event != null && event.major && event.name != previousName) {
        result.add(_UpcomingEvent(
          date: date,
          name: event.name,
          major: event.major,
          hijriDay: h.hDay,
          hijriMonth: h.hMonth,
          hijriYear: h.hYear,
        ));
      }
      previousName = event?.name;
    }
    return result;
  }

  Future<void> _startToday(DateTime today) async {
    final rest = ref.read(restProvider);
    if (!rest.canStart(today)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please review the previous record before starting a new one.'),
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a special-day record?'),
        content: Text(
          'Start the record from today, ${fmtDay(today, today)}. Namaz tracking will pause for these recorded dates, and the calendar will show your dhikr routine instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start today'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final latest = ref.read(restProvider);
      if (latest.canStart(today)) {
        ref.read(restProvider.notifier).start(today);
      }
    }
  }

  Future<void> _endOpenRun(DateTime today, RestRange open) async {
    final start = dayOnly(open.startDate);
    if (start.isAfter(today)) return;
    final lastDay = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: start,
      lastDate: today,
      helpText: 'Select your last special day',
      confirmText: 'Choose date',
    );
    if (lastDay == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish this record?'),
        content: Text(
          'Last special day: ${fmtDay(lastDay, today)}. Namaz tracking resumes from the next day.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(restProvider.notifier).endLast(lastDay);
    }
  }

  Widget _dayCell({
    required BuildContext context,
    required int day,
    required int lead,
    required int adj,
    required DateTime today,
    required RestState rest,
    required bool restOn,
    required Map<DateTime, int> prayerCounts,
    required Map<DateTime, int> dhikrCounts,
  }) {
    final p = context.pal;
    final g = _greg(day, adj);
    final isSelected = g == sel;
    final isToday = g == today;
    final isSpecial = restOn && rest.isRest(g);
    final e = islamicEvent(hm, day);
    final count = isSpecial
        ? (dhikrCounts[g] ?? 0)
        : (prayerCounts[g] ?? 0);
    final col = (lead + day - 1) % 7;
    final joinsLeft = isSpecial && rest.isRest(shift(g, -1)) && col != 0;
    final joinsRight = isSpecial && rest.isRest(shift(g, 1)) && col != 6;
    final band = isSpecial && !isSelected;
    final radius = band
        ? BorderRadius.horizontal(
            left: Radius.circular(joinsLeft ? 0 : 13),
            right: Radius.circular(joinsRight ? 0 : 13),
          )
        : BorderRadius.circular(15);
    final markerColor = isSelected ? p.onAccent : p.accent;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${hijriText(hijriOf(g, adj))}, ${g.day} ${months[g.month - 1]} ${g.year}'
          '${isToday ? ', today' : ''}'
          '${isSpecial ? ', special day, namaz tracking paused' : ''}'
          '${e == null ? '' : ', ${e.name}'}',
      child: InkWell(
        borderRadius: radius,
        onTap: () => setState(() => sel = g),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: band
              ? EdgeInsets.fromLTRB(joinsLeft ? 0 : 2, 2, joinsRight ? 0 : 2, 2)
              : const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: isSelected
                ? p.accent
                : isSpecial
                    ? p.special.withValues(alpha: .18)
                    : isToday
                        ? p.accent.withValues(alpha: .07)
                        : p.surface,
            border: Border.all(
              color: isToday && !isSelected
                  ? p.accent.withValues(alpha: .75)
                  : e?.major == true && !isSelected
                      ? p.gold.withValues(alpha: .55)
                      : Colors.transparent,
              width: 1.25,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$day',
                maxLines: 1,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: TextStyle(
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? p.onAccent
                      : e?.major == true
                          ? p.gold
                          : p.text,
                ),
              ),
              Text(
                '${g.day}',
                maxLines: 1,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: TextStyle(
                  fontSize: 9,
                  height: 1,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? p.onAccent.withValues(alpha: .72) : p.faint,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSpecial)
                      Icon(Icons.auto_awesome, size: 5, color: markerColor)
                    else if (count > 0)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: markerColor.withValues(
                            alpha: (.35 + .13 * count).clamp(0.0, 1.0).toDouble(),
                          ),
                        ),
                      ),
                    if (e != null) ...[
                      if (isSpecial || count > 0) const SizedBox(width: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? p.onAccent : p.gold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final adj = ref.watch(settingsProvider.select((s) => s.hijriAdj));
    final today = dayOnly(ref.watch(todayProvider));
    final log = ref.watch(logProvider);
    final specialLog = ref.watch(specialLogProvider);
    final restOn = ref.watch(restEnabledProvider);
    final rest = ref.watch(restProvider);

    final days = hc.getDaysInMonth(hy, hm);
    final first = _greg(1, adj);
    final last = _greg(days, adj);
    final lead = first.weekday % 7; // Sunday-first grid.
    final selectedHijri = hijriOf(sel, adj);
    final selectedEvent = islamicEvent(selectedHijri.hMonth, selectedHijri.hDay);
    final selectedRange = restOn ? rest.rangeOf(sel) : null;
    final activeRun = restOn ? rest.open : null;
    final upcoming = _upcomingEvents(today, adj);
    final monthSpecial = restOn
        ? List<int>.generate(days, (i) => i + 1)
            .where((d) => rest.isRest(_greg(d, adj)))
            .length
        : 0;

    final prayerCounts = <DateTime, int>{};
    final dhikrCounts = <DateTime, int>{};
    for (var d = 1; d <= days; d++) {
      final g = _greg(d, adj);
      prayerCounts[g] = log.count(g);
      dhikrCounts[g] = specialLog.count(g);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        const PageHeader(
          title: 'Calendar',
          subtitle: 'Hijri dates, notable days & your history',
        ),
        const SizedBox(height: 14),

        // Today's date gives the calendar a clear starting point and makes the
        // Gregorian/Hijri relationship easy to understand at a glance.
        AppCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.accent.withValues(alpha: .20), p.surface],
          ),
          borderColor: p.accent.withValues(alpha: .28),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 58,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(Icons.calendar_month_rounded, color: p.accent, size: 27),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TODAY · ${weekdays[today.weekday - 1].toUpperCase()}',
                        style: TextStyle(
                          color: p.muted,
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 3),
                    Text('${today.day} ${months[today.month - 1]} ${today.year}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(hijriText(hijriOf(today, adj)),
                        style: TextStyle(
                            color: p.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Jump to today',
                onPressed: () => _goToday(adj),
                icon: const Icon(Icons.my_location_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 13),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous Hijri month',
                    onPressed: () => _move(-1, adj),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${hMonths[hm - 1]} $hy AH',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            first.month == last.month && first.year == last.year
                                ? '${months[first.month - 1]} ${first.year}'
                                : '${months[first.month - 1]} ${first.year} – ${months[last.month - 1]} ${last.year}',
                            style: TextStyle(fontSize: 12, color: p.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Today',
                    onPressed: () => _goToday(adj),
                    icon: const Icon(Icons.today_rounded),
                  ),
                  IconButton(
                    tooltip: 'Next Hijri month',
                    onPressed: () => _move(1, adj),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Center(
                          child: Text(
                            ['S', 'M', 'T', 'W', 'T', 'F', 'S'][i],
                            style: TextStyle(
                              color: i == 5 ? p.gold : p.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 7,
                // Slightly taller cells leave room for both calendars and their
                // markers on compact Android displays and with larger text.
                childAspectRatio: 0.92,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                  for (var d = 1; d <= days; d++)
                    _dayCell(
                      context: context,
                      day: d,
                      lead: lead,
                      adj: adj,
                      today: today,
                      rest: rest,
                      restOn: restOn,
                      prayerCounts: prayerCounts,
                      dhikrCounts: dhikrCounts,
                    ),
                  for (var i = 0; i < (7 - ((lead + days) % 7)) % 7; i++)
                    const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _LegendDot(color: p.gold, label: 'Notable Hijri date'),
                    if (restOn)
                      _LegendDot(color: p.special, label: 'Special days'),
                    _LegendDot(color: p.accent, label: 'Prayer / dhikr logged'),
                  ],
                ),
              ),
              if (restOn && monthSpecial > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: p.special.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: p.special),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$monthSpecial special ${monthSpecial == 1 ? 'day' : 'days'} in this month',
                          style: TextStyle(
                              color: p.special, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),
        if (upcoming.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 19, color: p.gold),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Upcoming notable dates',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Text('Hijri', style: TextStyle(fontSize: 11, color: p.muted)),
            ],
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
            child: Column(
              children: [
                for (var i = 0; i < math.min(3, upcoming.length); i++) ...[
                  if (i > 0) Divider(height: 1, color: p.line),
                  _UpcomingEventTile(event: upcoming[i], today: today),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 7, 4, 0),
            child: Text(
              'Hijri dates can vary with local moon sighting. Treat these dates as a guide and follow your local mosque or authority.',
              style: TextStyle(color: p.muted, fontSize: 11, height: 1.35),
            ),
          ),
          const SizedBox(height: 14),
        ],

        Text(
          '${weekdays[sel.weekday - 1]}, ${sel.day} ${months[sel.month - 1]} ${sel.year}',
          style: TextStyle(color: p.muted, fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 7),
        AppCard(
          radius: 22,
          padding: const EdgeInsets.all(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.surface2, p.surface],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text('${selectedHijri.hDay}',
                        style: TextStyle(
                            color: p.accent, fontSize: 23, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hMonths[selectedHijri.hMonth - 1],
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        Text('${selectedHijri.hYear} AH · ${fmtDay(sel, today)}',
                            style: TextStyle(color: p.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (sel == today)
                    Pill('TODAY', p.accent, icon: Icons.check_circle_outline),
                ],
              ),
              if (restOn && rest.isRest(sel)) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Pill('Special day · namaz tracking paused', p.special,
                      icon: Icons.auto_awesome_rounded),
                ),
              ],
              if (selectedEvent != null) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: p.line),
                const SizedBox(height: 11),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      selectedEvent.major
                          ? Icons.star_rounded
                          : Icons.nights_stay_outlined,
                      color: p.gold,
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(selectedEvent.name,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(
                            selectedEvent.major
                                ? 'Notable Hijri date · exact date may vary by local moon sighting.'
                                : 'Suggested observance · follow the guidance of your local community.',
                            style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (selectedRange != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.special.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: p.special.withValues(alpha: .2)),
                  ),
                  child: Builder(builder: (_) {
                    final dayNo = daysBetween(selectedRange.startDate, sel) + 1;
                    final total = selectedRange.length(today);
                    final ongoing = selectedRange.end == null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 18, color: p.special),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                ongoing ? 'Day $dayNo · in progress' : 'Day $dayNo of $total',
                                style: TextStyle(
                                    color: p.special, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ongoing
                              ? 'Started ${fmtDay(selectedRange.startDate, today)} · $total ${total == 1 ? 'day' : 'days'} so far'
                              : '${fmtDay(selectedRange.startDate, today)} – ${fmtDay(selectedRange.lastDay(today), today)} · $total ${total == 1 ? 'day' : 'days'} in total',
                          style: TextStyle(color: p.muted, fontSize: 12),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Prayer & dhikr log',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        PrayerTiles(sel),

        if (restOn) ...[
          const SizedBox(height: 4),
          AppCard(
            radius: 22,
            padding: const EdgeInsets.all(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.special.withValues(alpha: .12), p.surface],
            ),
            borderColor: p.special.withValues(alpha: .28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.special.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.favorite_outline_rounded, color: p.special),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Special days tracker',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(
                            activeRun == null
                                ? '${rest.ranges.length} ${rest.ranges.length == 1 ? 'record' : 'records'} saved'
                                : 'Day ${activeRun.length(today)} · ongoing',
                            style: TextStyle(color: p.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (activeRun != null)
                      Icon(Icons.circle, size: 8, color: p.special),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  activeRun == null
                      ? 'When your special days begin, record them here so the calendar pauses namaz tracking for those dates and keeps your dhikr routine available.'
                      : 'Your current record began ${fmtDay(activeRun.startDate, today)}. Your namaz streak is protected for the recorded days.',
                  style: TextStyle(color: p.muted, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: activeRun == null
                      ? FilledButton.icon(
                          onPressed: rest.canStart(today) ? () => _startToday(today) : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start a record today'),
                          style: FilledButton.styleFrom(
                            backgroundColor: p.special,
                            foregroundColor: p.onAccent,
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => _endOpenRun(today, activeRun),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Finish current record'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: p.special,
                            side: BorderSide(color: p.special.withValues(alpha: .6)),
                          ),
                        ),
                ),
                if (activeRun == null && !rest.canStart(today)) ...[
                  const SizedBox(height: 6),
                  Text(
                    'A saved record already covers today. Review your special-days history before starting another.',
                    style: TextStyle(color: p.muted, fontSize: 11, height: 1.35),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  'Personal dates are stored on this device. Cycle estimates are approximate and can vary.',
                  style: TextStyle(color: p.faint, fontSize: 10, height: 1.35),
                ),
              ],
            ),
          ),
          const SpecialHistoryCard(),
        ],
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: p.muted, fontSize: 10)),
      ],
    );
  }
}

class _UpcomingEvent {
  final DateTime date;
  final String name;
  final bool major;
  final int hijriDay, hijriMonth, hijriYear;

  const _UpcomingEvent({
    required this.date,
    required this.name,
    required this.major,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
  });
}

class _UpcomingEventTile extends StatelessWidget {
  final _UpcomingEvent event;
  final DateTime today;
  const _UpcomingEventTile({required this.event, required this.today});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final offset = daysBetween(today, event.date);
    final when = offset == 0
        ? 'Today'
        : offset == 1
            ? 'Tomorrow'
            : fmtDay(event.date, today);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.gold.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${event.hijriDay}',
                    style: TextStyle(
                        fontSize: 17, color: p.gold, fontWeight: FontWeight.w900)),
                Text('HIJRI',
                    maxLines: 1,
                    style: TextStyle(fontSize: 7, color: p.gold, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 3),
                Text(
                  '${event.hijriDay} ${hMonths[event.hijriMonth - 1]} ${event.hijriYear} AH · $when',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: 11, height: 1.25),
                ),
              ],
            ),
          ),
          if (event.major)
            Icon(Icons.star_rounded, size: 17, color: p.gold)
          else
            Icon(Icons.nights_stay_outlined, size: 16, color: p.faint),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/prayer_utils.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/holy_times_service.dart';
import '../../providers/prayer_times_provider.dart';
import '../../providers/settings_provider.dart';
import '../settings/times_editor_page.dart';

String _ageText(DateTime? time) {
  if (time == null) return 'abhi';
  final d = DateTime.now().difference(time);
  if (d.inSeconds < 60) return 'abhi';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  return '${d.inHours}h ago';
}

void showTimesSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _TimesSheet(),
  );
}

/// Full table: Makkah | Madinah | your city (with your own adjustments).
class _TimesSheet extends ConsumerWidget {
  const _TimesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final now = ref.watch(pulseProvider).value ?? DateTime.now();
    final today = dayAtOffset(now, holyUtcMinutes);
    final s = ref.watch(settingsProvider);
    final mineDay = dayOnly(now);
    final mine = ref.watch(prayerTimesProvider(mineDay)).five;
    final liveHoly = ref.watch(holyTimesProvider(today));
    final holy = liveHoly.asData?.value ?? localHolyTimes(today);
    final mk = holy.makkah.five, md = holy.madinah.five;

    TableRow row(String label, String a, String b, String c,
            {bool head = false, int? i}) =>
        TableRow(children: [
          for (final (n, t) in [(0, label), (1, a), (2, b), (3, c)])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Text(t,
                  textAlign: n == 0 ? TextAlign.left : TextAlign.center,
                  style: TextStyle(
                      fontSize: head ? 12 : 14,
                      fontWeight:
                          head || n == 0 ? FontWeight.w800 : FontWeight.w600,
                      color: head
                          ? (n == 3 ? p.accent : p.gold)
                          : (n == 3 && i != null && s.customAt(i)
                              ? p.accent
                              : p.text))),
            ),
        ]);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Namaz ke waqt',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ),
            IconButton(
              tooltip: 'Live timings refresh',
              onPressed: liveHoly.isLoading
                  ? null
                  : () {
                      ref.read(holyRefreshProvider.notifier).state++;
                      ref.invalidate(holyTimesProvider(today));
                    },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ]),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Icon(
                liveHoly.isLoading
                    ? Icons.sync_rounded
                    : holy.source == HolyTimesSource.liveApi
                        ? Icons.cloud_done_rounded
                        : holy.source == HolyTimesSource.cache
                            ? Icons.cloud_off_rounded
                            : Icons.offline_bolt_rounded,
                size: 15,
                color: holy.source == HolyTimesSource.liveApi
                    ? p.accent
                    : p.muted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  liveHoly.isLoading && !liveHoly.hasValue
                      ? 'Live timings sync ho rahe hain…'
                      : switch (holy.source) {
                          HolyTimesSource.liveApi =>
                            'Live · Umm al-Qura · synced ${_ageText(holy.fetchedAt)}',
                          HolyTimesSource.cache =>
                            'Cached · last sync ${_ageText(holy.fetchedAt)}',
                          HolyTimesSource.localCalculation =>
                            'Offline fallback · local Umm al-Qura',
                        },
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {0: FlexColumnWidth(1.1)},
            border: TableBorder(horizontalInside: BorderSide(color: p.line)),
            children: [
              row('', 'Makkah', 'Madinah', s.place.name, head: true),
              for (var i = 0; i < 5; i++)
                row(prayers[i], fmtZ(mk[i], holyUtcMinutes),
                    fmtZ(md[i], holyUtcMinutes), fmt(mine[i]),
                    i: i),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Makkah / Madinah: Saudi local time (UTC+3), Umm al-Qura.\n${s.place.name}: aapke set kiye hue waqt${s.anyCustom ? ' (hare = aapne badla)' : ''}.',
                style: TextStyle(color: p.muted, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          Builder(builder: (_) {
            final q = qiblaBearing(s.place);
            return Row(children: [
              Transform.rotate(
                  angle: q * 3.141592653589793 / 180,
                  child: Icon(Icons.navigation_rounded, size: 18, color: p.gold)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Qibla (${s.place.name}): ${q.toStringAsFixed(0)}° ${compassName(q)} (true north se)',
                    style: TextStyle(color: p.muted, fontSize: 12)),
              ),
            ]);
          }),
          const SizedBox(height: 8),
          Text(
            holy.warning ??
                'Live source: AlAdhan API. Local masjid / government schedules can differ by a few minutes.',
            style: TextStyle(color: p.muted, fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop();
                nav.push(MaterialPageRoute<void>(
                    builder: (_) => const TimesEditorPage()));
              },
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Apne namaz ke waqt set karein'),
            ),
          ),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/prayer_times_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';

/// Every masjid / area has slightly different timings, so the user sets each
/// prayer themselves: nudge by minutes, or pick an exact time.
class TimesEditorPage extends ConsumerWidget {
  const TimesEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final today = ref.watch(todayProvider);
    final cur = ref.watch(prayerTimesProvider(today)).five;
    final auto = ref.watch(autoTimesProvider(today)).five;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz ke waqt',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
              onPressed: s.anyCustom ? n.clearAllTimes : null,
              child: const Text('Sab reset')),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        AppCard(
          color: p.accentSoft,
          borderColor: p.accent.withValues(alpha: .3),
          child: Row(children: [
            Icon(Icons.info_outline, color: p.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  '${s.place.name} ke hisaab se waqt nikle hain. Apne masjid / ilaake ke waqt ke mutabik har namaz ko -/+ minute se badlein, ya "Waqt chuno" se exact waqt daalein. Yeh sab jagah (Namaz, Calendar, top corner) lagu hoga.',
                  style: TextStyle(fontSize: 13, color: p.text)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < 5; i++) ...[
          _Row(
            i: i,
            time: cur[i],
            autoTime: auto[i],
            custom: s.customAt(i),
            exact: s.fixed[i] >= 0,
            offset: s.offsets[i],
            onNudge: (d) => n.nudge(i, d),
            onClear: () => n.clearTime(i),
            onPick: () async {
              final t = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay(hour: cur[i].hour, minute: cur[i].minute),
                helpText: '${prayers[i]} ka waqt',
              );
              if (t != null) n.setFixed(i, t.hour * 60 + t.minute);
            },
          ),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final int i, offset;
  final DateTime time, autoTime;
  final bool custom, exact;
  final void Function(int) onNudge;
  final VoidCallback onClear, onPick;
  const _Row({
    required this.i,
    required this.time,
    required this.autoTime,
    required this.custom,
    required this.exact,
    required this.offset,
    required this.onNudge,
    required this.onClear,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final note = exact
        ? 'Aapka exact waqt · auto: ${fmt(autoTime)}'
        : offset != 0
            ? 'Auto ${fmt(autoTime)} ${offset > 0 ? '+' : '-'} ${offset.abs()} min'
            : 'Auto (calculated)';
    return AppCard(
      borderColor: custom ? p.accent.withValues(alpha: .5) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: p.accentSoft, borderRadius: BorderRadius.circular(14)),
            child: Icon(prayerIcons[i], color: p.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(prayers[i],
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              Text(note, style: TextStyle(fontSize: 12, color: p.muted)),
            ]),
          ),
          Text(fmt(time),
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: custom ? p.accent : p.text)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          IconButton.filledTonal(
              tooltip: '1 minute kam',
              onPressed: () => onNudge(-1),
              icon: const Icon(Icons.remove)),
          IconButton.filledTonal(
              tooltip: '1 minute zyada',
              onPressed: () => onNudge(1),
              icon: const Icon(Icons.add)),
          OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.schedule, size: 18),
              label: const Text('Waqt chuno')),
          if (custom)
            TextButton(onPressed: onClear, child: const Text('Auto karo')),
        ]),
      ]),
    );
  }
}

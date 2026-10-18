import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/log_provider.dart';
import '../../providers/rest_provider.dart';
import '../../widgets/common.dart';

/// "Special days" card. Invisible unless switched on in Settings.
/// Warm and positive on purpose: the user should feel looked after and still
/// connected to her routine - never "excluded".
class SpecialCard extends ConsumerWidget {
  const SpecialCard({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref, DateTime today) async {
    final from = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('When did your special days start?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          ),
          for (final o in const [
            (0, 'Today'),
            (1, 'Yesterday'),
            (2, 'The day before yesterday')
          ])
            ListTile(
                leading: Icon(Icons.auto_awesome, color: ctx.pal.special),
                title: Text(o.$2),
                subtitle: Text(fmtDay(shift(today, -o.$1), today)),
                onTap: () => Navigator.pop(ctx, shift(today, -o.$1))),
          ListTile(
            leading: Icon(Icons.edit_calendar_outlined, color: ctx.pal.special),
            title: const Text('Pick another date'),
            onTap: () async {
              final d = await showDatePicker(
                context: ctx,
                initialDate: today,
                firstDate: shift(today, -60),
                lastDate: today,
              );
              if (d != null && ctx.mounted) Navigator.pop(ctx, d);
            },
          ),
        ]),
      ),
    );
    if (from == null || !context.mounted) return;
    if (!ref.read(restProvider).canStart(from, today: today)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('That date overlaps a saved record. Choose a date after your previous record.'),
      ));
      return;
    }
    ref.read(restProvider.notifier).start(from);
  }

  Future<void> _end(BuildContext context, WidgetRef ref, DateTime today,
      RestRange open) async {
    final startDay = open.startDate;
    final last = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Which was your last special day?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Namaz tracking resumes from the next day.',
                    style: TextStyle(color: ctx.pal.muted, fontSize: 13))),
          ),
          for (final o in const [
            (0, 'Today'),
            (1, 'Yesterday'),
            (2, 'The day before yesterday')
          ])
            if (!shift(today, -o.$1).isBefore(startDay))
              ListTile(
                  leading: Icon(Icons.check_circle_outline, color: ctx.pal.special),
                  title: Text(o.$2),
                  subtitle: Text(fmtDay(shift(today, -o.$1), today)),
                  onTap: () => Navigator.pop(ctx, shift(today, -o.$1))),
        ]),
      ),
    );
    if (last != null && context.mounted) {
      ref.read(restProvider.notifier).endLast(last);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(restEnabledProvider)) return const SizedBox.shrink();
    final p = context.pal;
    final rest = ref.watch(restProvider);
    final today = ref.watch(todayProvider);
    final owed = ref.watch(fastsOwedProvider);
    final dhikrToday = ref.watch(specialLogProvider.select((m) => m.count(today)));
    final open = rest.open;
    final dayNo = open == null ? 0 : open.length(today);
    final prev = rest.finished.isEmpty ? null : rest.finished.last;
    final n = ref.read(restProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.special.withValues(alpha: open == null ? .08 : .22), p.surface],
        ),
        borderColor: p.special.withValues(alpha: .35),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.auto_awesome, color: p.special),
            const SizedBox(width: 10),
            Expanded(
              child: Text(open == null ? 'Special days' : 'Special day · Day $dayNo',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ),
            open == null
                ? FilledButton.tonal(
                    onPressed: () => _start(context, ref, today),
                    child: const Text('Start'))
                : OutlinedButton(
                    onPressed: () => _end(context, ref, today, open),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: p.special,
                        side: BorderSide(color: p.special.withValues(alpha: .6))),
                    child: const Text('End')),
          ]),
          if (open != null) ...[
            const SizedBox(height: 8),
            Pill(
                'Started ${fmtDay(open.startDate, today)} · $dayNo ${dayNo == 1 ? 'day' : 'days'} so far',
                p.special,
                icon: Icons.event_available_outlined),
            const SizedBox(height: 10),
            Text(
                'Your special-day record is active. This app pauses prayer tracking for these dates and offers a gentle dhikr or dua routine instead. Your prayer history and streak are preserved.',
                style: TextStyle(color: p.muted, fontSize: 13, height: 1.4)),
            const SizedBox(height: 14),
            Row(children: [
              Text('Dhikr at prayer times today',
                  style: TextStyle(
                      color: p.muted, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$dhikrToday / 5',
                  style: TextStyle(
                      color: p.special, fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: dhikrToday / 5),
                duration: const Duration(milliseconds: 400),
                builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    color: p.special,
                    backgroundColor: p.special.withValues(alpha: .15)),
              ),
            ),
          ] else if (prev != null) ...[
            const SizedBox(height: 8),
            Text(
                'Last time: ${prev.length(today)} days (${fmtDay(prev.startDate, today)} - ${fmtDay(prev.lastDay(today), today)})',
                style: TextStyle(color: p.muted, fontSize: 13)),
          ] else ...[
            const SizedBox(height: 6),
            Text('Tap Start when your special days begin.',
                style: TextStyle(color: p.muted, fontSize: 13)),
          ],
          if (owed > 0 || open != null) ...[
            Divider(height: 26, color: p.line),
            Row(children: [
              Icon(Icons.nights_stay_outlined, size: 18, color: p.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Qada fasts remaining',
                    style: TextStyle(color: p.muted, fontWeight: FontWeight.w600)),
              ),
              Text('$owed',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              OutlinedButton.icon(
                  onPressed: owed > 0 ? n.fastMadeUp : null,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Made up one')),
              TextButton.icon(
                  onPressed: n.fastAdd,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add one')),
            ]),
          ],
        ]),
      ),
    );
  }
}

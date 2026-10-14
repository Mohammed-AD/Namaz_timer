import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/rest_provider.dart';
import '../../widgets/common.dart';

/// Record of every special-days run: dates, duration, averages and a gentle
/// estimate of the next one. Invisible unless the feature is on.
class SpecialHistoryCard extends ConsumerWidget {
  const SpecialHistoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(restEnabledProvider)) return const SizedBox.shrink();
    final p = context.pal;
    final rest = ref.watch(restProvider);
    final today = ref.watch(todayProvider);
    final avgLen = rest.avgLength(today);
    final cycle = rest.avgCycle();

    DateTime? next;
    if (cycle != null && rest.open == null && rest.ranges.isNotEmpty) {
      final e = rest.ranges.last.startDate.add(Duration(days: cycle));
      if (!dayOnly(e).isBefore(today)) next = dayOnly(e);
    }

    // Newest first, but keep the real index so delete removes the right one.
    final order = [for (var i = rest.ranges.length - 1; i >= 0; i--) i];
    final shown = order.take(6).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: AppCard(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.special.withValues(alpha: .1), p.surface],
        ),
        borderColor: p.special.withValues(alpha: .3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.auto_awesome, color: p.special, size: 20),
            const SizedBox(width: 8),
            const Text('Special days record',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          if (rest.ranges.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
                'No records yet. Tap Start on the Namaz tab and the dates and duration of each time will be saved here.',
                style: TextStyle(color: p.muted, fontSize: 13, height: 1.35)),
          ] else ...[
            const SizedBox(height: 12),
            Row(children: [
              if (avgLen != null)
                Expanded(
                    child: _stat(context, 'Average length', '${avgLen.round()} days')),
              if (cycle != null)
                Expanded(child: _stat(context, 'Cycle', '~$cycle days')),
              Expanded(
                  child: _stat(context, 'Times logged', '${rest.ranges.length}')),
            ]),
            if (next != null) ...[
              const SizedBox(height: 10),
              Text(
                  'Next expected: ~${fmtDay(next, today)} (an estimate only; it can vary from month to month)',
                  style: TextStyle(color: p.muted, fontSize: 12, height: 1.35)),
            ],
            const SizedBox(height: 10),
            Divider(height: 1, color: p.line),
            for (final i in shown) _row(context, ref, rest.ranges[i], i, today),
          ],
        ]),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      Text(label, style: TextStyle(fontSize: 11, color: p.muted)),
    ]);
  }

  Widget _row(BuildContext context, WidgetRef ref, RestRange r, int index,
      DateTime today) {
    final p = context.pal;
    final len = r.length(today);
    final ongoing = r.end == null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: ongoing ? p.special : p.faint),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
              ongoing
                  ? '${fmtDay(r.startDate, today)} onwards · ongoing'
                  : '${fmtDay(r.startDate, today)} - ${fmtDay(r.lastDay(today), today)}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Text('$len ${len == 1 ? 'day' : 'days'}',
            style: TextStyle(color: p.special, fontWeight: FontWeight.w800)),
        IconButton(
          tooltip: 'Delete this record',
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.delete_outline, size: 20, color: p.faint),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete this record?'),
                content: const Text(
                    'Use this to remove an entry made by mistake. Namaz for those days will be tracked again.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete')),
                ],
              ),
            );
            if (ok == true) ref.read(restProvider.notifier).removeAt(index);
          },
        ),
      ]),
    );
  }
}

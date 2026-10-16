import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/rest_provider.dart';
import '../../widgets/common.dart';

/// Private, on-device record of special-day runs with gentle, clearly labelled
/// estimates. The UI intentionally avoids treating cycle estimates as promises.
class SpecialHistoryCard extends ConsumerWidget {
  const SpecialHistoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(restEnabledProvider)) return const SizedBox.shrink();
    final p = context.pal;
    final rest = ref.watch(restProvider);
    final today = ref.watch(todayProvider);
    final averageLength = rest.avgLength(today);
    final cycle = rest.avgCycle();

    DateTime? nextEstimate;
    if (cycle != null && rest.open == null && rest.ranges.isNotEmpty) {
      final candidate = dayOnly(rest.ranges.last.startDate.add(Duration(days: cycle)));
      if (!candidate.isBefore(today)) nextEstimate = candidate;
    }

    // Show newest first, but retain the true index for deleting a record.
    final newestFirst = [for (var i = rest.ranges.length - 1; i >= 0; i--) i];
    final shown = newestFirst.take(6).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        radius: 22,
        padding: const EdgeInsets.all(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.special.withValues(alpha: .09), p.surface],
        ),
        borderColor: p.special.withValues(alpha: .28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.special.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.history_rounded, color: p.special),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Special days history',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('Your saved records, newest first',
                          style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                if (rest.ranges.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.special.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${rest.ranges.length}',
                        style: TextStyle(color: p.special, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
            if (rest.ranges.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.event_note_rounded, color: p.special, size: 21),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'No records yet. Use “Start a record today” above when your special days begin. The calendar will save the dates and keep your dhikr routine available.',
                        style: TextStyle(fontSize: 12, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 13),
              Row(
                children: [
                  if (averageLength != null)
                    Expanded(
                      child: _Stat(
                        value: '${averageLength.round()} days',
                        label: 'Avg. duration',
                        icon: Icons.timelapse_rounded,
                      ),
                    ),
                  if (cycle != null)
                    Expanded(
                      child: _Stat(
                        value: '~$cycle days',
                        label: 'Avg. cycle',
                        icon: Icons.repeat_rounded,
                      ),
                    ),
                  Expanded(
                    child: _Stat(
                      value: '${rest.ranges.length}',
                      label: 'Records',
                      icon: Icons.event_available_outlined,
                    ),
                  ),
                ],
              ),
              if (nextEstimate != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.gold.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: p.gold.withValues(alpha: .2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: p.gold, size: 19),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rough next-date estimate',
                                style: TextStyle(
                                    color: p.gold, fontWeight: FontWeight.w800, fontSize: 12)),
                            const SizedBox(height: 3),
                            Text('Around ${fmtDay(nextEstimate, today)} · based only on past start dates.',
                                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 9),
              Text(
                'Duration and cycle values are estimates, not predictions. Dates can vary from month to month.',
                style: TextStyle(color: p.muted, fontSize: 11, height: 1.35),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: p.line),
              for (final index in shown)
                _RecordRow(
                  range: rest.ranges[index],
                  index: index,
                  today: today,
                ),
              if (rest.ranges.length > shown.length) ...[
                const SizedBox(height: 8),
                Text(
                  'Showing the latest ${shown.length} of ${rest.ranges.length} records.',
                  style: TextStyle(color: p.muted, fontSize: 11),
                ),
              ],
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: p.faint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Stored on this device; include it in your manual backup if needed.',
                    style: TextStyle(color: p.faint, fontSize: 10, height: 1.35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _Stat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 10, 7, 10),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: p.special, size: 16),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: p.muted)),
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends ConsumerWidget {
  final RestRange range;
  final int index;
  final DateTime today;
  const _RecordRow({required this.range, required this.index, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final length = range.length(today);
    final ongoing = range.end == null;
    final rangeLabel = ongoing
        ? '${fmtDay(range.startDate, today)} onwards · ongoing'
        : '${fmtDay(range.startDate, today)} – ${fmtDay(range.lastDay(today), today)}';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ongoing ? p.special : p.faint,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rangeLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                if (ongoing)
                  Text('Day $length in progress',
                      style: TextStyle(color: p.special, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$length ${length == 1 ? 'day' : 'days'}',
              style: TextStyle(color: p.special, fontSize: 12, fontWeight: FontWeight.w900)),
          IconButton(
            tooltip: 'Delete this record',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline_rounded, size: 20, color: p.faint),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete this record?'),
                  content: Text(
                    'Remove $rangeLabel? This cannot be undone. The calendar will stop treating these dates as special days, and the normal prayer log for those dates will show again.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Keep record'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete record'),
                    ),
                  ],
                ),
              );
              if (ok == true) ref.read(restProvider.notifier).removeAt(index);
            },
          ),
        ],
      ),
    );
  }
}

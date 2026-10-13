import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/rest_provider.dart';

/// Discreet "rest days" card. Invisible unless switched on in Settings.
/// Wording is deliberately neutral: "Aaram" (rest) - nothing explicit on screen.
class RestCard extends ConsumerWidget {
  const RestCard({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref, DateTime today) async {
    final p = context.pal;
    final back = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: p.surface,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Aaram kab se shuru hua?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          ),
          for (final o in const [(0, 'Aaj se'), (1, 'Kal se'), (2, 'Parso se')])
            ListTile(
                leading: Icon(Icons.nightlight_round, color: p.gold),
                title: Text(o.$2),
                onTap: () => Navigator.pop(ctx, o.$1)),
        ]),
      ),
    );
    if (back != null) ref.read(restProvider.notifier).start(shift(today, -back));
  }

  Future<void> _end(BuildContext context, WidgetRef ref, DateTime today) async {
    final p = context.pal;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: const Text('Aaram mode khatam karein?'),
        content: const Text('Aaj se namaz dobara track hogi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abhi nahi')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Haan, khatam')),
        ],
      ),
    );
    if (ok == true) ref.read(restProvider.notifier).end(today);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    if (!ref.watch(restEnabledProvider)) return const SizedBox.shrink();
    final rest = ref.watch(restProvider);
    final today = ref.watch(todayProvider);
    final owed = ref.watch(fastsOwedProvider);
    final open = rest.open;
    final dayNo = open == null
        ? 0
        : math.max(
            1, (today.difference(parseKey(open.start)).inHours / 24).round() + 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: p.gold.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.gold.withValues(alpha: .35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.nightlight_round, color: p.gold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(open == null ? 'Aaram mode' : 'Aaram ke din · Din $dayNo',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          open == null
              ? OutlinedButton(
                  onPressed: () => _start(context, ref, today),
                  child: const Text('Shuru'))
              : TextButton(
                  onPressed: () => _end(context, ref, today),
                  child: const Text('Khatam')),
        ]),
        if (open != null) ...[
          const SizedBox(height: 4),
          const Text(
              'Aaj namaz maaf hai, track nahi hogi. Streak safe hai. Dhikr aur dua jaari rakh sakte hain.',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
        ],
        if (owed > 0 || open != null) ...[
          const Divider(height: 20, color: Colors.white12),
          Row(children: [
            Expanded(
              child: Text('Qada roze baaki: $owed',
                  style: const TextStyle(color: Colors.white70)),
            ),
            IconButton(
                tooltip: 'Ek qada roza rakha',
                onPressed: owed > 0
                    ? () => ref.read(restProvider.notifier).fastMadeUp()
                    : null,
                icon: const Icon(Icons.check_circle_outline)),
            IconButton(
                tooltip: 'Ek roza add karo',
                onPressed: () => ref.read(restProvider.notifier).fastAdd(),
                icon: const Icon(Icons.add_circle_outline)),
          ]),
        ],
      ]),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/rest_provider.dart';
import '../../widgets/common.dart';

/// "Special days" card. Invisible unless switched on in Settings.
/// Warm and positive on purpose: the user should feel looked after and still
/// connected to her routine - never "excluded".
class SpecialCard extends ConsumerWidget {
  const SpecialCard({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref, DateTime today) async {
    final back = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Special days kab se shuru hue?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          ),
          for (final o in const [(0, 'Aaj se'), (1, 'Kal se'), (2, 'Parso se')])
            ListTile(
                leading: Icon(Icons.auto_awesome, color: ctx.pal.special),
                title: Text(o.$2),
                onTap: () => Navigator.pop(ctx, o.$1)),
        ]),
      ),
    );
    if (back != null) ref.read(restProvider.notifier).start(shift(today, -back));
  }

  Future<void> _end(BuildContext context, WidgetRef ref, DateTime today) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Special days khatam karein?'),
        content: const Text('Aaj se namaz dobara track hogi. Aapki streak safe hai.'),
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
    if (!ref.watch(restEnabledProvider)) return const SizedBox.shrink();
    final p = context.pal;
    final rest = ref.watch(restProvider);
    final today = ref.watch(todayProvider);
    final owed = ref.watch(fastsOwedProvider);
    final open = rest.open;
    final dayNo = open == null
        ? 0
        : math.max(
            1, (today.difference(parseKey(open.start)).inHours / 24).round() + 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
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
              child: Text(open == null ? 'Special days' : 'Special day · Din $dayNo',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
            const SizedBox(height: 6),
            Text(
                'Aaj namaz maaf hai, yeh Allah ki aasaani hai. Har namaz ke waqt thoda dhikr ya dua karke judi rahein. Aapki streak safe hai aur kuch miss nahi hua.',
                style: TextStyle(color: p.muted, fontSize: 13, height: 1.35)),
          ],
          if (owed > 0 || open != null) ...[
            Divider(height: 22, color: p.line),
            Row(children: [
              Expanded(
                child: Text('Qada roze baaki: $owed',
                    style: TextStyle(color: p.muted)),
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
      ),
    );
  }
}

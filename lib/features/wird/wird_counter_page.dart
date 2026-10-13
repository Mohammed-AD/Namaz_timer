import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/wird_provider.dart';
import '../../widgets/common.dart';
import 'wird_editor.dart';

/// Full-screen tasbih-style counter for one wird.
class WirdCounterPage extends ConsumerWidget {
  final String id;
  const WirdCounterPage(this.id, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final items = ref.watch(wirdProvider);
    final found = items.where((e) => e.id == id);
    if (found.isEmpty) return const Scaffold(body: SizedBox());
    final item = found.first;
    final n = ref.read(wirdProvider.notifier);
    final c = item.countFor(dayKey(DateTime.now()));
    final done = c >= item.target;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              tooltip: 'Badlein',
              onPressed: () => showWirdEditor(context, item: item),
              icon: const Icon(Icons.edit_outlined)),
          IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final nav = Navigator.of(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('"${item.name}" delete karein?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Nahi')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok == true) {
                  n.remove(item.id);
                  nav.pop();
                }
              }),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (item.arabic.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(item.arabic,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, color: p.muted)),
              ),
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                BoxShadow(
                    color: p.accent.withValues(alpha: .18),
                    blurRadius: 50,
                    spreadRadius: 2)
              ]),
              child: Material(
                color: p.surface,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    final reached = n.tap(item.id);
                    if (reached) {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('MashaAllah! ${item.name} ka target poora')));
                    } else {
                      HapticFeedback.lightImpact();
                    }
                  },
                  child: ProgressRing(
                    size: 280,
                    stroke: 12,
                    value: (c / item.target).clamp(0.0, 1.0).toDouble(),
                    color: done ? p.gold : p.accent,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$c',
                              style: const TextStyle(
                                  fontSize: 76, fontWeight: FontWeight.w300)),
                          Text('/ ${item.target}',
                              style: TextStyle(
                                  color: done ? p.gold : p.accent,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1)),
                          if (done)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Pill('Target poora', p.gold,
                                  icon: Icons.check_circle),
                            ),
                        ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
                '${item.daily ? 'Roz reset hota hai' : 'Total count'} · ab tak kul: ${item.total}',
                style: TextStyle(color: p.muted, fontSize: 12)),
            const SizedBox(height: 12),
            Row(mainAxisSize: MainAxisSize.min, children: [
              OutlinedButton.icon(
                  onPressed: c == 0 ? null : () => n.undo(item.id),
                  icon: const Icon(Icons.undo),
                  label: const Text('-1')),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                  onPressed: c == 0 ? null : () => n.reset(item.id),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset')),
            ]),
          ]),
        ),
      ),
    );
  }
}

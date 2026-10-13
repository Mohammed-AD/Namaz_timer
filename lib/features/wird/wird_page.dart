import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/wird_provider.dart';
import '../../widgets/common.dart';
import 'wird_counter_page.dart';
import 'wird_editor.dart';

/// Surahs + dhikr the user wants to read, each with their own limit.
class WirdPage extends ConsumerStatefulWidget {
  const WirdPage({super.key});
  @override
  ConsumerState<WirdPage> createState() => _WirdPageState();
}

class _WirdPageState extends ConsumerState<WirdPage> {
  int filter = -1; // -1 all, 0 surah, 1 dhikr

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = ref.watch(wirdProvider);
    final key = dayKey(DateTime.now());
    final shown = items.where((e) => filter < 0 || e.kind == filter).toList();
    final doneCount = items.where((e) => e.countFor(key) >= e.target).length;

    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), children: [
        PageHeader(
            title: 'Wird',
            subtitle: items.isEmpty
                ? 'Surah ya dhikr jodein'
                : 'Aaj $doneCount / ${items.length} poore'),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          for (final f in const [(-1, 'Sab'), (0, 'Surah'), (1, 'Dhikr')])
            ChoiceChip(
                label: Text(f.$2),
                selected: filter == f.$1,
                onSelected: (_) => setState(() => filter = f.$1)),
        ]),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          AppCard(
            child: Column(children: [
              Icon(Icons.menu_book_outlined, size: 40, color: p.faint),
              const SizedBox(height: 8),
              Text('Abhi kuch nahi hai. "Naya jodein" dabayein.',
                  style: TextStyle(color: p.muted)),
            ]),
          ),
        for (final e in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _WirdCard(e, key: ValueKey(e.id)),
          ),
      ]),
      Positioned(
        right: 16,
        bottom: 16,
        child: FloatingActionButton.extended(
          onPressed: () => showWirdEditor(context),
          icon: const Icon(Icons.add),
          label: const Text('Naya jodein'),
        ),
      ),
    ]);
  }
}

class _WirdCard extends ConsumerWidget {
  final WirdItem item;
  const _WirdCard(this.item, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final c = item.countFor(dayKey(DateTime.now()));
    final done = c >= item.target;
    final color = done ? p.gold : p.accent;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      borderColor: done ? p.gold.withValues(alpha: .5) : null,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => WirdCounterPage(item.id))),
      onLongPress: () => showWirdEditor(context, item: item),
      child: Row(children: [
        ProgressRing(
          size: 54,
          stroke: 5,
          color: color,
          value: (c / item.target).clamp(0.0, 1.0).toDouble(),
          child: Icon(item.kind == 0 ? Icons.menu_book_rounded : Icons.blur_circular,
              size: 22, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(
                '$c / ${item.target} · ${item.daily ? 'roz' : 'total'}${done ? ' · poora' : ''}',
                style: TextStyle(fontSize: 12, color: done ? p.gold : p.muted)),
          ]),
        ),
        IconButton.filled(
          tooltip: '+1',
          onPressed: () {
            final reached = ref.read(wirdProvider.notifier).tap(item.id);
            if (reached) {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('MashaAllah! ${item.name} ka target poora')));
            } else {
              HapticFeedback.lightImpact();
            }
          },
          icon: const Icon(Icons.add),
        ),
      ]),
    );
  }
}

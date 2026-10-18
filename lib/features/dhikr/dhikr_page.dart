import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/dhikr_provider.dart';
import '../../widgets/common.dart';
import '../settings/settings_sheet.dart';

/// Tasbih counter: big tap target, haptics, saved between launches.
class DhikrPage extends ConsumerWidget {
  const DhikrPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final st = ref.watch(dhikrProvider);
    final item = dhikrItems[st.preset];
    final n = ref.read(dhikrProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
          child: Column(children: [
            PageHeader(
                title: 'Dhikr',
                subtitle: 'Aaj kul: ${st.today}',
                trailing: const SettingsButton()),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dhikrItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                    label: Text(dhikrItems[i].name),
                    selected: st.preset == i,
                    selectedColor: p.gold.withValues(alpha: .3),
                    onSelected: (_) => n.setPreset(i)),
              ),
            ),
            const SizedBox(height: 28),
            Semantics(
              button: true,
              label: '${item.name}, count ${st.count} of ${item.target}. Tap to count',
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                  BoxShadow(color: p.gold.withValues(alpha: .16), blurRadius: 44)
                ]),
                child: Material(
                  color: p.surface,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final roundDone = n.tap();
                      if (roundDone) {
                        HapticFeedback.heavyImpact();
                      } else {
                        HapticFeedback.lightImpact();
                      }
                    },
                    child: ProgressRing(
                      size: 280,
                      stroke: 10,
                      value: st.count / item.target,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.arabic,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 28, color: Colors.white70)),
                            Text('${st.count}',
                                style: const TextStyle(
                                    fontSize: 72, fontWeight: FontWeight.w200)),
                            Text('/ ${item.target}',
                                style: TextStyle(
                                    color: p.gold, letterSpacing: 1)),
                          ]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Gol button ko tap karein',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                onPressed: st.count == 0 ? null : n.reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset')),
          ]),
        ),
      ),
    );
  }
}

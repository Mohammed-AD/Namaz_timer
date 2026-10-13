import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/prayer_times_provider.dart';
import '../../providers/settings_provider.dart';
import '../settings/settings_sheet.dart';
import 'watch_face.dart';

class WatchPage extends ConsumerWidget {
  /// Only the visible tab ticks every second (saves battery).
  final bool active;
  const WatchPage({super.key, required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final now = active
        ? (ref.watch(secondProvider).value ?? DateTime.now())
        : DateTime.now();
    final s = ref.watch(settingsProvider);
    final today = dayOnly(now);
    final nx = nextPrayer(
      now,
      ref.watch(prayerTimesProvider(today)),
      ref.watch(prayerTimesProvider(shift(today, 1))),
    );
    final h = hijriOf(now, s.hijriAdj);

    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          WatchFace(now: now, style: s.style),
          const SizedBox(height: 30),
          Text(hijriText(h),
              style: TextStyle(
                  fontSize: 22, color: p.gold, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}',
              style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
                color: p.gold.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: p.gold.withValues(alpha: .5))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_active_outlined, size: 18, color: p.gold),
              const SizedBox(width: 8),
              Text(
                  'Next: ${prayers[nx.$1]} ${fmt(nx.$2)}  ·  ${dur(nx.$2.difference(now))}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 20),
          Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
            for (var i = 0; i < watchStyles.length; i++)
              ChoiceChip(
                  label: Text(watchStyles[i]),
                  selected: s.style == i,
                  selectedColor: p.gold.withValues(alpha: .3),
                  onSelected: (_) =>
                      ref.read(settingsProvider.notifier).setStyle(i)),
          ]),
          TextButton.icon(
            onPressed: () => showSettings(context),
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: Text(
                '${cities[s.city].name}  ·  ${s.hanafi ? 'Hanafi' : "Shafi'i"}'),
          ),
        ]),
      ),
    );
  }
}

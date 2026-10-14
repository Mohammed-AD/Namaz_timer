import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/prayer_times_provider.dart';
import '../../providers/settings_provider.dart';
import 'watch_face.dart';

/// Opens the big watch face (tap the mini clock in the top bar).
/// The face is drawn for a dark background, so this screen is always dark.
void showWatchPage(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => Theme(
      data: buildTheme(AppPalette.dark, Brightness.dark),
      child: const Scaffold(body: SafeArea(child: WatchPage())),
    ),
  ));
}

class WatchPage extends ConsumerWidget {
  const WatchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final now = ref.watch(secondProvider).value ?? DateTime.now();
    final s = ref.watch(settingsProvider);
    final today = dayOnly(now);
    final nx = nextPrayer(
      now,
      ref.watch(prayerTimesProvider(today)),
      ref.watch(prayerTimesProvider(shift(today, 1))),
    );
    final h = ref.watch(hijriNowProvider);

    return Stack(children: [
      Center(
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
                Icon(Icons.notifications_active_outlined,
                    size: 18, color: p.gold),
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
            const SizedBox(height: 12),
            Text(
                '${s.place.name}  ·  ${s.hanafi ? 'Hanafi' : "Shafi'i"}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      ),
      Positioned(
        top: 4,
        left: 4,
        child: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back)),
      ),
    ]);
  }
}

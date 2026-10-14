import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/clock_provider.dart';
import '../../providers/log_provider.dart';
import '../../providers/prayer_times_provider.dart';
import '../../providers/rest_provider.dart';
import '../../widgets/common.dart';

/// The five rows for one day. On a special day each row becomes a gentle
/// "dhikr at prayer time" slot, so the routine and the feeling of being
/// connected are never lost.
class PrayerTiles extends ConsumerWidget {
  final DateTime day;
  const PrayerTiles(this.day, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = dayOnly(day);
    final today = ref.watch(todayProvider);
    final locked = d.isAfter(today);
    final special = ref.watch(restDayProvider(d));
    final mask = ref.watch(logProvider.select((m) => m.mask(d)));
    final smask = ref.watch(specialLogProvider.select((m) => m.mask(d)));
    final times = ref.watch(prayerTimesProvider(d)).five;
    final nowT = d == today
        ? (ref.watch(pulseProvider).value ?? DateTime.now())
        : null;
    final next = nowT == null ? -1 : times.indexWhere((t) => t.isAfter(nowT));

    return Column(children: [
      for (var i = 0; i < 5; i++)
        _Tile(
          i: i,
          time: times[i],
          done: (((special ? smask : mask) >> i) & 1) == 1,
          special: special,
          locked: locked,
          eta: (i == next && nowT != null) ? times[i].difference(nowT) : null,
          onTap: locked
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  final n = special
                      ? ref.read(specialLogProvider.notifier)
                      : ref.read(logProvider.notifier);
                  n.toggle(d, i);
                },
        ),
    ]);
  }
}

class _Tile extends StatelessWidget {
  final int i;
  final DateTime time;
  final bool done, special, locked;
  final Duration? eta;
  final VoidCallback? onTap;
  const _Tile({
    required this.i,
    required this.time,
    required this.done,
    required this.special,
    required this.locked,
    required this.eta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tint = special ? p.special : p.accent;
    final isNext = eta != null;
    return Semantics(
      button: onTap != null,
      checked: done,
      label:
          '${prayers[i]} ${fmt(time)}${special ? ', special day dhikr' : ''}${done ? ', done' : ''}',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: locked ? .45 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: done ? tint.withValues(alpha: .14) : p.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: done
                    ? tint.withValues(alpha: .7)
                    : isNext
                        ? tint.withValues(alpha: .55)
                        : p.line,
                width: isNext && !done ? 1.5 : 1),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: tint.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(15)),
                    child: Icon(prayerIcons[i], color: tint),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(prayers[i],
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800)),
                            if (isNext) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                  child: Pill('Next · ${dur(eta!)}', tint)),
                            ],
                          ]),
                          const SizedBox(height: 2),
                          Text(
                              special
                                  ? 'Dhikr time · ${specialIdeas[i]}'
                                  : arabic[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.muted, fontSize: 12)),
                        ]),
                  ),
                  const SizedBox(width: 8),
                  Text(fmt(time),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: done ? tint : p.muted)),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: Icon(
                        done
                            ? (special
                                ? Icons.favorite_rounded
                                : Icons.check_circle_rounded)
                            : Icons.radio_button_unchecked,
                        key: ValueKey(done),
                        color: done ? tint : p.faint,
                        size: 28),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

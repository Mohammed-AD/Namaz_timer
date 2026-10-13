import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/beep.dart';
import '../../core/theme.dart';
import '../../core/format.dart';
import '../../providers/prayer_times_provider.dart';
import '../../widgets/common.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});
  @override
  ConsumerState<TimerPage> createState() => _TimerState();
}

class _TimerState extends ConsumerState<TimerPage> {
  int minutes = 10;
  Duration left = const Duration(minutes: 10);
  DateTime? endAt;
  Timer? tick;
  bool ringing = false;
  final player = AudioPlayer();

  @override
  void dispose() {
    tick?.cancel();
    player.dispose();
    super.dispose();
  }

  void start() {
    endAt = DateTime.now().add(left);
    tick?.cancel();
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = endAt!.difference(DateTime.now());
      if (r <= Duration.zero) {
        tick?.cancel();
        endAt = null;
        setState(() {
          left = Duration.zero;
          ringing = true;
        });
        ring();
      } else {
        setState(
            () => left = Duration(seconds: (r.inMilliseconds / 1000).ceil()));
      }
    });
    setState(() {});
  }

  void pause() {
    tick?.cancel();
    final deadline = endAt;
    if (deadline != null) {
      left = deadline.difference(DateTime.now());
      if (left < Duration.zero) left = Duration.zero;
    }
    endAt = null;
    setState(() {});
  }

  void reset() {
    tick?.cancel();
    endAt = null;
    stopAlarm();
    setState(() {
      left = Duration(minutes: minutes);
      ringing = false;
    });
  }

  Future<void> ring() async {
    HapticFeedback.heavyImpact();
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(BytesSource(beepWav()));
    } catch (_) {}
  }

  Future<void> stopAlarm() async {
    try {
      await player.stop();
    } catch (_) {}
  }

  void _toNextNamaz() {
    final now = DateTime.now();
    final today = dayOnly(now);
    final nx = nextPrayer(
      now,
      ref.read(prayerTimesProvider(today)),
      ref.read(prayerTimesProvider(shift(today, 1))),
    );
    final d = nx.$2.difference(now);
    setState(() {
      minutes = math.max(1, d.inMinutes + 1);
      left = d;
    });
  }

  @override
  Widget build(BuildContext context) {
    final running = endAt != null;
    final total = Duration(minutes: minutes).inMilliseconds;
    final p = context.pal;
    final accent = ringing ? const Color(0xFFFF6B6B) : p.accent;
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: PageHeader(title: 'Timer'),
            ),
            const SizedBox(height: 12),
            Container(
              width: 270,
              height: 270,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                BoxShadow(
                    color: accent.withValues(alpha: running || ringing ? .3 : .08),
                    blurRadius: 44,
                    spreadRadius: 2)
              ]),
              child: ProgressRing(
                size: 242,
                stroke: 12,
                color: accent,
                value: total == 0
                    ? 0
                    : math.min(1.0, left.inMilliseconds / total),
                child: Text(
                    '${p2(left.inHours > 0 ? left.inHours : left.inMinutes)}:${p2(left.inHours > 0 ? left.inMinutes % 60 : left.inSeconds % 60)}',
                    style: const TextStyle(
                        fontSize: 60, fontWeight: FontWeight.w200)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
                ringing
                    ? 'Time up!'
                    : running
                        ? 'Alarm at ${fmt(endAt!)}'
                        : 'Duration set karo',
                style: TextStyle(
                    fontSize: 15,
                    color: ringing ? const Color(0xFFFF6B6B) : p.muted,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            if (!running && !ringing) ...[
              Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                for (final m in [1, 5, 10, 15, 30, 60])
                  ChoiceChip(
                      label: Text('${m}m'),
                      selected: minutes == m,
                      onSelected: (_) => setState(() {
                            minutes = m;
                            left = Duration(minutes: m);
                          })),
                ActionChip(
                  avatar: Icon(Icons.notifications_active_outlined,
                      size: 16, color: p.accent),
                  label: const Text('Next namaz'),
                  onPressed: _toNextNamaz,
                ),
              ]),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Slider(
                  value: minutes.toDouble(),
                  min: 1,
                  max: 1440,
                  divisions: 1439,
                  label: '$minutes min',
                  onChanged: (v) => setState(() {
                    minutes = v.round();
                    left = Duration(minutes: minutes);
                  }),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (ringing)
              FilledButton.icon(
                  onPressed: reset,
                  icon: const Icon(Icons.alarm_off),
                  label: const Text('Stop alarm'))
            else
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FilledButton.icon(
                    onPressed:
                        running ? pause : (left > Duration.zero ? start : null),
                    icon: Icon(running ? Icons.pause : Icons.play_arrow),
                    label: Text(running ? 'Pause' : 'Start')),
                const SizedBox(width: 12),
                if (running) ...[
                  OutlinedButton(
                      onPressed: () => setState(
                          () => endAt = endAt!.add(const Duration(minutes: 1))),
                      child: const Text('+1m')),
                  const SizedBox(width: 12),
                ],
                OutlinedButton(onPressed: reset, child: const Text('Reset')),
              ]),
            const SizedBox(height: 16),
          ]),
        ),
      );
    });
  }
}

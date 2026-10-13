import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';

/// One widget for all four watch styles (0 Classic, 1 Modern, 2 Digital, 3 Ring).
class WatchFace extends StatelessWidget {
  final DateTime now;
  final int style;
  const WatchFace({super.key, required this.now, required this.style});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final side = math.min(300.0, MediaQuery.sizeOf(context).width - 48);
    final h12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour < 12 ? 'AM' : 'PM';

    if (style <= 1) {
      return RepaintBoundary(
        child: CustomPaint(
            painter: AnalogPainter(
              now,
              style == 0,
              gold: p.gold,
              bg: p.bg,
              card: p.surface,
            ),
            size: Size(side, side)),
      );
    }
    if (style == 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: p.gold, width: 2),
          boxShadow: [BoxShadow(color: p.gold.withValues(alpha: .25), blurRadius: 32)],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${p2(h12)}:${p2(now.minute)}',
                    style: TextStyle(
                        fontSize: 68,
                        fontWeight: FontWeight.w300,
                        color: p.gold,
                        fontFeatures: [const FontFeature.tabularFigures()])),
                Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 8),
                    child: Text('${p2(now.second)}\n$ampm',
                        style: const TextStyle(
                            fontSize: 16, height: 1.3, color: Colors.white70))),
              ]),
        ),
      );
    }
    final ring = math.min(280.0, side);
    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(
            child: CircularProgressIndicator(
                value: (now.second + 1) / 60,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                color: p.gold,
                backgroundColor: p.surface)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${p2(h12)}:${p2(now.minute)}',
              style: const TextStyle(fontSize: 58, fontWeight: FontWeight.w200)),
          Text(ampm, style: TextStyle(color: p.gold, letterSpacing: 2)),
        ]),
      ]),
    );
  }
}

class AnalogPainter extends CustomPainter {
  final DateTime t;
  final bool classic;
  final Color gold;
  final Color bg;
  final Color card;

  AnalogPainter(this.t, this.classic,
      {required this.gold, required this.bg, required this.card});

  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.shortestSide / 2;
    Offset pt(double a, double len) =>
        ctr + Offset(math.cos(a), math.sin(a)) * len;
    c.drawCircle(
        ctr,
        r,
        Paint()
          ..shader = RadialGradient(colors: [bg, card]).createShader(
              Rect.fromCircle(center: ctr, radius: r)));
    c.drawCircle(
        ctr,
        r - 3,
        Paint()
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
    for (var i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      if (!classic && !major) continue;
      final a = i * math.pi / 30;
      final p = Paint()
        ..color = major ? gold : Colors.white38
        ..strokeWidth = major ? (classic ? 3 : 6) : 1.2
        ..strokeCap = StrokeCap.round;
      c.drawLine(pt(a, r * (major ? .82 : .89)), pt(a, r * .93), p);
    }
    if (classic) {
      for (var n = 1; n <= 12; n++) {
        final tp = TextPainter(
          text: TextSpan(
              text: '$n',
              style: TextStyle(
                  color: n % 3 == 0 ? gold : Colors.white70,
                  fontSize: r * .15,
                  fontWeight: FontWeight.w500)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
            c,
            pt(n * math.pi / 6 - math.pi / 2, r * .68) -
                Offset(tp.width / 2, tp.height / 2));
      }
    }
    void hand(double f, double len, double w, Color col, {double tail = 0}) {
      final a = f * 2 * math.pi - math.pi / 2;
      c.drawLine(
          pt(a, -tail),
          pt(a, r * len),
          Paint()
            ..color = col
            ..strokeWidth = w
            ..strokeCap = StrokeCap.round);
    }

    hand(((t.hour % 12) + t.minute / 60) / 12, .45, 8, gold);
    hand((t.minute + t.second / 60) / 60, .68, 5, Colors.white);
    hand(t.second / 60, .8, 2, Colors.redAccent, tail: r * .12);
    c.drawCircle(ctr, 8, Paint()..color = gold);
    c.drawCircle(ctr, 3, Paint()..color = card);
  }

  @override
  bool shouldRepaint(AnalogPainter o) =>
      o.t.second != t.second || o.classic != classic;
}

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/log_provider.dart';
import '../../providers/rest_provider.dart';

/// Whole year in ONE canvas pass: O(365) time, O(1) widgets.
/// [rest] is null when the special-days feature is off.
class HeatPainter extends CustomPainter {
  static const cell = 16.0, top = 18.0;
  final Map<String, int> log, slog;
  final RestState? rest;
  final int year;
  final AppPalette pal;
  HeatPainter(this.log, this.slog, this.rest, this.year, this.pal);

  @override
  void paint(Canvas c, Size size) {
    final start = DateTime(year, 1, 1);
    final off = start.weekday % 7;
    final days = DateTime(year + 1, 1, 1).difference(start).inDays;
    final now = DateTime.now();
    final p = Paint();
    for (var i = 0; i < days; i++) {
      final d = DateTime(year, 1, 1 + i);
      final n = log.count(d);
      if (n == 0 && (rest?.isRest(d) ?? false)) {
        p.color = pal.special.withValues(alpha: .22 + .13 * slog.count(d));
      } else {
        final alpha = (.22 + .16 * n).clamp(0.0, 1.0).toDouble();
        p.color = n == 0 ? pal.surface2 : pal.accent.withValues(alpha: alpha);
      }
      final x = ((i + off) ~/ 7) * cell, y = top + ((i + off) % 7) * cell;
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1.5, y + 1.5, cell - 3, cell - 3),
          const Radius.circular(4));
      c.drawRRect(rect, p);
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        c.drawRRect(
            rect,
            Paint()
              ..color = pal.text
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
      if (d.day == 1) {
        final tp = TextPainter(
            text: TextSpan(
                text: months[d.month - 1],
                style: TextStyle(color: pal.muted, fontSize: 10)),
            textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(c, Offset(x, 2));
      }
    }
  }

  @override
  bool shouldRepaint(HeatPainter o) =>
      o.log != log ||
      o.slog != slog ||
      o.rest != rest ||
      o.year != year ||
      o.pal != pal;
}

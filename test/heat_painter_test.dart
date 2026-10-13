import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_app/core/format.dart';
import 'package:namaz_app/core/theme.dart';
import 'package:namaz_app/features/namaz/heat_painter.dart';

void main() {
  test('paints a visible accent for a day with all prayers completed',
      () async {
    final today = DateTime.now();
    final painter = HeatPainter(
      {dayKey(today): 0x1f},
      const {},
      null,
      today.year,
      AppPalette.dark,
    );
    final recorder = PictureRecorder();
    const width = 54 * HeatPainter.cell;
    const height = HeatPainter.top + 7 * HeatPainter.cell;

    painter.paint(Canvas(recorder), const Size(width, height));
    final image =
        await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final pixels = await image.toByteData(format: ImageByteFormat.rawRgba);
    final start = DateTime(today.year, 1, 1);
    final position = today.difference(start).inDays + start.weekday % 7;
    final x = (position ~/ 7) * HeatPainter.cell + HeatPainter.cell / 2;
    final y = HeatPainter.top +
        (position % 7) * HeatPainter.cell +
        HeatPainter.cell / 2;
    final offset = (y.toInt() * width.toInt() + x.toInt()) * 4;

    expect(pixels!.getUint8(offset + 1), greaterThan(150));
    image.dispose();
  });
}

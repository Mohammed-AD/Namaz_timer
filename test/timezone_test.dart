
import 'package:flutter_test/flutter_test.dart';

import 'package:namaz_app/core/constants.dart';
import 'package:namaz_app/core/format.dart';

void main() {
  test('Saudi date remains October 6 before Saudi midnight', () {
    final instant = DateTime.utc(2026, 10, 6, 20, 45);
    final saudi = wallClockAtOffset(instant, holyUtcMinutes);

    expect(saudi.year, 2026);
    expect(saudi.month, 10);
    expect(saudi.day, 6);
    expect(saudi.hour, 23);
    expect(saudi.minute, 45);
  });

  test('Saudi date rolls over correctly after midnight', () {
    final instant = DateTime.utc(2026, 10, 6, 22, 45);
    final saudiDay = dayAtOffset(instant, holyUtcMinutes);

    expect(saudiDay.year, 2026);
    expect(saudiDay.month, 10);
    expect(saudiDay.day, 7);
  });

  test('Saudi wall-clock time converts to the correct UTC instant', () {
    final saudiWall = DateTime(2026, 10, 6, 19, 34);
    final utc = wallClockToUtc(saudiWall, holyUtcMinutes);

    expect(utc, DateTime.utc(2026, 10, 6, 16, 34));
  });
}

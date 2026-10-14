import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_app/core/constants.dart';
import 'package:namaz_app/core/day_times.dart';
import 'package:namaz_app/core/events.dart';
import 'package:namaz_app/core/prayer_utils.dart';

DayTimes day(int d) => DayTimes(
      DateTime(2026, 10, d, 5),
      DateTime(2026, 10, d, 6, 20),
      DateTime(2026, 10, d, 12, 30),
      DateTime(2026, 10, d, 16),
      DateTime(2026, 10, d, 18, 15),
      DateTime(2026, 10, d, 19, 30),
    );

void main() {
  group('qiblaBearing', () {
    test('Nashik points a little north of west (~279 degrees)', () {
      final q = qiblaBearing(cities[0]);
      expect(q, inInclusiveRange(275, 283));
      expect(compassName(q), 'W');
    });

    test('Delhi is a little north of west', () {
      final q = qiblaBearing(cities[3]);
      expect(q, inInclusiveRange(255, 275));
    });
  });

  group('currentWindow', () {
    final y = day(5), t = day(6), n = day(7);

    test('Fajr runs until sunrise', () {
      final w = currentWindow(DateTime(2026, 10, 6, 5, 30), y, t, n)!;
      expect(w.index, 0);
      expect(w.end, t.sunrise);
    });

    test('nothing is running between sunrise and Zohar', () {
      expect(currentWindow(DateTime(2026, 10, 6, 9), y, t, n), isNull);
    });

    test('Zohar, Asr and Maghrib end when the next one starts', () {
      expect(currentWindow(DateTime(2026, 10, 6, 13), y, t, n)!.end, t.asr);
      expect(currentWindow(DateTime(2026, 10, 6, 17), y, t, n)!.end, t.maghrib);
      expect(currentWindow(DateTime(2026, 10, 6, 18, 30), y, t, n)!.end, t.isha);
    });

    test('Isha runs until tomorrow\'s Fajr', () {
      final w = currentWindow(DateTime(2026, 10, 6, 22), y, t, n)!;
      expect(w.index, 4);
      expect(w.end, n.fajr);
    });

    test('after midnight we are still in last night\'s Isha', () {
      final w = currentWindow(DateTime(2026, 10, 6, 2), y, t, n)!;
      expect(w.index, 4);
      expect(w.end, t.fajr);
    });
  });

  group('islamicEvent', () {
    test('Ramadan 13-15 is not labelled as a sunnah roza', () {
      expect(islamicEvent(9, 14), isNull);
    });
    test('Ayyam al-Bidh in other months still is', () {
      expect(islamicEvent(7, 14)?.name, contains('Ayyam al-Bidh'));
    });
    test('Dhu al-Hijjah 13 is Tashreeq, not a sunnah roza', () {
      expect(islamicEvent(12, 13)?.name, 'Ayyam al-Tashreeq');
    });
    test('Tasu\'a comes before Ashura', () {
      expect(islamicEvent(1, 9), isNotNull);
      expect(islamicEvent(1, 10)?.name, 'Ashura');
    });
  });
}

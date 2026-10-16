import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:namaz_app/core/day_times.dart';
import 'package:namaz_app/providers/holy_times_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fetches both cities, converts Saudi wall time to UTC, and caches',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      return http.Response(
        jsonEncode({
          'code': 200,
          'data': {
            'timings': {
              'Fajr': '04:15 (AST)',
              'Sunrise': '05:35 (AST)',
              'Dhuhr': '12:05 (AST)',
              'Asr': '15:25 (AST)',
              'Maghrib': '18:20 (AST)',
              'Isha': '19:50 (AST)',
            },
          },
        }),
        200,
      );
    });
    final service = HolyTimesService(
      prefs,
      client: client,
      localFallback: (_) => throw StateError('Unexpected fallback'),
    );

    final result = await service.load(DateTime(2026, 10, 6));

    expect(result.source, HolyTimesSource.liveApi);
    expect(requests, hasLength(2));
    expect(requests.first.queryParameters['method'], '4');
    expect(requests.first.queryParameters['timezonestring'], 'Asia/Riyadh');
    expect(result.makkah.fajr, DateTime.utc(2026, 10, 6, 1, 15));

    final cachedService = HolyTimesService(
      prefs,
      client: MockClient((_) async => throw StateError('Cache was not used')),
      localFallback: (_) => throw StateError('Unexpected fallback'),
    );
    final cached = await cachedService.load(DateTime(2026, 10, 6));

    // A fresh cache is fast to reuse, but must not be reported as a live
    // network response when this load did not contact the API.
    expect(cached.source, HolyTimesSource.cache);
    expect(cached.makkah.fajr, result.makkah.fajr);
  });

  test('force bypasses the fresh cache (manual refresh button)', () async {
    final prefs = await SharedPreferences.getInstance();
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response(
        jsonEncode({
          'code': 200,
          'data': {
            'timings': {
              'Fajr': '04:15',
              'Sunrise': '05:35',
              'Dhuhr': '12:05',
              'Asr': '15:25',
              'Maghrib': '18:20',
              'Isha': '19:50',
            },
          },
        }),
        200,
      );
    });
    final service = HolyTimesService(
      prefs,
      client: client,
      localFallback: (_) => throw StateError('Unexpected fallback'),
    );

    await service.load(DateTime(2026, 10, 6));
    expect(calls, 2); // Makkah + Madinah
    await service.load(DateTime(2026, 10, 6));
    expect(calls, 2); // served from cache
    await service.load(DateTime(2026, 10, 6), force: true);
    expect(calls, 4); // forced network load
  });

  test('rejects out-of-range API prayer times and falls back safely', () async {
    final prefs = await SharedPreferences.getInstance();
    final fallback = HolyTimesFetchResult(
      makkah: DayTimes(
        DateTime.utc(2026, 10, 6, 1),
        DateTime.utc(2026, 10, 6, 2),
        DateTime.utc(2026, 10, 6, 9),
        DateTime.utc(2026, 10, 6, 12),
        DateTime.utc(2026, 10, 6, 15),
        DateTime.utc(2026, 10, 6, 16),
      ),
      madinah: DayTimes(
        DateTime.utc(2026, 10, 6, 1),
        DateTime.utc(2026, 10, 6, 2),
        DateTime.utc(2026, 10, 6, 9),
        DateTime.utc(2026, 10, 6, 12),
        DateTime.utc(2026, 10, 6, 15),
        DateTime.utc(2026, 10, 6, 16),
      ),
      source: HolyTimesSource.localCalculation,
    );
    final client = MockClient((_) async => http.Response(
          jsonEncode({
            'code': 200,
            'data': {
              'timings': {
                'Fajr': '99:15',
                'Sunrise': '05:35',
                'Dhuhr': '12:05',
                'Asr': '15:25',
                'Maghrib': '18:20',
                'Isha': '19:50',
              },
            },
          }),
          200,
        ));
    final service = HolyTimesService(
      prefs,
      client: client,
      localFallback: (_) => fallback,
    );

    final result = await service.load(DateTime(2026, 10, 6));
    expect(result.source, HolyTimesSource.localCalculation);
    expect(result.warning, contains('Internet unavailable'));
  });

  test('uses the local schedule when the API is unavailable', () async {
    final prefs = await SharedPreferences.getInstance();
    final fallback = HolyTimesFetchResult(
      makkah: DayTimes(
        DateTime.utc(2026, 10, 6, 1),
        DateTime.utc(2026, 10, 6, 2),
        DateTime.utc(2026, 10, 6, 9),
        DateTime.utc(2026, 10, 6, 12),
        DateTime.utc(2026, 10, 6, 15),
        DateTime.utc(2026, 10, 6, 16),
      ),
      madinah: DayTimes(
        DateTime.utc(2026, 10, 6, 1),
        DateTime.utc(2026, 10, 6, 2),
        DateTime.utc(2026, 10, 6, 9),
        DateTime.utc(2026, 10, 6, 12),
        DateTime.utc(2026, 10, 6, 15),
        DateTime.utc(2026, 10, 6, 16),
      ),
      source: HolyTimesSource.localCalculation,
    );
    final service = HolyTimesService(
      prefs,
      client: MockClient((_) async => http.Response('', 503)),
      localFallback: (_) => fallback,
    );

    final result = await service.load(DateTime(2026, 10, 6));

    expect(result.source, HolyTimesSource.localCalculation);
    expect(result.warning, contains('Internet unavailable'));
    expect(result.makkah.fajr, fallback.makkah.fajr);
  });
}

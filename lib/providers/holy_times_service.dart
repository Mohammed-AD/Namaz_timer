
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/day_times.dart';
import '../core/format.dart';

class HolyTimesFetchResult {
  final DayTimes makkah;
  final DayTimes madinah;
  final HolyTimesSource source;
  final DateTime? fetchedAt;
  final String? warning;

  const HolyTimesFetchResult({
    required this.makkah,
    required this.madinah,
    required this.source,
    this.fetchedAt,
    this.warning,
  });

  bool get isLive => source == HolyTimesSource.liveApi;
}

enum HolyTimesSource { liveApi, cache, localCalculation }

typedef HolyTimesFallback = HolyTimesFetchResult Function(DateTime day);

class HolyTimesService {
  static const _cacheTtl = Duration(minutes: 15);
  static const _apiHost = 'api.aladhan.com';
  static const _method = '4'; // Umm Al-Qura University, Makkah.
  static const _timeZone = 'Asia/Riyadh';

  final SharedPreferences prefs;
  final http.Client client;
  final HolyTimesFallback localFallback;

  const HolyTimesService(this.prefs,
      {required this.client, required this.localFallback});

  Future<HolyTimesFetchResult> load(DateTime day) async {
    final d = dayOnly(day);
    final cacheKey = _cacheKey(d);

    final cached = _readCache(d);
    final fetchedAt = cached?.fetchedAt;
    if (cached != null &&
      fetchedAt != null &&
      DateTime.now().difference(fetchedAt) < _cacheTtl) {
      return cached;
    }

    try {
      final values = await Future.wait([
        _fetchCity(makkah, d),
        _fetchCity(madinah, d),
      ]);
      final result = HolyTimesFetchResult(
        makkah: values[0],
        madinah: values[1],
        source: HolyTimesSource.liveApi,
        fetchedAt: DateTime.now(),
      );
      await _writeCache(cacheKey, d, result);
      return result;
    } catch (e) {
      if (cached != null) {
        return HolyTimesFetchResult(
          makkah: cached.makkah,
          madinah: cached.madinah,
          source: HolyTimesSource.cache,
          fetchedAt: cached.fetchedAt,
          warning: 'Live sync failed; showing the last cached schedule.',
        );
      }

      final local = localFallback(d);
      return HolyTimesFetchResult(
        makkah: local.makkah,
        madinah: local.madinah,
        source: HolyTimesSource.localCalculation,
        warning: 'Internet unavailable; showing local Umm Al-Qura calculation.',
      );
    }
  }

  Future<DayTimes> _fetchCity(City city, DateTime day) async {
    final date = '${p2(day.day)}-${p2(day.month)}-${day.year}';
    final uri = Uri.https(_apiHost, '/v1/timings/$date', {
      'latitude': '${city.lat}',
      'longitude': '${city.lng}',
      'method': _method,
      'school': '0',
      'timezonestring': _timeZone,
      'iso8601': 'false',
    });

    final response = await client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Prayer API returned ${response.statusCode}');
    }

    final root = jsonDecode(response.body);
    if (root is! Map || root['code'] != 200) {
      throw Exception('Prayer API returned an invalid payload');
    }

    final data = root['data'];
    if (data is! Map || data['timings'] is! Map) {
      throw Exception('Prayer API payload is missing timings');
    }

    final timings = Map<String, dynamic>.from(data['timings'] as Map);
    DateTime parse(String key) => _apiTimeToUtc(day, timings[key]);

    return DayTimes(
      parse('Fajr'),
      parse('Sunrise'),
      parse('Dhuhr'),
      parse('Asr'),
      parse('Maghrib'),
      parse('Isha'),
    );
  }

  DateTime _apiTimeToUtc(DateTime day, dynamic raw) {
    if (raw is! String) {
      throw Exception('Missing prayer time');
    }
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) {
      throw Exception('Invalid prayer time: $raw');
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final saudiWall = DateTime(day.year, day.month, day.day, hour, minute);
    return wallClockToUtc(saudiWall, holyUtcMinutes);
  }

  String _cacheKey(DateTime d) => 'holy_live_${dayKey(d)}';

  HolyTimesFetchResult? _readCache(DateTime day) {
    final raw = prefs.getString(_cacheKey(day));
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final fetchedAt = DateTime.parse(json['fetchedAt'] as String);
      return HolyTimesFetchResult(
        makkah: _decodeDayTimes(json['makkah'] as Map<String, dynamic>),
        madinah: _decodeDayTimes(json['madinah'] as Map<String, dynamic>),
        source: HolyTimesSource.cache,
        fetchedAt: fetchedAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
    String key,
    DateTime day,
    HolyTimesFetchResult result,
  ) async {
    final payload = <String, dynamic>{
      'date': dayKey(day),
      'fetchedAt': result.fetchedAt!.toIso8601String(),
      'makkah': _encodeDayTimes(result.makkah),
      'madinah': _encodeDayTimes(result.madinah),
    };
    await prefs.setString(key, jsonEncode(payload));
  }

  Map<String, String> _encodeDayTimes(DayTimes t) => {
        'fajr': t.fajr.toIso8601String(),
        'sunrise': t.sunrise.toIso8601String(),
        'dhuhr': t.dhuhr.toIso8601String(),
        'asr': t.asr.toIso8601String(),
        'maghrib': t.maghrib.toIso8601String(),
        'isha': t.isha.toIso8601String(),
      };

  DayTimes _decodeDayTimes(Map<String, dynamic> raw) => DayTimes(
        DateTime.parse(raw['fajr'] as String),
        DateTime.parse(raw['sunrise'] as String),
        DateTime.parse(raw['dhuhr'] as String),
        DateTime.parse(raw['asr'] as String),
        DateTime.parse(raw['maghrib'] as String),
        DateTime.parse(raw['isha'] as String),
      );
}

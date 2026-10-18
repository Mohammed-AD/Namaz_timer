import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_app/core/constants.dart';
import 'package:namaz_app/providers/prefs_provider.dart';
import 'package:namaz_app/providers/prayer_times_provider.dart';
import 'package:namaz_app/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> make({
    Map<String, Object> initial = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
  }

  test('settings sanitize invalid saved indexes and list lengths', () async {
    final c = await make(initial: {
      'city': 999,
      'hAdj': 9,
      'theme': 9,
      'watchStyle': 99,
      'pOff': ['12'],
      'pFix': ['bad'],
    });

    final s = c.read(settingsProvider);
    expect(s.city, cities.length - 1);
    expect(s.hijriAdj, 1);
    expect(s.themeMode, 2);
    expect(s.style, watchStyles.length - 1);
    expect(s.offsets, List<int>.filled(5, 0));
    expect(s.fixed, List<int>.filled(5, -1));
    c.dispose();
  });

  test('custom place and prayer-time overrides persist', () async {
    final c = await make();
    final n = c.read(settingsProvider.notifier);
    n.setCustomLocation('Sample Place', 18.5204, 73.8567);
    n.setHanafi(false);
    n.setHijriAdj(-1);
    n.setFixed(0, 5 * 60 + 12);
    n.nudge(0, 3);

    final s = c.read(settingsProvider);
    expect(s.isCustom, isTrue);
    expect(s.place.name, 'Sample Place');
    expect(s.place.lat, 18.5204);
    expect(s.place.lng, 73.8567);
    expect(s.hanafi, isFalse);
    expect(s.hijriAdj, -1);
    expect(s.fixed[0], 5 * 60 + 15);

    final prefs = c.read(prefsProvider);
    expect(prefs.getInt('city'), customCityIndex);
    expect(prefs.getString('cName'), 'Sample Place');
    expect(prefs.getDouble('cLat'), 18.5204);
    expect(prefs.getDouble('cLng'), 73.8567);
    expect(prefs.getStringList('pFix')!.first, '${5 * 60 + 15}');

    final day = DateTime(2026, 10, 14);
    expect(
      c.read(prayerTimesProvider(day)).fajr,
      DateTime(2026, 10, 14, 5, 15),
    );
    c.dispose();
  });
}

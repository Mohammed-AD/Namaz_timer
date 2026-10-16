import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_app/core/theme.dart';
import 'package:namaz_app/features/namaz/prayer_tiles.dart';
import 'package:namaz_app/providers/clock_provider.dart';
import 'package:namaz_app/providers/prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('prayer tiles fit a 320 logical pixel phone width', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          pulseProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 10, 14, 0, 1)),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(AppPalette.light, Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PrayerTiles(DateTime(2026, 10, 14)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Next ·'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
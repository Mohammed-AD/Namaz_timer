import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_app/core/theme.dart';
import 'package:namaz_app/features/calendar/calendar_page.dart';
import 'package:namaz_app/providers/clock_provider.dart';
import 'package:namaz_app/providers/prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('calendar day grid does not overflow on a compact display',
      (tester) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        pulseProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 10, 14)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(AppPalette.dark, Brightness.dark),
          home: const Scaffold(body: CalendarPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // RenderFlex overflow warnings are reported as framework exceptions.
    expect(tester.takeException(), isNull);
  });
}

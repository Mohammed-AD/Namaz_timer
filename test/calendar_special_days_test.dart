import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_app/core/theme.dart';
import 'package:namaz_app/features/calendar/calendar_page.dart';
import 'package:namaz_app/providers/prefs_provider.dart';
import 'package:namaz_app/providers/rest_provider.dart';
import 'package:namaz_app/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('explains why prayers are not tracked on a special date',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    container.read(settingsProvider.notifier).setRestEnabled(true);
    container.read(restProvider.notifier).start(DateTime.now());

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
    await tester.scrollUntilVisible(
      find.text('Special day · namaz tracking paused'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Special day · namaz tracking paused'), findsOneWidget);

    container.dispose();
  });
}

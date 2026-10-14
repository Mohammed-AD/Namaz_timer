import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_app/core/format.dart';
import 'package:namaz_app/providers/prefs_provider.dart';
import 'package:namaz_app/providers/rest_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> make() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)]);
  }

  final today = DateTime(2026, 10, 13);

  test('length counts both the first and the last day', () {
    expect(const RestRange('20261010', '20261015').length(today), 6);
    expect(const RestRange('20261013').length(today), 1); // ongoing, today
    expect(const RestRange('20261010').length(today), 4); // ongoing, 10..13
  });

  test('daysBetween is exact', () {
    expect(daysBetween(DateTime(2026, 10, 10), DateTime(2026, 10, 13)), 3);
    expect(daysBetween(DateTime(2026, 12, 30), DateTime(2027, 1, 2)), 3);
  });

  test('endLast closes the run on the chosen last day', () async {
    final c = await make();
    final n = c.read(restProvider.notifier);
    n.start(DateTime(2026, 10, 10));
    n.endLast(DateTime(2026, 10, 14));
    final r = c.read(restProvider).ranges.single;
    expect(r.end, '20261014');
    expect(r.length(today), 5);
    expect(c.read(restProvider).open, isNull);
    c.dispose();
  });

  test('a run that would end before it started is dropped', () async {
    final c = await make();
    final n = c.read(restProvider.notifier);
    n.start(DateTime(2026, 10, 13));
    n.end(DateTime(2026, 10, 13)); // last day = yesterday < start
    expect(c.read(restProvider).ranges, isEmpty);
    c.dispose();
  });

  test('a new run cannot overlap the previous one', () async {
    final c = await make();
    final n = c.read(restProvider.notifier);
    n.start(DateTime(2026, 10, 1));
    n.endLast(DateTime(2026, 10, 6));
    n.start(DateTime(2026, 10, 4));
    expect(c.read(restProvider).ranges.last.start, '20261007');
    c.dispose();
  });

  test('averages and cycle from several runs', () async {
    final c = await make();
    final n = c.read(restProvider.notifier);
    n.start(DateTime(2026, 7, 1));
    n.endLast(DateTime(2026, 7, 5)); // 5 days
    n.start(DateTime(2026, 7, 30));
    n.endLast(DateTime(2026, 8, 6)); // 8 days
    final st = c.read(restProvider);
    expect(st.avgLength(today), 6.5);
    expect(st.avgCycle(), 29);
    expect(st.rangeOf(DateTime(2026, 8, 2))?.start, '20260730');
    expect(st.rangeOf(DateTime(2026, 8, 20)), isNull);
    c.dispose();
  });

  test('removeAt deletes only that run', () async {
    final c = await make();
    final n = c.read(restProvider.notifier);
    n.start(DateTime(2026, 7, 1));
    n.endLast(DateTime(2026, 7, 5));
    n.start(DateTime(2026, 8, 1));
    n.endLast(DateTime(2026, 8, 5));
    n.removeAt(0);
    expect(c.read(restProvider).ranges.single.start, '20260801');
    c.dispose();
  });
}

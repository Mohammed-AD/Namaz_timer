import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_app/providers/backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('backup round-trips every kind of value', () async {
    SharedPreferences.setMockInitialValues({
      'log': '{"20261006":31}',
      'city': 3,
      'hanafi': false,
      'cLat': 19.9975,
      'pOff': ['0', '2', '0', '0', '-1'],
      'unrelated': 'ignored',
    });
    final prefs = await SharedPreferences.getInstance();
    final text = exportBackup(prefs);
    expect(text.contains('unrelated'), isFalse);

    SharedPreferences.setMockInitialValues({});
    final fresh = await SharedPreferences.getInstance();
    final n = await importBackup(fresh, text);

    expect(n, 5);
    expect(fresh.getString('log'), '{"20261006":31}');
    expect(fresh.getInt('city'), 3);
    expect(fresh.getBool('hanafi'), false);
    expect(fresh.getDouble('cLat'), 19.9975);
    expect(fresh.getStringList('pOff'), ['0', '2', '0', '0', '-1']);
  });

  test(
      'rejects text that is not a Namaz backup or uses an unsupported version',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await expectLater(importBackup(prefs, 'hello'), throwsFormatException);
    await expectLater(
      importBackup(prefs, '{"app":"other"}'),
      throwsFormatException,
    );
    await expectLater(
      importBackup(prefs, '{"app":"namaz_app","v":99,"data":{}}'),
      throwsFormatException,
    );
  });
}

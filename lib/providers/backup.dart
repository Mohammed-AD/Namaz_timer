import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Every preference key the app owns. Anything else in storage is ignored.
const backupKeys = [
  'log', 'slog', 'rest', 'fastDone', 'fastExtra', 'wird', //
  'city', 'hanafi', 'restOn', 'hAdj', 'theme', 'watchStyle', 'hMag', //
  'cName', 'cLat', 'cLng', 'pOff', 'pFix',
];

/// All app data as one JSON string (namaz log, wird, settings...).
String exportBackup(SharedPreferences p) {
  final data = <String, dynamic>{};
  for (final k in backupKeys) {
    final v = p.get(k);
    if (v != null) data[k] = v;
  }
  return jsonEncode({'app': 'namaz_app', 'v': 1, 'data': data});
}

/// Restores a string made by [exportBackup]. Returns how many values were
/// restored. Throws [FormatException] if the text is not a Namaz backup.
Future<int> importBackup(SharedPreferences p, String text) async {
  Object? root;
  try {
    root = jsonDecode(text.trim());
  } catch (_) {
    throw const FormatException('Yeh valid backup nahi hai');
  }
  if (root is! Map || root['app'] != 'namaz_app' || root['data'] is! Map) {
    throw const FormatException('Yeh Namaz app ka backup nahi hai');
  }
  final data = Map<String, dynamic>.from(root['data'] as Map);
  var n = 0;
  for (final k in backupKeys) {
    if (!data.containsKey(k)) continue;
    final v = data[k];
    if (v is String) {
      await p.setString(k, v);
    } else if (v is bool) {
      await p.setBool(k, v);
    } else if (v is int) {
      await p.setInt(k, v);
    } else if (v is double) {
      await p.setDouble(k, v);
    } else if (v is List) {
      await p.setStringList(k, v.map((e) => '$e').toList());
    } else {
      continue;
    }
    n++;
  }
  return n;
}

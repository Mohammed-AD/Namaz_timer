import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import 'prefs_provider.dart';

/// Each day = one int bitmask (5 bits, one per prayer): tiny, O(1) toggle.
extension LogX on Map<String, int> {
  int mask(DateTime d) => this[dayKey(d)] ?? 0;
  int count(DateTime d) => bits(mask(d));

  /// Total namaz for keys starting with prefix ("2026" or "202609").
  int sum(String prefix) {
    var t = 0;
    forEach((k, v) {
      if (k.startsWith(prefix)) t += bits(v);
    });
    return t;
  }
}

class LogNotifier extends Notifier<Map<String, int>> {
  final String prefKey;
  LogNotifier(this.prefKey);

  @override
  Map<String, int> build() {
    final s = ref.read(prefsProvider).getString(prefKey);
    if (s == null) return {};
    try {
      return (jsonDecode(s) as Map)
          .map((k, v) => MapEntry(k as String, v as int));
    } catch (_) {
      return {};
    }
  }

  void toggle(DateTime d, int i) {
    final k = dayKey(d);
    final m = (state[k] ?? 0) ^ (1 << i);
    final next = Map<String, int>.of(state);
    if (m == 0) {
      next.remove(k);
    } else {
      next[k] = m;
    }
    state = next;
    ref.read(prefsProvider).setString(prefKey, jsonEncode(next));
  }
}

/// Real namaz.
final logProvider = NotifierProvider<LogNotifier, Map<String, int>>(
    () => LogNotifier('log'));

/// Dhikr done at prayer time on special days (kept separate from real namaz).
final specialLogProvider = NotifierProvider<LogNotifier, Map<String, int>>(
    () => LogNotifier('slog'));

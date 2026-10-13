import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import 'prefs_provider.dart';

/// A thing the user reads regularly: a surah (kind 0) or a dhikr (kind 1),
/// with their OWN target ("kitna padhna hai").
class WirdItem {
  final String id, name, arabic;
  final int kind, target, count, total;
  final bool daily; // true: count resets every day
  final String day; // yyyymmdd of the last update (for daily reset)

  const WirdItem({
    required this.id,
    required this.name,
    this.arabic = '',
    required this.kind,
    required this.target,
    required this.daily,
    this.count = 0,
    this.total = 0,
    this.day = '',
  });

  int countFor(String todayKey) => (daily && day != todayKey) ? 0 : count;

  WirdItem copyWith({
    String? name,
    String? arabic,
    int? kind,
    int? target,
    bool? daily,
    int? count,
    int? total,
    String? day,
  }) =>
      WirdItem(
        id: id,
        name: name ?? this.name,
        arabic: arabic ?? this.arabic,
        kind: kind ?? this.kind,
        target: target ?? this.target,
        daily: daily ?? this.daily,
        count: count ?? this.count,
        total: total ?? this.total,
        day: day ?? this.day,
      );

  Map<String, dynamic> toJson() => {
        'i': id,
        'n': name,
        'a': arabic,
        'k': kind,
        't': target,
        'd': daily,
        'c': count,
        'T': total,
        'y': day,
      };

  factory WirdItem.fromJson(Map<String, dynamic> j) => WirdItem(
        id: j['i'] as String,
        name: j['n'] as String,
        arabic: (j['a'] as String?) ?? '',
        kind: j['k'] as int,
        target: j['t'] as int,
        daily: j['d'] as bool,
        count: (j['c'] as int?) ?? 0,
        total: (j['T'] as int?) ?? 0,
        day: (j['y'] as String?) ?? '',
      );
}

const _seed = [
  WirdItem(id: 's1', name: 'Al-Ikhlas', arabic: 'الإخلاص', kind: 0, target: 3, daily: true),
  WirdItem(id: 'd1', name: 'SubhanAllah', arabic: 'سبحان الله', kind: 1, target: 33, daily: true),
  WirdItem(id: 'd2', name: 'Alhamdulillah', arabic: 'الحمد لله', kind: 1, target: 33, daily: true),
  WirdItem(id: 'd3', name: 'Allahu Akbar', arabic: 'الله أكبر', kind: 1, target: 34, daily: true),
  WirdItem(id: 'd4', name: 'Astaghfirullah', arabic: 'أستغفر الله', kind: 1, target: 100, daily: true),
  WirdItem(id: 'd5', name: 'Durood Shareef', arabic: 'اللهم صل على محمد', kind: 1, target: 100, daily: true),
];

class WirdNotifier extends Notifier<List<WirdItem>> {
  @override
  List<WirdItem> build() {
    final s = ref.read(prefsProvider).getString('wird');
    if (s == null) return List.of(_seed);
    try {
      return (jsonDecode(s) as List)
          .map((e) => WirdItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return List.of(_seed);
    }
  }

  void _save() => ref
      .read(prefsProvider)
      .setString('wird', jsonEncode(state.map((e) => e.toJson()).toList()));

  void _replace(String id, WirdItem Function(WirdItem) f) {
    state = [for (final e in state) e.id == id ? f(e) : e];
    _save();
  }

  void add(WirdItem item) {
    state = [...state, item];
    _save();
  }

  void update(WirdItem item) => _replace(item.id, (_) => item);

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  /// +1. Returns true if this tap exactly reaches the target.
  bool tap(String id) {
    final key = dayKey(DateTime.now());
    var reached = false;
    _replace(id, (e) {
      final c = e.countFor(key) + 1;
      reached = c == e.target;
      return e.copyWith(count: c, total: e.total + 1, day: key);
    });
    return reached;
  }

  void undo(String id) {
    final key = dayKey(DateTime.now());
    _replace(id, (e) {
      final c = e.countFor(key);
      if (c == 0) return e;
      return e.copyWith(count: c - 1, total: e.total > 0 ? e.total - 1 : 0, day: key);
    });
  }

  void reset(String id) =>
      _replace(id, (e) => e.copyWith(count: 0, day: dayKey(DateTime.now())));
}

final wirdProvider =
    NotifierProvider<WirdNotifier, List<WirdItem>>(WirdNotifier.new);

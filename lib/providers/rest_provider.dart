import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import 'clock_provider.dart';
import 'prefs_provider.dart';
import 'settings_provider.dart';

/// A run of consecutive rest days. [end] == null means "still ongoing".
class RestRange {
  final String start;
  final String? end;
  const RestRange(this.start, [this.end]);

  List<String> toJson() => [start, end ?? ''];

  factory RestRange.fromJson(dynamic j) {
    final l = (j as List).cast<String>();
    return RestRange(l[0], l[1].isEmpty ? null : l[1]);
  }

  bool covers(String k) =>
      k.compareTo(start) >= 0 && (end == null || k.compareTo(end!) <= 0);
}

class RestState {
  final List<RestRange> ranges;

  /// Qada fasts already made up / extra fasts the user added manually.
  final int done, extra;
  const RestState({this.ranges = const [], this.done = 0, this.extra = 0});

  bool isRest(DateTime d) {
    final k = dayKey(d);
    for (final r in ranges) {
      if (r.covers(k)) return true;
    }
    return false;
  }

  RestRange? get open =>
      ranges.isNotEmpty && ranges.last.end == null ? ranges.last : null;

  RestState copyWith({List<RestRange>? ranges, int? done, int? extra}) =>
      RestState(
        ranges: ranges ?? this.ranges,
        done: done ?? this.done,
        extra: extra ?? this.extra,
      );
}

class RestNotifier extends Notifier<RestState> {
  @override
  RestState build() {
    final p = ref.read(prefsProvider);
    var ranges = <RestRange>[];
    try {
      final s = p.getString('rest');
      if (s != null) {
        ranges = (jsonDecode(s) as List).map(RestRange.fromJson).toList();
      }
    } catch (_) {
      ranges = [];
    }
    return RestState(
      ranges: ranges,
      done: p.getInt('fastDone') ?? 0,
      extra: p.getInt('fastExtra') ?? 0,
    );
  }

  void _saveRanges() => ref.read(prefsProvider).setString(
      'rest', jsonEncode(state.ranges.map((r) => r.toJson()).toList()));

  void start(DateTime from) {
    if (state.open != null) return;
    state = state.copyWith(ranges: [...state.ranges, RestRange(dayKey(from))]);
    _saveRanges();
  }

  /// Ends the ongoing run. [today] itself is not a rest day any more.
  void end(DateTime today) {
    final o = state.open;
    if (o == null) return;
    final last = dayKey(shift(today, -1));
    final list = [...state.ranges]..removeLast();
    if (last.compareTo(o.start) >= 0) list.add(RestRange(o.start, last));
    state = state.copyWith(ranges: list);
    _saveRanges();
  }

  void fastMadeUp() {
    state = state.copyWith(done: state.done + 1);
    ref.read(prefsProvider).setInt('fastDone', state.done);
  }

  void fastAdd() {
    state = state.copyWith(extra: state.extra + 1);
    ref.read(prefsProvider).setInt('fastExtra', state.extra);
  }
}

final restProvider =
    NotifierProvider<RestNotifier, RestState>(RestNotifier.new);

final restEnabledProvider = Provider<bool>(
    (ref) => ref.watch(settingsProvider.select((s) => s.restEnabled)));

/// Is [d] a rest day (and is the feature switched on)?
final restDayProvider = Provider.autoDispose.family<bool, DateTime>(
    (ref, d) => ref.watch(restEnabledProvider) && ref.watch(restProvider).isRest(d));

/// Ramadan fasts still to be made up: rest days that fell in Ramadan + manual
/// extras - fasts already made up.
final fastsOwedProvider = Provider<int>((ref) {
  final st = ref.watch(restProvider);
  final adj = ref.watch(settingsProvider.select((s) => s.hijriAdj));
  final today = ref.watch(todayProvider);
  var auto = 0;
  for (final r in st.ranges) {
    final e = r.end == null ? today : parseKey(r.end!);
    var d = parseKey(r.start);
    var guard = 0;
    while (!d.isAfter(e) && guard++ < 400) {
      if (hijriOf(d, adj).hMonth == 9) auto++;
      d = shift(d, 1);
    }
  }
  return math.max(0, auto + st.extra - st.done);
});

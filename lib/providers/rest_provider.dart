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

  /// An open run covers dates from its start through today, never future dates.
  /// Capping it here prevents a future calendar month from appearing as if a
  /// special-day run had already happened. A caller may pass an explicit
  /// [throughKey] when it has a deterministic clock in tests.
  bool covers(String k, {String? throughKey}) =>
      k.compareTo(start) >= 0 &&
      (end == null
          ? k.compareTo(throughKey ?? dayKey(DateTime.now())) <= 0
          : k.compareTo(end!) <= 0);

  DateTime get startDate => parseKey(start);

  /// Last special day (today while the run is still going).
  DateTime lastDay(DateTime today) => end == null ? today : parseKey(end!);

  /// Number of days in this run, counting the first and the last day.
  int length(DateTime today) =>
      math.max(1, daysBetween(startDate, lastDay(today)) + 1);
}

class RestState {
  final List<RestRange> ranges;

  /// Qada fasts already made up / extra fasts the user added manually.
  final int done, extra;
  const RestState({this.ranges = const [], this.done = 0, this.extra = 0});

  bool isRest(DateTime d, {DateTime? today}) {
    final k = dayKey(d);
    final through = dayKey(dayOnly(today ?? DateTime.now()));
    for (final r in ranges) {
      if (r.covers(k, throughKey: through)) return true;
    }
    return false;
  }

  RestRange? get open =>
      ranges.isNotEmpty && ranges.last.end == null ? ranges.last : null;

  /// The run that contains [d], if any.
  RestRange? rangeOf(DateTime d, {DateTime? today}) {
    final k = dayKey(d);
    final through = dayKey(dayOnly(today ?? DateTime.now()));
    for (final r in ranges) {
      if (r.covers(k, throughKey: through)) return r;
    }
    return null;
  }

  /// Whether a new run may begin on [date] without future-dating or overlap.
  bool canStart(DateTime date, {DateTime? today}) {
    if (open != null || dayOnly(date).isAfter(dayOnly(today ?? DateTime.now()))) {
      return false;
    }
    if (ranges.isEmpty) return true;
    final end = ranges.last.end;
    return end != null && dayKey(dayOnly(date)).compareTo(end) > 0;
  }

  /// Finished runs only, oldest first.
  List<RestRange> get finished => ranges.where((r) => r.end != null).toList();

  /// Average length (days) of finished runs, null if there are none.
  double? avgLength(DateTime today) {
    final f = finished;
    if (f.isEmpty) return null;
    return f.fold<int>(0, (a, r) => a + r.length(today)) / f.length;
  }

  /// Average gap between the starts of consecutive runs (last 6 gaps).
  /// Gaps outside 15-90 days are ignored as data-entry mistakes.
  int? avgCycle() {
    final starts = ranges.map((r) => r.startDate).toList()..sort();
    final gaps = <int>[];
    for (var i = 1; i < starts.length; i++) {
      final g = daysBetween(starts[i - 1], starts[i]);
      if (g >= 15 && g <= 90) gaps.add(g);
    }
    if (gaps.isEmpty) return null;
    final recent = gaps.length > 6 ? gaps.sublist(gaps.length - 6) : gaps;
    return (recent.fold<int>(0, (a, b) => a + b) / recent.length).round();
  }

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
    var s = dayOnly(from);
    // Never overlap the previous run.
    if (state.ranges.isNotEmpty) {
      final prevEnd = state.ranges.last.end;
      if (prevEnd != null && dayKey(s).compareTo(prevEnd) <= 0) {
        s = shift(parseKey(prevEnd), 1);
      }
    }
    state = state.copyWith(ranges: [...state.ranges, RestRange(dayKey(s))]);
    _saveRanges();
  }

  /// Ends the ongoing run; [lastDay] is the final special day.
  void endLast(DateTime lastDay) {
    final o = state.open;
    if (o == null) return;
    final last = dayKey(lastDay);
    final list = [...state.ranges]..removeLast();
    if (last.compareTo(o.start) >= 0) list.add(RestRange(o.start, last));
    state = state.copyWith(ranges: list);
    _saveRanges();
  }

  /// Ends the ongoing run. [today] itself is not a rest day any more.
  void end(DateTime today) => endLast(shift(today, -1));

  /// Deletes one saved run (for a wrong entry).
  void removeAt(int index) {
    if (index < 0 || index >= state.ranges.length) return;
    final list = [...state.ranges]..removeAt(index);
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

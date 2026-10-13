import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';

/// Slow heartbeat (every 20s) for things that only need minute precision.
final pulseProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 20), (_) => DateTime.now());
});

/// Today's date (no time). Value only changes at midnight, so widgets that
/// watch this rebuild once per day, not every pulse.
final todayProvider = Provider<DateTime>(
  (ref) => dayOnly(ref.watch(pulseProvider).value ?? DateTime.now()),
);

/// 1-second ticker. autoDispose: it only runs while a widget is watching it
/// (the Watch tab, and only while that tab is visible).
final secondProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

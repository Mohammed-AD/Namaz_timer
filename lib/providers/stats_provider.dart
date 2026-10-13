import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import 'clock_provider.dart';
import 'log_provider.dart';
import 'rest_provider.dart';

/// Consecutive days with all 5 namaz. Rest days neither add to nor break it,
/// so nobody loses a streak because of them. Today counts only if complete.
final streakProvider = Provider<int>((ref) {
  final log = ref.watch(logProvider);
  final rest = ref.watch(restProvider);
  final on = ref.watch(restEnabledProvider);
  var d = ref.watch(todayProvider);
  bool off(DateTime x) => on && rest.isRest(x);

  if (!off(d) && log.count(d) < 5) d = shift(d, -1);
  var n = 0, guard = 0;
  while (guard++ < 3650) {
    if (off(d)) {
      d = shift(d, -1);
      continue;
    }
    if (log.count(d) < 5) break;
    n++;
    d = shift(d, -1);
  }
  return n;
});

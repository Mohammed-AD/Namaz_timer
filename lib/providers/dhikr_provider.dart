import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import 'prefs_provider.dart';

class DhikrItem {
  final String name, arabic;
  final int target;
  const DhikrItem(this.name, this.arabic, this.target);
}

const dhikrItems = [
  DhikrItem('SubhanAllah', 'سبحان الله', 33),
  DhikrItem('Alhamdulillah', 'الحمد لله', 33),
  DhikrItem('Allahu Akbar', 'الله أكبر', 34),
  DhikrItem('La ilaha illallah', 'لا إله إلا الله', 100),
  DhikrItem('Astaghfirullah', 'أستغفر الله', 100),
  DhikrItem('Durood Shareef', 'اللهم صل على محمد', 100),
];

class DhikrState {
  final int preset, count, today;
  const DhikrState(
      {required this.preset, required this.count, required this.today});

  DhikrState copyWith({int? preset, int? count, int? today}) => DhikrState(
        preset: preset ?? this.preset,
        count: count ?? this.count,
        today: today ?? this.today,
      );
}

class DhikrNotifier extends Notifier<DhikrState> {
  @override
  DhikrState build() {
    final p = ref.read(prefsProvider);
    final sameDay = p.getString('dDay') == dayKey(DateTime.now());
    return DhikrState(
      preset: (p.getInt('dPreset') ?? 0).clamp(0, dhikrItems.length - 1),
      count: p.getInt('dCount') ?? 0,
      today: sameDay ? (p.getInt('dToday') ?? 0) : 0,
    );
  }

  /// Returns true when this tap completes a full round.
  bool tap() {
    final p = ref.read(prefsProvider);
    final key = dayKey(DateTime.now());
    var c = state.count + 1;
    var roundDone = false;
    if (c >= dhikrItems[state.preset].target) {
      c = 0;
      roundDone = true;
    }
    final t = (p.getString('dDay') == key ? state.today : 0) + 1;
    state = state.copyWith(count: c, today: t);
    p.setInt('dCount', c);
    p.setInt('dToday', t);
    p.setString('dDay', key);
    return roundDone;
  }

  void reset() {
    state = state.copyWith(count: 0);
    ref.read(prefsProvider).setInt('dCount', 0);
  }

  void setPreset(int i) {
    state = state.copyWith(preset: i, count: 0);
    final p = ref.read(prefsProvider);
    p.setInt('dPreset', i);
    p.setInt('dCount', 0);
  }
}

final dhikrProvider =
    NotifierProvider<DhikrNotifier, DhikrState>(DhikrNotifier.new);

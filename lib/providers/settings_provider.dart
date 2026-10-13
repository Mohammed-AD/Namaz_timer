import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'prefs_provider.dart';

const watchStyles = ['Classic', 'Modern', 'Digital', 'Ring'];

class Settings {
  final int city;
  final bool hanafi;
  final bool restEnabled; // "Special days" feature
  final int hijriAdj; // -1, 0, +1
  final int themeMode; // 0 system, 1 light, 2 dark (same order as ThemeMode)
  final int style; // 0-3 watch style

  /// Per prayer [fajr, dhuhr, asr, maghrib, isha]:
  /// minute offset from the calculated time, and an exact time (minutes after
  /// midnight, -1 = not set). An exact time wins over the offset.
  final List<int> offsets;
  final List<int> fixed;

  const Settings({
    required this.city,
    required this.hanafi,
    required this.restEnabled,
    required this.hijriAdj,
    required this.themeMode,
    required this.style,
    required this.offsets,
    required this.fixed,
  });

  bool customAt(int i) => offsets[i] != 0 || fixed[i] >= 0;
  bool get anyCustom => List.generate(5, customAt).any((e) => e);

  Settings copyWith({
    int? city,
    bool? hanafi,
    bool? restEnabled,
    int? hijriAdj,
    int? themeMode,
    int? style,
    List<int>? offsets,
    List<int>? fixed,
  }) =>
      Settings(
        city: city ?? this.city,
        hanafi: hanafi ?? this.hanafi,
        restEnabled: restEnabled ?? this.restEnabled,
        hijriAdj: hijriAdj ?? this.hijriAdj,
        themeMode: themeMode ?? this.themeMode,
        style: style ?? this.style,
        offsets: offsets ?? this.offsets,
        fixed: fixed ?? this.fixed,
      );
}

class SettingsNotifier extends Notifier<Settings> {
  static List<int> _list(List<String>? raw, int fallback) {
    final l = raw?.map((e) => int.tryParse(e) ?? fallback).toList();
    return (l != null && l.length == 5) ? l : List.filled(5, fallback);
  }

  @override
  Settings build() {
    final p = ref.read(prefsProvider);
    return Settings(
      city: (p.getInt('city') ?? 0).clamp(0, cities.length - 1),
      hanafi: p.getBool('hanafi') ?? true,
      restEnabled: p.getBool('restOn') ?? false,
      hijriAdj: (p.getInt('hAdj') ?? 0).clamp(-1, 1),
      themeMode: (p.getInt('theme') ?? 0).clamp(0, 2),
      style: (p.getInt('watchStyle') ?? 0).clamp(0, watchStyles.length - 1),
      offsets: _list(p.getStringList('pOff'), 0),
      fixed: _list(p.getStringList('pFix'), -1),
    );
  }

  void setCity(int v) {
    state = state.copyWith(city: v);
    ref.read(prefsProvider).setInt('city', v);
  }

  void setHanafi(bool v) {
    state = state.copyWith(hanafi: v);
    ref.read(prefsProvider).setBool('hanafi', v);
  }

  void setRestEnabled(bool v) {
    state = state.copyWith(restEnabled: v);
    ref.read(prefsProvider).setBool('restOn', v);
  }

  void setHijriAdj(int v) {
    state = state.copyWith(hijriAdj: v);
    ref.read(prefsProvider).setInt('hAdj', v);
  }

  void setThemeMode(int v) {
    state = state.copyWith(themeMode: v);
    ref.read(prefsProvider).setInt('theme', v);
  }

  void setStyle(int v) {
    final value = v.clamp(0, watchStyles.length - 1);
    state = state.copyWith(style: value);
    ref.read(prefsProvider).setInt('watchStyle', value);
  }

  void _saveTimes() {
    final p = ref.read(prefsProvider);
    p.setStringList('pOff', state.offsets.map((e) => '$e').toList());
    p.setStringList('pFix', state.fixed.map((e) => '$e').toList());
  }

  /// +/- minutes on prayer [i]. Moves the exact time if one is set.
  void nudge(int i, int delta) {
    final o = [...state.offsets];
    final f = [...state.fixed];
    if (f[i] >= 0) {
      f[i] = (f[i] + delta + 1440) % 1440;
    } else {
      o[i] = (o[i] + delta).clamp(-180, 180);
    }
    state = state.copyWith(offsets: o, fixed: f);
    _saveTimes();
  }

  void setFixed(int i, int minutesOfDay) {
    final f = [...state.fixed];
    f[i] = minutesOfDay;
    state = state.copyWith(fixed: f);
    _saveTimes();
  }

  void clearTime(int i) {
    final o = [...state.offsets];
    final f = [...state.fixed];
    o[i] = 0;
    f[i] = -1;
    state = state.copyWith(offsets: o, fixed: f);
    _saveTimes();
  }

  void clearAllTimes() {
    state = state.copyWith(
        offsets: List.filled(5, 0), fixed: List.filled(5, -1));
    _saveTimes();
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

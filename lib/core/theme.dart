import 'package:flutter/material.dart';

/// All app colours live here, so every screen works in light AND dark.
/// Use `context.pal.xxx` in widgets - never hard-code colours.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg, bgTop, surface, surface2, line, text, muted, faint;
  final Color accent, onAccent, gold, special;

  const AppPalette({
    required this.bg,
    required this.bgTop,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.gold,
    required this.special,
  });

  Color get accentSoft => accent.withValues(alpha: .14);
  Color get specialSoft => special.withValues(alpha: .13);

  static const dark = AppPalette(
    bg: Color(0xFF0A100F),
    bgTop: Color(0xFF12302A),
    surface: Color(0xFF131C1A),
    surface2: Color(0xFF1B2623),
    line: Color(0x1FFFFFFF),
    text: Color(0xFFF1F5F3),
    muted: Color(0xB3F1F5F3),
    faint: Color(0x66F1F5F3),
    accent: Color(0xFF3DDC97),
    onAccent: Color(0xFF04281B),
    gold: Color(0xFFE9C46A),
    special: Color(0xFFB7A4FF),
  );

  static const light = AppPalette(
    bg: Color(0xFFF3F6F4),
    bgTop: Color(0xFFD9EEE5),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEAF0ED),
    line: Color(0x1A0B1A14),
    text: Color(0xFF0E1A15),
    muted: Color(0xB30E1A15),
    faint: Color(0x660E1A15),
    accent: Color(0xFF0B7A5A),
    onAccent: Color(0xFFFFFFFF),
    gold: Color(0xFFB7791F),
    special: Color(0xFF7B61D9),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bg: l(bg, other.bg),
      bgTop: l(bgTop, other.bgTop),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      line: l(line, other.line),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      gold: l(gold, other.gold),
      special: l(special, other.special),
    );
  }
}

extension PaletteX on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>()!;
}

ThemeData buildTheme(AppPalette p, Brightness b) {
  final scheme = ColorScheme(
    brightness: b,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.gold,
    onSecondary: p.onAccent,
    error: const Color(0xFFFF6B6B),
    onError: Colors.white,
    surface: p.surface,
    onSurface: p.text,
  );
  final text = ThemeData(brightness: b, useMaterial3: true)
      .textTheme
      .apply(bodyColor: p.text, displayColor: p.text);

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    textTheme: text,
    extensions: [p],
    dividerColor: p.line,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accentSoft,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? p.accent : p.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? p.accent : p.muted)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.accentSoft,
      selectedIconTheme: IconThemeData(color: p.accent),
      unselectedIconTheme: IconThemeData(color: p.muted),
      selectedLabelTextStyle:
          TextStyle(color: p.accent, fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(color: p.muted, fontSize: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.accentSoft,
      side: BorderSide(color: p.line),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: TextStyle(color: p.text, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface2,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.surface2,
      contentTextStyle: TextStyle(color: p.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.text,
      elevation: 0,
    ),
  );
}

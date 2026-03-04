import 'package:flutter/material.dart';

import 'tactical_colors.dart';

/// Builds a complete [ThemeData] from a [TacticalColorScheme].
///
/// All surface colours, component themes, and text defaults derive from the
/// tactical palette so the entire app stays consistent when the user switches
/// between RED LIGHT, NVG GREEN, DAY WHITE, or BLUE FORCE.
ThemeData buildTheme(TacticalColorScheme colors) {
  final bool isDark = colors.id != 'white';
  final Brightness brightness = isDark ? Brightness.dark : Brightness.light;

  final ColorScheme colorScheme = ColorScheme(
    brightness: brightness,
    primary: colors.accent,
    onPrimary: isDark ? Colors.white : Colors.white,
    secondary: colors.accent,
    onSecondary: isDark ? Colors.white : Colors.white,
    surface: colors.card,
    onSurface: colors.text,
    error: const Color(0xFFCF6679),
    onError: Colors.black,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.bg,

    // ── AppBar ──────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.bg,
      foregroundColor: colors.text,
      titleTextStyle: TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: colors.text,
        letterSpacing: 2,
      ),
      iconTheme: IconThemeData(color: colors.text),
    ),

    // ── Cards ────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.border, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // ── Elevated buttons (44 px min height — glove-friendly) ────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: isDark ? Colors.white : Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.5,
        ),
      ),
    ),

    // ── Text buttons ────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.accent,
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.5,
        ),
      ),
    ),

    // ── Input decoration ────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.card2,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.accent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: TextStyle(
        fontFamily: 'monospace',
        color: colors.text3,
      ),
      hintStyle: TextStyle(
        fontFamily: 'monospace',
        color: colors.text4,
      ),
      prefixIconColor: colors.text3,
      suffixIconColor: colors.text3,
    ),

    // ── Bottom navigation ───────────────────────────────────────────────
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.bg,
      selectedItemColor: colors.accent,
      unselectedItemColor: colors.text3,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        letterSpacing: 1,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        letterSpacing: 1,
      ),
    ),

    // ── Dividers ────────────────────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: colors.border2,
      thickness: 1,
      space: 1,
    ),

    // ── Dialogs ─────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: colors.text,
        letterSpacing: 2,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: colors.text2,
      ),
    ),
  );
}

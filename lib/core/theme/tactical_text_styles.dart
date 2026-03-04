import 'package:flutter/material.dart';

import 'tactical_colors.dart';

/// Pre-defined text styles for tactical UI elements.
///
/// Every style uses a monospace font to reinforce the military-data aesthetic
/// and accepts a [TacticalColorScheme] so colours automatically follow the
/// active theme.
class TacticalTextStyles {
  TacticalTextStyles._(); // prevent instantiation

  /// Page / section headings.
  static TextStyle heading(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: c.text,
        letterSpacing: 2,
      );

  /// Smaller headings / card titles.
  static TextStyle subheading(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 16,
        color: c.text2,
      );

  /// General body text.
  static TextStyle body(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: c.text2,
      );

  /// Captions, timestamps, footnotes.
  static TextStyle caption(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: c.text3,
      );

  /// Large MGRS grid-reference readout (e.g. hero display).
  static TextStyle mgrsDisplay(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: c.accent,
        letterSpacing: 4,
      );

  /// Compact MGRS readout for lists / cards.
  static TextStyle mgrsSmall(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: c.accent,
        letterSpacing: 2,
      );

  /// Full-screen bearing / azimuth display.
  static TextStyle bearingDisplay(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        fontSize: 36,
        color: c.text,
      );

  /// Button labels.
  static TextStyle buttonText(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: c.text,
        letterSpacing: 1.5,
      );

  /// Tiny uppercase field labels.
  static TextStyle label(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        color: c.text3,
        letterSpacing: 1,
      );

  /// Prominent data values (speed, altitude, etc.).
  static TextStyle value(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: c.text,
      );

  /// Very dim / low-priority text.
  static TextStyle dim(TacticalColorScheme c) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: c.text4,
      );
}

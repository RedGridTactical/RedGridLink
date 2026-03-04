/// Tactical colour themes ported from useTheme.js.
///
/// Colour keys:
///   text   — primary text / arrows / headings
///   text2  — secondary text (labels, dim values)
///   text3  — tertiary text (subtitles, hints)
///   text4  — very dim text (footers, disabled)
///   text5  — near-bg decorative (tiny separators)
///   accent — interactive highlights (same as text usually)
///   bg     — screen background
///   card   — card / modal surface
///   card2  — input / field surface
///   border — medium border
///   border2— dim border / divider
import 'package:flutter/material.dart';

class TacticalColorScheme {
  final String id;
  final String label;
  final String sub;
  final bool pro;
  final Color bg;
  final Color text;
  final Color text2;
  final Color text3;
  final Color text4;
  final Color text5;
  final Color accent;
  final Color card;
  final Color card2;
  final Color border;
  final Color border2;

  const TacticalColorScheme({
    required this.id,
    required this.label,
    required this.sub,
    required this.pro,
    required this.bg,
    required this.text,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.text5,
    required this.accent,
    required this.card,
    required this.card2,
    required this.border,
    required this.border2,
  });
}

const Map<String, TacticalColorScheme> tacticalThemes = {
  'red': TacticalColorScheme(
    id: 'red',
    label: 'RED LIGHT',
    sub: 'Default tactical display',
    pro: false,
    bg: Color(0xFF0A0000),
    text: Color(0xFFCC0000),
    text2: Color(0xFFBB3333),
    text3: Color(0xFFAA2222),
    text4: Color(0xFF330000),
    text5: Color(0xFF1A0000),
    accent: Color(0xFFCC0000),
    card: Color(0xFF0D0000),
    card2: Color(0xFF110000),
    border: Color(0xFF660000),
    border2: Color(0xFF330000),
  ),
  'green': TacticalColorScheme(
    id: 'green',
    label: 'NVG GREEN',
    sub: 'Night vision goggle compatible',
    pro: true,
    bg: Color(0xFF001400),
    text: Color(0xFF00CC00),
    text2: Color(0xFF33BB33),
    text3: Color(0xFF22AA22),
    text4: Color(0xFF003300),
    text5: Color(0xFF001A00),
    accent: Color(0xFF00CC00),
    card: Color(0xFF001800),
    card2: Color(0xFF001E00),
    border: Color(0xFF006600),
    border2: Color(0xFF003300),
  ),
  'white': TacticalColorScheme(
    id: 'white',
    label: 'DAY WHITE',
    sub: 'High visibility in sunlight',
    pro: true,
    bg: Color(0xFFF5F5F5),
    text: Color(0xFF111111),
    text2: Color(0xFF333333),
    text3: Color(0xFF555555),
    text4: Color(0xFF999999),
    text5: Color(0xFFDDDDDD),
    accent: Color(0xFFCC0000),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFEEEEEE),
    border: Color(0xFF999999),
    border2: Color(0xFFCCCCCC),
  ),
  'blue': TacticalColorScheme(
    id: 'blue',
    label: 'BLUE FORCE',
    sub: 'Blue-force tracker color scheme',
    pro: true,
    bg: Color(0xFF000A14),
    text: Color(0xFF0099DD),
    text2: Color(0xFF33AABB),
    text3: Color(0xFF2288AA),
    text4: Color(0xFF002233),
    text5: Color(0xFF00111A),
    accent: Color(0xFF0099DD),
    card: Color(0xFF000E1A),
    card2: Color(0xFF001422),
    border: Color(0xFF004466),
    border2: Color(0xFF002233),
  ),
};

/// Get a tactical color scheme by ID, defaulting to 'red'.
TacticalColorScheme getTacticalColors(String themeId) {
  return tacticalThemes[themeId] ?? tacticalThemes['red']!;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/mgrs.dart';
import '../../../core/utils/voice.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/mode_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../common/widgets/bearing_arrow.dart';
import '../../common/widgets/mgrs_display.dart';
import '../../common/widgets/section_header.dart';
import '../../common/widgets/tactical_button.dart';
import '../../common/widgets/tactical_card.dart';
import 'widgets/precision_selector.dart';
import 'widgets/wayfinder_panel.dart';

/// Provider for the selected MGRS precision level (1-5).
final mgrsPrecisionProvider = StateProvider<int>((ref) => 5);

/// Main MGRS grid display screen -- the solo navigation screen.
///
/// Layout:
///   Top 40% : Large MGRS display with precision toggle
///   Middle  : Heading arrow + bearing value + speed
///   Bottom  : Altitude, accuracy, lat/lon, action buttons, wayfinder
class GridScreen extends ConsumerWidget {
  const GridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final position = ref.watch(currentPositionProvider);
    final precision = ref.watch(mgrsPrecisionProvider);
    final declination = ref.watch(declinationProvider);
    final compassHeading = ref.watch(compassHeadingProvider);
    final mode = ref.watch(currentModeProvider);
    final isDemo = ref.watch(demoModeProvider);

    // Use compass heading when stationary (speed < 0.5 m/s) or GPS heading
    // is unavailable. GPS heading is only reliable while moving.
    final double? effectiveHeading;
    final speed = position?.speed ?? 0;
    if (speed > 0.5 && position?.heading != null && position!.heading! > 0) {
      effectiveHeading = position.heading;
    } else {
      effectiveHeading = compassHeading ?? position?.heading;
    }

    // Compute MGRS at selected precision
    final String mgrsRaw = position != null
        ? toMGRS(position.lat, position.lon, precision)
        : '--- -- ----- -----';
    final String mgrsFormatted =
        position != null ? formatMGRS(mgrsRaw) : '--- -- ----- -----';

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- MODE HEADER ----
              Row(
                children: [
                  Icon(mode.icon, size: 16, color: colors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'GRID \u2022 ${mode.gridSubtitle.toUpperCase()}',
                    style: TacticalTextStyles.label(colors).copyWith(
                      color: colors.accent,
                      letterSpacing: 1,
                    ),
                  ),
                  if (isDemo) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'DEMO',
                        style: TacticalTextStyles.caption(colors).copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // ---- MGRS DISPLAY ----
              _MgrsSection(
                mgrsFormatted: mgrsFormatted,
                mgrsRaw: mgrsRaw,
                position: position,
                precision: precision,
                colors: colors,
                onPrecisionChanged: (v) {
                  ref.read(mgrsPrecisionProvider.notifier).state = v;
                },
              ),

              const SizedBox(height: 16),

              // ---- HEADING / SPEED ----
              _HeadingSection(
                heading: effectiveHeading,
                speed: position?.speed,
                colors: colors,
              ),

              const SizedBox(height: 16),

              // ---- ALTITUDE / ACCURACY / LAT-LON ----
              _InfoSection(
                position: position,
                declination: declination,
                colors: colors,
              ),

              const SizedBox(height: 16),

              // ---- ACTION BUTTONS ----
              _ActionButtons(
                mgrsFormatted: mgrsFormatted,
                colors: colors,
              ),

              const SizedBox(height: 16),

              // ---- WAYFINDER PANEL ----
              WayfinderPanel(colors: colors, mode: mode),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MGRS section: large display + precision selector
// ---------------------------------------------------------------------------

class _MgrsSection extends StatelessWidget {
  const _MgrsSection({
    required this.mgrsFormatted,
    required this.mgrsRaw,
    required this.position,
    required this.precision,
    required this.colors,
    required this.onPrecisionChanged,
  });

  final String mgrsFormatted;
  final String mgrsRaw;
  final dynamic position;
  final int precision;
  final TacticalColorScheme colors;
  final ValueChanged<int> onPrecisionChanged;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Large MGRS readout
          MgrsDisplay(
            mgrs: mgrsFormatted,
            isLarge: true,
            colors: colors,
          ),
          const SizedBox(height: 8),
          // Lat/lon below in smaller text
          if (position != null)
            Text(
              '${position.lat.toStringAsFixed(6)}, '
              '${position.lon.toStringAsFixed(6)}',
              style: TacticalTextStyles.caption(colors),
            )
          else
            Text(
              'Waiting for GPS fix...',
              style: TacticalTextStyles.caption(colors),
            ),
          const SizedBox(height: 16),
          // Precision selector
          SectionHeader(title: 'Precision', colors: colors),
          const SizedBox(height: 8),
          PrecisionSelector(
            currentPrecision: precision,
            onChanged: onPrecisionChanged,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Heading section: compass arrow + bearing + speed
// ---------------------------------------------------------------------------

class _HeadingSection extends StatelessWidget {
  const _HeadingSection({
    required this.heading,
    required this.speed,
    required this.colors,
  });

  final double? heading;
  final double? speed;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final double displayHeading = heading ?? 0;
    final double displaySpeed = speed ?? 0;

    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Compass arrow
          BearingArrow(
            bearingDegrees: displayHeading,
            size: 56,
            colors: colors,
          ),
          const SizedBox(width: 16),
          // Bearing value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HEADING',
                  style: TacticalTextStyles.label(colors),
                ),
                Text(
                  heading != null
                      ? '${heading!.toStringAsFixed(0)}\u00B0'
                      : '---\u00B0',
                  style: TacticalTextStyles.bearingDisplay(colors).copyWith(
                    fontSize: 32,
                  ),
                ),
              ],
            ),
          ),
          // Speed
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SPEED',
                style: TacticalTextStyles.label(colors),
              ),
              Text(
                (displaySpeed * 3.6).toStringAsFixed(1),
                style: TacticalTextStyles.value(colors),
              ),
              Text(
                'km/h',
                style: TacticalTextStyles.caption(colors),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info section: altitude, accuracy, declination
// ---------------------------------------------------------------------------

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.position,
    required this.declination,
    required this.colors,
  });

  final dynamic position;
  final double declination;
  final TacticalColorScheme colors;

  String _accuracyLabel(double? accuracy) {
    if (accuracy == null) return '---';
    if (accuracy <= 3) return 'EXCELLENT';
    if (accuracy <= 10) return 'GOOD';
    if (accuracy <= 25) return 'FAIR';
    return 'POOR';
  }

  Color _accuracyColor(double? accuracy) {
    if (accuracy == null) return colors.text4;
    if (accuracy <= 3) return const Color(0xFF00CC00);
    if (accuracy <= 10) return colors.accent;
    if (accuracy <= 25) return const Color(0xFFCCAA00);
    return const Color(0xFFCC0000);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Altitude
        Expanded(
          child: TacticalCard(
            colors: colors,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ALT', style: TacticalTextStyles.label(colors)),
                const SizedBox(height: 4),
                Text(
                  position?.altitude != null
                      ? '${position.altitude.toStringAsFixed(0)}m'
                      : '---',
                  style: TacticalTextStyles.value(colors),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // GPS accuracy
        Expanded(
          child: TacticalCard(
            colors: colors,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GPS', style: TacticalTextStyles.label(colors)),
                const SizedBox(height: 4),
                Text(
                  position?.accuracy != null
                      ? '\u00B1${position.accuracy.toStringAsFixed(0)}m'
                      : '---',
                  style: TacticalTextStyles.value(colors).copyWith(
                    color: _accuracyColor(position?.accuracy),
                  ),
                ),
                Text(
                  _accuracyLabel(position?.accuracy),
                  style: TacticalTextStyles.caption(colors).copyWith(
                    color: _accuracyColor(position?.accuracy),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Declination
        Expanded(
          child: TacticalCard(
            colors: colors,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DECL', style: TacticalTextStyles.label(colors)),
                const SizedBox(height: 4),
                Text(
                  '${declination >= 0 ? "+" : ""}${declination.toStringAsFixed(1)}\u00B0',
                  style: TacticalTextStyles.value(colors),
                ),
                Text(
                  declination >= 0 ? 'EAST' : 'WEST',
                  style: TacticalTextStyles.caption(colors).copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Action buttons: NATO readout + copy
// ---------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.mgrsFormatted,
    required this.colors,
  });

  final String mgrsFormatted;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // NATO phonetic readout
        Expanded(
          child: TacticalButton(
            label: 'Speak',
            icon: Icons.volume_up,
            colors: colors,
            isCompact: true,
            onPressed: () {
              speakMGRS(mgrsFormatted);
            },
          ),
        ),
        const SizedBox(width: 8),
        // Copy MGRS
        Expanded(
          child: TacticalButton(
            label: 'Copy',
            icon: Icons.copy,
            colors: colors,
            isCompact: true,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: mgrsFormatted));
              notifySuccess();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'MGRS COPIED',
                    style: TacticalTextStyles.caption(colors).copyWith(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: colors.accent,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

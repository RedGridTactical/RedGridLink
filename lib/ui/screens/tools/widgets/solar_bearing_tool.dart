import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/tactical.dart';
import '../../../../providers/location_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/widgets/bearing_arrow.dart';
import '../../../common/widgets/tactical_card.dart';
import '../../../common/widgets/section_header.dart';

/// Solar and Lunar bearing tool.
///
/// Shows current sun/moon azimuth + altitude, auto-refreshes every 60 seconds.
class SolarBearingTool extends ConsumerStatefulWidget {
  const SolarBearingTool({super.key});

  @override
  ConsumerState<SolarBearingTool> createState() => _SolarBearingToolState();
}

class _SolarBearingToolState extends ConsumerState<SolarBearingTool> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final position = ref.watch(currentPositionProvider);

    final sun = position != null
        ? solarBearing(_now, position.lat, position.lon)
        : null;
    final moon = position != null
        ? lunarBearing(_now, position.lat, position.lon)
        : null;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title: Text('CELESTIAL NAV', style: TacticalTextStyles.heading(colors)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time display
            TacticalCard(
              colors: colors,
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LOCAL TIME', style: TacticalTextStyles.label(colors)),
                  Text(
                    '${_now.hour.toString().padLeft(2, '0')}:'
                    '${_now.minute.toString().padLeft(2, '0')}:'
                    '${_now.second.toString().padLeft(2, '0')}',
                    style: TacticalTextStyles.value(colors),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (position == null) ...[
              TacticalCard(
                colors: colors,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Waiting for GPS fix to compute celestial positions...',
                  style: TacticalTextStyles.body(colors),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              // Sun section
              SectionHeader(title: 'Sun', colors: colors),
              const SizedBox(height: 8),
              _CelestialBody(
                icon: Icons.wb_sunny,
                name: 'SUN',
                azimuth: sun!.azimuth,
                altitude: sun.altitude,
                statusLabel: sun.isDay ? 'ABOVE HORIZON' : 'BELOW HORIZON',
                isVisible: sun.isDay,
                colors: colors,
              ),

              const SizedBox(height: 16),

              // Moon section
              SectionHeader(title: 'Moon', colors: colors),
              const SizedBox(height: 8),
              _CelestialBody(
                icon: Icons.nightlight_round,
                name: 'MOON',
                azimuth: moon!.azimuth,
                altitude: moon.altitude,
                statusLabel: moon.isUp ? 'ABOVE HORIZON' : 'BELOW HORIZON',
                isVisible: moon.isUp,
                colors: colors,
              ),

              const SizedBox(height: 20),

              // Usage note
              TacticalCard(
                colors: colors,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Point your compass toward the sun or moon bearing '
                  'to calibrate or verify your heading. '
                  'Accuracy: approximately 1 degree.',
                  style: TacticalTextStyles.caption(colors),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Celestial body card
// ---------------------------------------------------------------------------

class _CelestialBody extends StatelessWidget {
  const _CelestialBody({
    required this.icon,
    required this.name,
    required this.azimuth,
    required this.altitude,
    required this.statusLabel,
    required this.isVisible,
    required this.colors,
  });

  final IconData icon;
  final String name;
  final double azimuth;
  final double altitude;
  final String statusLabel;
  final bool isVisible;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      colors: colors,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Bearing arrow
          Column(
            children: [
              BearingArrow(
                bearingDegrees: azimuth,
                size: 48,
                colors: colors,
                color: isVisible ? colors.accent : colors.text4,
              ),
              const SizedBox(height: 4),
              Icon(
                icon,
                color: isVisible ? colors.accent : colors.text4,
                size: 20,
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Data
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('AZIMUTH',
                        style: TacticalTextStyles.label(colors)),
                    const Spacer(),
                    Text(
                      '${azimuth.toStringAsFixed(1)}\u00B0',
                      style: TacticalTextStyles.value(colors),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('ALTITUDE',
                        style: TacticalTextStyles.label(colors)),
                    const Spacer(),
                    Text(
                      '${altitude.toStringAsFixed(1)}\u00B0',
                      style: TacticalTextStyles.body(colors),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVisible
                        ? colors.accent.withValues(alpha: 0.2)
                        : colors.text4.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TacticalTextStyles.caption(colors).copyWith(
                      color: isVisible ? colors.accent : colors.text4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

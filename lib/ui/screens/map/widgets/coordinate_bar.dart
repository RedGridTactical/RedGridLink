// Bottom coordinate display bar for the map screen.
//
// Shows the current map center in MGRS or FixPhrase format, the zoom level,
// and bearing to the last GPS fix (if available). Tapping the coordinate
// cycles the display format; long-pressing copies to clipboard.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/core/extensions/latlng_ext.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/providers/fixphrase_provider.dart';
import 'package:red_grid_link/providers/map_provider.dart';

/// Coordinate display formats for the bottom bar.
enum _CoordFormat { mgrs, fixPhrase }

class CoordinateBar extends ConsumerStatefulWidget {
  final TacticalColorScheme colors;

  const CoordinateBar({super.key, required this.colors});

  @override
  ConsumerState<CoordinateBar> createState() => _CoordinateBarState();
}

class _CoordinateBarState extends ConsumerState<CoordinateBar> {
  _CoordFormat _format = _CoordFormat.mgrs;

  TacticalColorScheme get colors => widget.colors;

  @override
  Widget build(BuildContext context) {
    final center = ref.watch(mapCenterProvider);
    final zoom = ref.watch(mapZoomProvider);
    final service = ref.read(mapControllerServiceProvider);
    final lastGps = service.lastGpsPosition;

    // Compute MGRS for display
    final mgrsStr = center.toFormattedMGRS();

    // Compute FixPhrase (if provider loaded)
    final fpAsync = ref.watch(fixPhraseProvider);
    final fixPhraseStr = fpAsync.valueOrNull?.format(
      center.latitude,
      center.longitude,
    );

    // Determine which string to display
    final bool showFixPhrase =
        _format == _CoordFormat.fixPhrase && fixPhraseStr != null;
    final displayStr = showFixPhrase ? fixPhraseStr : mgrsStr;
    final formatLabel = showFixPhrase ? 'FP' : 'MGRS';
    final copyLabel = showFixPhrase ? 'FIXPHRASE' : 'MGRS';

    // Compute bearing to last GPS fix (if we have one and it differs)
    String bearingStr = '---';
    if (lastGps != null) {
      final bearing = center.bearingTo(lastGps);
      bearingStr = '${bearing.round()}\u00B0';
    }

    // Grid density label
    final gridLabel = service.getCurrentGridDensityLabel();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: colors.border2, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Format indicator chip
            GestureDetector(
              onTap: () {
                setState(() {
                  _format = _format == _CoordFormat.mgrs
                      ? _CoordFormat.fixPhrase
                      : _CoordFormat.mgrs;
                });
              },
              child: _InfoChip(
                label: formatLabel,
                colors: colors,
                icon: Icons.swap_horiz,
              ),
            ),

            const SizedBox(width: 6),

            // Coordinate display (tap to cycle, long-press to copy)
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _format = _format == _CoordFormat.mgrs
                        ? _CoordFormat.fixPhrase
                        : _CoordFormat.mgrs;
                  });
                },
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: displayStr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$copyLabel COPIED',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: colors.text,
                          letterSpacing: 1,
                        ),
                      ),
                      backgroundColor: colors.card,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  displayStr,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                    letterSpacing: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Zoom level
            _InfoChip(
              label: 'Z${zoom.toStringAsFixed(1)}',
              colors: colors,
            ),

            const SizedBox(width: 6),

            // Grid density
            _InfoChip(
              label: gridLabel,
              colors: colors,
            ),

            const SizedBox(width: 6),

            // Bearing to GPS
            _InfoChip(
              label: bearingStr,
              colors: colors,
              icon: Icons.navigation,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small info chip for zoom, grid, and bearing display.
class _InfoChip extends StatelessWidget {
  final String label;
  final TacticalColorScheme colors;
  final IconData? icon;

  const _InfoChip({
    required this.label,
    required this.colors,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.card2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border2, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: colors.text3),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: colors.text2,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

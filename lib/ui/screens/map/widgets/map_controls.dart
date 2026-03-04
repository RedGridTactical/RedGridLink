// Floating map control buttons.
//
// Vertical column of circular tactical buttons for:
//   - Zoom in (+)
//   - Zoom out (-)
//   - Re-center on GPS position
//   - Toggle MGRS grid overlay
//   - Toggle map tile source (OSM / Topo)
//
// All buttons are 44px minimum size for glove-friendly touch targets.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/providers/map_provider.dart';
import 'package:red_grid_link/services/map/tile_manager.dart';

class MapControls extends ConsumerWidget {
  final TacticalColorScheme colors;

  const MapControls({super.key, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = ref.watch(isFollowingProvider);
    final showGrid = ref.watch(showMgrsGridProvider);
    final mapSource = ref.watch(mapSourceProvider);
    final controllerService = ref.read(mapControllerServiceProvider);

    return Positioned(
      right: 12,
      top: MediaQuery.of(context).padding.top + 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom in
          _ControlButton(
            icon: Icons.add,
            colors: colors,
            onPressed: () {
              controllerService.zoomIn();
            },
            tooltip: 'Zoom in',
          ),
          const SizedBox(height: 6),

          // Zoom out
          _ControlButton(
            icon: Icons.remove,
            colors: colors,
            onPressed: () {
              controllerService.zoomOut();
            },
            tooltip: 'Zoom out',
          ),
          const SizedBox(height: 14),

          // Re-center on GPS
          _ControlButton(
            icon: isFollowing ? Icons.my_location : Icons.location_searching,
            colors: colors,
            isActive: isFollowing,
            onPressed: () {
              if (isFollowing) {
                controllerService.stopFollowing();
                ref.read(isFollowingProvider.notifier).state = false;
              } else {
                controllerService.recenter();
                ref.read(isFollowingProvider.notifier).state = true;
              }
            },
            tooltip: isFollowing ? 'Stop following' : 'Re-center GPS',
          ),
          const SizedBox(height: 14),

          // Toggle MGRS grid
          _ControlButton(
            icon: Icons.grid_4x4,
            colors: colors,
            isActive: showGrid,
            onPressed: () {
              ref.read(showMgrsGridProvider.notifier).state = !showGrid;
            },
            tooltip: showGrid ? 'Hide MGRS grid' : 'Show MGRS grid',
          ),
          const SizedBox(height: 6),

          // Toggle map source
          _ControlButton(
            icon: Icons.layers,
            colors: colors,
            label: TileSources.labelFor(mapSource),
            onPressed: () {
              final current = ref.read(mapSourceProvider);
              final next = current == TileSources.osm
                  ? TileSources.topo
                  : TileSources.osm;
              ref.read(mapSourceProvider.notifier).state = next;
            },
            tooltip: 'Switch map source',
          ),
        ],
      ),
    );
  }
}

/// Individual circular control button with tactical styling.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final TacticalColorScheme colors;
  final VoidCallback onPressed;
  final bool isActive;
  final String? label;
  final String? tooltip;

  const _ControlButton({
    required this.icon,
    required this.colors,
    required this.onPressed,
    this.isActive = false,
    this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: isActive
            ? colors.accent.withValues(alpha: 0.2)
            : colors.card.withValues(alpha: 0.88),
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? colors.accent : colors.text2,
                      letterSpacing: 0.5,
                    ),
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: isActive ? colors.accent : colors.text2,
                  ),
          ),
        ),
      ),
    );

    // Add border
    final bordered = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? colors.accent : colors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: button,
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: bordered);
    }
    return bordered;
  }
}

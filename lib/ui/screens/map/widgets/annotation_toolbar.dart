// Drawing toolbar for creating annotations on the map.
//
// Toggle bar at the bottom of the map (above the coordinate bar):
//   - Tools: draw polyline, draw polygon, place marker, cancel
//   - When drawing: tap map to add points, double-tap to finish
//   - Color picker (5 preset colors)
//   - Label input on completion
//   - Save annotation to sync engine
//
// All state is managed through Riverpod providers in map_provider.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/utils/mgrs.dart' as mgrs_util;
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart' as model;
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/map_provider.dart';

/// 5 preset annotation colors.
const List<Color> annotationColors = [
  Color(0xFFFF4444), // Red
  Color(0xFF44AAFF), // Blue
  Color(0xFF44CC44), // Green
  Color(0xFFFFAA00), // Orange
  Color(0xFFCC44CC), // Purple
];

class AnnotationToolbar extends ConsumerWidget {
  final TacticalColorScheme colors;

  const AnnotationToolbar({super.key, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingMode = ref.watch(drawingModeProvider);
    final drawingPoints = ref.watch(drawingPointsProvider);
    final colorIndex = ref.watch(drawingColorIndexProvider);
    final isDrawing = drawingMode != DrawingMode.none;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: colors.border2, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drawing status row (when active)
            if (isDrawing)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      drawingMode == DrawingMode.polyline
                          ? Icons.timeline
                          : drawingMode == DrawingMode.polygon
                              ? Icons.crop_square
                              : Icons.place,
                      size: 14,
                      color: colors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _modeLabel(drawingMode),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: colors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${drawingPoints.length} pts',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: colors.text2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Undo last point
                    if (drawingPoints.isNotEmpty)
                      _SmallButton(
                        icon: Icons.undo,
                        colors: colors,
                        onTap: () {
                          final current = ref.read(drawingPointsProvider);
                          if (current.isNotEmpty) {
                            ref.read(drawingPointsProvider.notifier).state =
                                List.from(current)..removeLast();
                          }
                        },
                        tooltip: 'Undo point',
                      ),
                    const SizedBox(width: 4),
                    // Done
                    if (drawingPoints.length >= 2)
                      _SmallButton(
                        icon: Icons.check,
                        colors: colors,
                        isAccent: true,
                        onTap: () => _finishDrawing(context, ref),
                        tooltip: 'Finish',
                      ),
                  ],
                ),
              ),

            // Tool buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Polyline
                _ToolButton(
                  icon: Icons.timeline,
                  label: 'LINE',
                  colors: colors,
                  isActive: drawingMode == DrawingMode.polyline,
                  onTap: () => _selectTool(ref, DrawingMode.polyline),
                ),

                // Polygon
                _ToolButton(
                  icon: Icons.crop_square,
                  label: 'AREA',
                  colors: colors,
                  isActive: drawingMode == DrawingMode.polygon,
                  onTap: () => _selectTool(ref, DrawingMode.polygon),
                ),

                // Marker
                _ToolButton(
                  icon: Icons.place,
                  label: 'MARK',
                  colors: colors,
                  isActive: drawingMode == DrawingMode.marker,
                  onTap: () => _selectTool(ref, DrawingMode.marker),
                ),

                // Color picker
                _ColorPicker(
                  colors: colors,
                  selectedIndex: colorIndex,
                  onSelect: (i) {
                    ref.read(drawingColorIndexProvider.notifier).state = i;
                  },
                ),

                // Cancel / close
                _ToolButton(
                  icon: isDrawing ? Icons.close : Icons.edit_off,
                  label: isDrawing ? 'CANCEL' : 'CLOSE',
                  colors: colors,
                  isDestructive: isDrawing,
                  onTap: () {
                    if (isDrawing) {
                      _cancelDrawing(ref);
                    } else {
                      ref.read(showAnnotationToolbarProvider.notifier).state =
                          false;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectTool(WidgetRef ref, DrawingMode mode) {
    final current = ref.read(drawingModeProvider);
    if (current == mode) {
      // Deselect tool
      ref.read(drawingModeProvider.notifier).state = DrawingMode.none;
      ref.read(drawingPointsProvider.notifier).state = [];
    } else {
      ref.read(drawingModeProvider.notifier).state = mode;
      ref.read(drawingPointsProvider.notifier).state = [];
    }
  }

  void _cancelDrawing(WidgetRef ref) {
    ref.read(drawingModeProvider.notifier).state = DrawingMode.none;
    ref.read(drawingPointsProvider.notifier).state = [];
  }

  void _finishDrawing(BuildContext context, WidgetRef ref) {
    final mode = ref.read(drawingModeProvider);
    final points = ref.read(drawingPointsProvider);

    if (mode == DrawingMode.marker && points.isNotEmpty) {
      _showLabelDialog(context, ref, isMarker: true);
    } else if (points.length >= 2) {
      _showLabelDialog(context, ref, isMarker: false);
    }
  }

  void _showLabelDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool isMarker,
  }) {
    final labelController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          isMarker ? 'MARKER LABEL' : 'ANNOTATION LABEL',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.text,
            letterSpacing: 1,
          ),
        ),
        content: TextField(
          controller: labelController,
          autofocus: true,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: colors.text,
          ),
          decoration: InputDecoration(
            hintText: 'Enter label (optional)',
            hintStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: colors.text4,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelDrawing(ref);
            },
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: colors.text3,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _saveAnnotation(ref, labelController.text, isMarker);
            },
            child: Text(
              'SAVE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveAnnotation(WidgetRef ref, String label, bool isMarker) {
    final points = ref.read(drawingPointsProvider);
    final colorIndex = ref.read(drawingColorIndexProvider);
    final mode = ref.read(drawingModeProvider);
    final service = ref.read(fieldLinkServiceProvider);
    final colorValue = annotationColors[colorIndex].toARGB32();
    final now = DateTime.now();
    final id =
        '${now.millisecondsSinceEpoch}_${points.hashCode.abs().toString().substring(0, 4)}';

    if (isMarker && points.isNotEmpty) {
      final point = points.first;
      final mgrs = mgrs_util.toMGRS(point.latitude, point.longitude);
      final marker = model.Marker(
        id: id,
        lat: point.latitude,
        lon: point.longitude,
        mgrs: mgrs,
        label: label,
        icon: model.MarkerIcon.waypoint,
        createdBy: service.localDeviceId,
        createdAt: now,
        color: colorValue,
        isSynced: true,
      );
      service.addMarker(marker);
    } else if (points.length >= 2) {
      final annotationPoints = points
          .map((p) => AnnotationPoint(lat: p.latitude, lon: p.longitude))
          .toList();

      final annotation = Annotation(
        id: id,
        type: mode == DrawingMode.polygon
            ? AnnotationType.polygon
            : AnnotationType.polyline,
        points: annotationPoints,
        color: colorValue,
        strokeWidth: 2.0,
        label: label.isNotEmpty ? label : null,
        createdBy: service.localDeviceId,
        createdAt: now,
        isSynced: true,
      );
      service.addAnnotation(annotation);
    }

    // Reset drawing state
    ref.read(drawingModeProvider.notifier).state = DrawingMode.none;
    ref.read(drawingPointsProvider.notifier).state = [];
  }

  String _modeLabel(DrawingMode mode) {
    return switch (mode) {
      DrawingMode.polyline => 'DRAWING LINE',
      DrawingMode.polygon => 'DRAWING AREA',
      DrawingMode.marker => 'PLACE MARKER',
      DrawingMode.none => '',
    };
  }
}

/// Tool button in the toolbar.
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final TacticalColorScheme colors;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.colors,
    this.isActive = false,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFCC4444)
        : isActive
            ? colors.accent
            : colors.text2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? colors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: colors.accent, width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 7,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Color picker: 5 small circles.
class _ColorPicker extends StatelessWidget {
  final TacticalColorScheme colors;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ColorPicker({
    required this.colors,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(annotationColors.length, (i) {
        final isSelected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: Container(
            width: isSelected ? 18 : 14,
            height: isSelected ? 18 : 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: annotationColors[i],
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : Border.all(
                      color: colors.border,
                      width: 0.5,
                    ),
            ),
          ),
        );
      }),
    );
  }
}

/// Small icon-only button for undo/done.
class _SmallButton extends StatelessWidget {
  final IconData icon;
  final TacticalColorScheme colors;
  final VoidCallback onTap;
  final bool isAccent;
  final String? tooltip;

  const _SmallButton({
    required this.icon,
    required this.colors,
    required this.onTap,
    this.isAccent = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final widget = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isAccent
              ? colors.accent.withValues(alpha: 0.15)
              : colors.card2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isAccent ? colors.accent : colors.border,
            width: isAccent ? 1 : 0.5,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 14,
            color: isAccent ? colors.accent : colors.text2,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widget);
    }
    return widget;
  }
}

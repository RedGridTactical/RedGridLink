// Annotation rendering layer for the map.
//
// Renders synced annotations (polylines and polygons):
//   - Polylines with configurable color and stroke width
//   - Polygons with fill (low alpha) and stroke
//   - Labels at centroid of annotation
//   - Synced annotations from other peers rendered with slight transparency
//   - Tap interaction: show annotation info popup with delete option
//
// Reads reactively from syncedAnnotationsProvider.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/utils/mgrs.dart' as mgrs_util;
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';

class AnnotationLayer extends ConsumerStatefulWidget {
  final TacticalColorScheme colors;

  const AnnotationLayer({super.key, required this.colors});

  @override
  ConsumerState<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends ConsumerState<AnnotationLayer> {
  String? _selectedAnnotationId;

  @override
  Widget build(BuildContext context) {
    final annotationsAsync = ref.watch(syncedAnnotationsProvider);
    final localDeviceId = ref.watch(localDeviceIdProvider);

    return annotationsAsync.when(
      data: (annotations) => _buildLayers(context, annotations, localDeviceId),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLayers(
    BuildContext context,
    List<Annotation> annotations,
    String localDeviceId,
  ) {
    final polylines = <fm.Polyline>[];
    final polygons = <fm.Polygon>[];
    final labelMarkers = <fm.Marker>[];

    for (final annotation in annotations) {
      if (annotation.points.length < 2) continue;

      final points = annotation.points
          .map((p) => LatLng(p.lat, p.lon))
          .toList();

      final color = Color(annotation.color);
      final isRemote = annotation.createdBy != localDeviceId;
      final displayOpacity = isRemote ? 0.65 : 1.0;

      if (annotation.type == AnnotationType.polyline) {
        polylines.add(
          fm.Polyline(
            points: points,
            color: color.withValues(alpha: displayOpacity),
            strokeWidth: annotation.strokeWidth,
          ),
        );
      } else if (annotation.type == AnnotationType.boundary) {
        // Boundary: dashed outline with semi-transparent fill
        polygons.add(
          fm.Polygon(
            points: points,
            color: color.withValues(alpha: 0.08 * displayOpacity),
            borderColor: color.withValues(alpha: displayOpacity),
            borderStrokeWidth: annotation.strokeWidth + 1.0,
          ),
        );
        polylines.add(
          fm.Polyline(
            points: [...points, points.first], // close the loop
            color: color.withValues(alpha: displayOpacity),
            strokeWidth: annotation.strokeWidth,
            pattern: const fm.StrokePattern.dotted(),
          ),
        );
      } else if (annotation.type == AnnotationType.polygon) {
        polygons.add(
          fm.Polygon(
            points: points,
            color: color.withValues(alpha: 0.1 * displayOpacity),
            borderColor: color.withValues(alpha: displayOpacity),
            borderStrokeWidth: annotation.strokeWidth,
          ),
        );
      }

      // Tappable label/target at centroid
      final centroid = _computeCentroid(points);
      final hasLabel = annotation.label != null && annotation.label!.isNotEmpty;

      labelMarkers.add(
        fm.Marker(
          point: centroid,
          width: hasLabel ? 100 : 30,
          height: hasLabel ? 20 : 30,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedAnnotationId =
                    _selectedAnnotationId == annotation.id
                        ? null
                        : annotation.id;
              });
            },
            child: hasLabel
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.colors.bg.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: color.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      annotation.label!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Container(
                    // Invisible tap target for annotations without labels
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      );
    }

    // Info popup for selected annotation
    if (_selectedAnnotationId != null) {
      final selected = annotations
          .where((a) => a.id == _selectedAnnotationId)
          .firstOrNull;

      if (selected != null && selected.points.isNotEmpty) {
        final points = selected.points
            .map((p) => LatLng(p.lat, p.lon))
            .toList();
        final centroid = _computeCentroid(points);

        labelMarkers.add(
          fm.Marker(
            point: centroid,
            width: 240,
            height: 180,
            alignment: Alignment.topCenter,
            child: _AnnotationInfoPopup(
              annotation: selected,
              colors: widget.colors,
              onClose: () =>
                  setState(() => _selectedAnnotationId = null),
              onDelete: () =>
                  _confirmDeleteAnnotation(context, selected),
            ),
          ),
        );
      }
    }

    // Stack layers: polygons first, then polylines, then labels
    return Stack(
      children: [
        if (polygons.isNotEmpty)
          fm.PolygonLayer(polygons: polygons),
        if (polylines.isNotEmpty)
          fm.PolylineLayer(polylines: polylines),
        if (labelMarkers.isNotEmpty)
          fm.MarkerLayer(markers: labelMarkers),
      ],
    );
  }

  /// Show a confirmation dialog before deleting an annotation.
  void _confirmDeleteAnnotation(
    BuildContext context,
    Annotation annotation,
  ) {
    final displayName = (annotation.label != null && annotation.label!.isNotEmpty)
        ? annotation.label!
        : 'annotation';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.card,
        title: Text(
          'DELETE ${ displayName.toUpperCase() }?',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: widget.colors.text,
            letterSpacing: 1,
          ),
        ),
        content: Text(
          'This will remove the annotation for all peers.',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: widget.colors.text2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: widget.colors.text3,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(fieldLinkServiceProvider).removeAnnotation(
                    annotation.id,
                  );
              setState(() => _selectedAnnotationId = null);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFFCC4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compute the centroid of a list of points.
  LatLng _computeCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (points.length == 1) return points.first;

    double latSum = 0;
    double lonSum = 0;
    for (final p in points) {
      latSum += p.latitude;
      lonSum += p.longitude;
    }
    return LatLng(latSum / points.length, lonSum / points.length);
  }
}

/// Info popup for an annotation.
class _AnnotationInfoPopup extends StatelessWidget {
  final Annotation annotation;
  final TacticalColorScheme colors;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const _AnnotationInfoPopup({
    required this.annotation,
    required this.colors,
    required this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeStr = switch (annotation.type) {
      AnnotationType.polyline => 'POLYLINE',
      AnnotationType.polygon => 'POLYGON',
      AnnotationType.boundary => 'BOUNDARY',
    };
    final pointCount = annotation.points.length;

    // MGRS of first point
    final firstPoint = annotation.points.first;
    final mgrsStr = mgrs_util.formatMGRS(
      mgrs_util.toMGRS(firstPoint.lat, firstPoint.lon),
    );

    return Container(
      width: 230,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Color(annotation.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  annotation.label ?? typeStr,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, size: 14, color: colors.text3),
              ),
            ],
          ),
          const SizedBox(height: 6),

          _Row(label: 'TYPE', value: typeStr, colors: colors),
          _Row(label: 'PTS', value: '$pointCount', colors: colors),
          _Row(label: 'MGRS', value: mgrsStr, colors: colors, isAccent: true),
          _Row(
            label: 'BY',
            value: annotation.createdBy.length > 12
                ? '${annotation.createdBy.substring(0, 12)}..'
                : annotation.createdBy,
            colors: colors,
          ),

          const SizedBox(height: 8),

          // Delete button
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFCC4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFFCC4444).withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: const Text(
                'DELETE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Color(0xFFCC4444),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final TacticalColorScheme colors;
  final bool isAccent;

  const _Row({
    required this.label,
    required this.value,
    required this.colors,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: colors.text4,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: isAccent ? colors.accent : colors.text2,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

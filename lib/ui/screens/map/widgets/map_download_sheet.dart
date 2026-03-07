// Bottom sheet for downloading map regions for offline use.
//
// Provides:
//   - "Download Current View" with tile count estimate and region name
//   - Download progress bar with cancel button
//   - List of downloaded regions with size and delete option
//   - Pro gating: free tier limited to 1 region

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/core/constants/map_constants.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/core/theme/tactical_text_styles.dart';
import 'package:red_grid_link/core/utils/haptics.dart';
import 'package:red_grid_link/data/models/entitlement.dart';
import 'package:red_grid_link/data/models/map_region.dart';
import 'package:red_grid_link/providers/map_provider.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/providers/theme_provider.dart';
import 'package:red_grid_link/ui/common/widgets/paywall_sheet.dart';

/// Shows the map download management bottom sheet.
void showMapDownloadSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MapDownloadSheet(),
  );
}

class _MapDownloadSheet extends ConsumerStatefulWidget {
  const _MapDownloadSheet();

  @override
  ConsumerState<_MapDownloadSheet> createState() => _MapDownloadSheetState();
}

class _MapDownloadSheetState extends ConsumerState<_MapDownloadSheet> {
  final _nameController = TextEditingController(text: 'My Region');

  /// Current download progress (null = not downloading).
  double? _downloadProgress;

  /// Whether a download is currently active.
  bool _isDownloading = false;

  /// Stream subscription for the active download.
  StreamSubscription<double>? _downloadSub;

  /// Error message from a failed download.
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _downloadSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final downloadedRegions = ref.watch(downloadedRegionsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20, color: colors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'OFFLINE MAPS',
                      style: TacticalTextStyles.heading(colors),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Download map tiles for use without internet.',
                  style: TacticalTextStyles.caption(colors),
                ),
              ),

              const SizedBox(height: 16),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Download Current View ────────────────────────
                      if (_isDownloading)
                        _buildDownloadProgress(colors)
                      else
                        _buildDownloadForm(colors),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TacticalTextStyles.caption(colors).copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── Downloaded Regions ───────────────────────────
                      Text(
                        'DOWNLOADED REGIONS',
                        style: TacticalTextStyles.label(colors).copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      downloadedRegions.when(
                        data: (regions) {
                          if (regions.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.border2),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cloud_off,
                                    size: 32,
                                    color: colors.text4,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No offline regions downloaded.',
                                    style: TacticalTextStyles.caption(colors),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Use the form above to download the current map view.',
                                    style: TacticalTextStyles.dim(colors),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: regions.map((region) {
                              return _RegionTile(
                                region: region,
                                colors: colors,
                                onDelete: () => _deleteRegion(region.id),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(colors.accent),
                            ),
                          ),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Failed to load regions.',
                            style: TacticalTextStyles.caption(colors),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Close button
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            alignment: Alignment.center,
                            child: Text(
                              'CLOSE',
                              style: TacticalTextStyles.buttonText(colors),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Download form (idle state)
  // ---------------------------------------------------------------------------

  Widget _buildDownloadForm(TacticalColorScheme colors) {
    final controllerService = ref.read(mapControllerServiceProvider);
    final tileManager = ref.read(tileManagerProvider);

    // Get current viewport bounds — may fail if map hasn't rendered yet.
    int currentZoom;
    int maxZoom;
    MapBounds mapBounds;

    try {
      final camera = controllerService.mapController.camera;
      final bounds = camera.visibleBounds;
      currentZoom = camera.zoom.floor();
      maxZoom = (currentZoom + 2)
          .clamp(currentZoom, MapConstants.maxDownloadZoom.toInt());
      mapBounds = MapBounds(
        north: bounds.north,
        south: bounds.south,
        east: bounds.east,
        west: bounds.west,
      );
    } catch (_) {
      // Camera not yet initialized (map hasn't rendered).
      // Use default CONUS-center viewport as fallback.
      currentZoom = MapConstants.defaultZoom.toInt();
      maxZoom = (currentZoom + 2)
          .clamp(currentZoom, MapConstants.maxDownloadZoom.toInt());
      mapBounds = const MapBounds(
        north: MapConstants.defaultLat + 1,
        south: MapConstants.defaultLat - 1,
        east: MapConstants.defaultLon + 1,
        west: MapConstants.defaultLon - 1,
      );
    }

    // Calculate tile count estimate
    final tileCount = tileManager.estimateTileCount(mapBounds, currentZoom, maxZoom);
    final estimatedSizeMb = (tileCount * 20 / 1024).toStringAsFixed(1); // ~20KB/tile

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DOWNLOAD CURRENT VIEW',
            style: TacticalTextStyles.label(colors).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Region name input
          TextField(
            controller: _nameController,
            style: TacticalTextStyles.body(colors),
            decoration: InputDecoration(
              labelText: 'Region Name',
              labelStyle: TacticalTextStyles.caption(colors),
              filled: true,
              fillColor: colors.card2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.accent),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Estimate info
          _InfoRow(
            label: 'Zoom range',
            value: '$currentZoom – $maxZoom',
            colors: colors,
          ),
          const SizedBox(height: 4),
          _InfoRow(
            label: 'Tiles',
            value: _formatTileCount(tileCount),
            colors: colors,
          ),
          const SizedBox(height: 4),
          _InfoRow(
            label: 'Est. size',
            value: '$estimatedSizeMb MB',
            colors: colors,
          ),
          const SizedBox(height: 12),

          // Download button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Material(
              color: colors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => _startDownload(
                  mapBounds,
                  currentZoom,
                  maxZoom,
                ),
                borderRadius: BorderRadius.circular(6),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, size: 18, color: colors.accent),
                      const SizedBox(width: 8),
                      Text(
                        'DOWNLOAD',
                        style: TacticalTextStyles.buttonText(colors).copyWith(
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Download progress (active download)
  // ---------------------------------------------------------------------------

  Widget _buildDownloadProgress(TacticalColorScheme colors) {
    final progress = _downloadProgress ?? 0.0;
    final percent = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.accent),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DOWNLOADING: ${_nameController.text.toUpperCase()}',
                  style: TacticalTextStyles.label(colors).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.card2,
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
          const SizedBox(height: 8),

          // Progress text
          Text(
            '$percent% complete',
            style: TacticalTextStyles.caption(colors),
          ),
          const SizedBox(height: 12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Material(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: _cancelDownload,
                borderRadius: BorderRadius.circular(6),
                child: Center(
                  child: Text(
                    'CANCEL',
                    style: TacticalTextStyles.buttonText(colors).copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Download logic
  // ---------------------------------------------------------------------------

  Future<void> _startDownload(
    MapBounds bounds,
    int minZoom,
    int maxZoom,
  ) async {
    // Check entitlement
    final entitlementName = ref.read(entitlementProvider);
    final entitlement = Entitlement.values.firstWhere(
      (e) => e.name == entitlementName,
      orElse: () => Entitlement.free,
    );

    // Free tier: check region count limit
    if (!entitlement.allMapRegions) {
      final existing = await ref.read(tileManagerProvider).getDownloadedRegions();
      if (existing.isNotEmpty) {
        if (!mounted) return;
        showPaywallSheet(context, featureName: 'Unlimited Offline Maps');
        return;
      }
    }

    final regionName = _nameController.text.trim();
    if (regionName.isEmpty) {
      setState(() => _errorMessage = 'Please enter a region name.');
      return;
    }

    // Create region model
    final regionId = DateTime.now().millisecondsSinceEpoch.toString();
    final region = MapRegion(
      id: regionId,
      name: regionName,
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );

    // Create region in database BEFORE starting download so
    // markAsDownloaded() has a row to update.
    final tileManager = ref.read(tileManagerProvider);
    await tileManager.createRegion(region);

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
    });

    tapMedium();

    try {
      _downloadSub = tileManager.downloadRegion(region).listen(
        (progress) {
          if (mounted) {
            setState(() => _downloadProgress = progress);
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _downloadProgress = null;
            });
            // Refresh the downloaded regions list
            ref.invalidate(downloadedRegionsProvider);
            tapMedium();
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _downloadProgress = null;
              _errorMessage = 'Download failed: $error';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = null;
          _errorMessage = 'Download failed: $e';
        });
      }
    }
  }

  Future<void> _cancelDownload() async {
    tapMedium();
    await ref.read(tileManagerProvider).cancelDownload();
    _downloadSub?.cancel();
    _downloadSub = null;

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = null;
      });
    }
  }

  Future<void> _deleteRegion(String regionId) async {
    tapLight();
    final tileManager = ref.read(tileManagerProvider);
    await tileManager.deleteRegion(regionId);
    ref.invalidate(downloadedRegionsProvider);
  }

  String _formatTileCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// ---------------------------------------------------------------------------
// Info row helper
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TacticalTextStyles.caption(colors)),
        Text(
          value,
          style: TacticalTextStyles.caption(colors).copyWith(
            color: colors.text2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Region tile (downloaded region list item)
// ---------------------------------------------------------------------------

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.region,
    required this.colors,
    required this.onDelete,
  });

  final MapRegion region;
  final TacticalColorScheme colors;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final sizeMb = region.sizeBytes != null
        ? (region.sizeBytes! / (1024 * 1024)).toStringAsFixed(1)
        : '?';

    final downloadDate = region.downloadedAt != null
        ? '${region.downloadedAt!.month}/${region.downloadedAt!.day}/${region.downloadedAt!.year}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border2),
        ),
        child: Row(
          children: [
            Icon(Icons.map, size: 20, color: colors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.name.toUpperCase(),
                    style: TacticalTextStyles.body(colors),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$sizeMb MB  •  Z${region.minZoom}-${region.maxZoom}  •  $downloadDate',
                    style: TacticalTextStyles.dim(colors),
                  ),
                ],
              ),
            ),
            // Delete button
            SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _confirmDelete(context),
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colors.text3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bg,
        title: Text(
          'DELETE REGION',
          style: TacticalTextStyles.subheading(colors),
        ),
        content: Text(
          'Delete "${region.name}" and remove cached tiles?',
          style: TacticalTextStyles.body(colors),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: TacticalTextStyles.caption(colors).copyWith(
                color: colors.text3,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: Text(
              'DELETE',
              style: TacticalTextStyles.caption(colors).copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

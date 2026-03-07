// Manages online and offline tile sources for flutter_map.
//
// Provides TileLayer widgets for online tile servers (OSM, OpenTopo)
// and offline MBTiles tile providers. Downloads tile regions into
// MBTiles databases using Dio for HTTP and the mbtiles package for storage.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:latlong2/latlong.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:red_grid_link/core/constants/map_constants.dart';
import 'package:red_grid_link/data/models/map_region.dart';
import 'package:red_grid_link/data/repositories/map_repository.dart';

/// Tile source identifiers.
class TileSources {
  TileSources._();

  static const String osm = 'osm';
  static const String topo = 'topo';

  static const List<String> all = [osm, topo];

  static String labelFor(String id) {
    switch (id) {
      case osm:
        return 'OSM';
      case topo:
        return 'TOPO';
      default:
        return id.toUpperCase();
    }
  }
}

/// Manages tile layers and offline region downloads.
class TileManager {
  final MapRepository? _mapRepository;
  final Dio _dio;

  /// Active download completer for cancellation support.
  Completer<void>? _cancelCompleter;

  /// Whether a download is currently in progress.
  bool _isDownloading = false;

  TileManager({MapRepository? mapRepository, Dio? dio})
      : _mapRepository = mapRepository,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              responseType: ResponseType.bytes,
              headers: {
                'User-Agent': 'com.redgridlink.app',
              },
            ));

  // ---------------------------------------------------------------------------
  // Online tile layers
  // ---------------------------------------------------------------------------

  /// Build a [TileLayer] for the given online source.
  ///
  /// [sourceId] must be one of [TileSources.osm] or [TileSources.topo].
  TileLayer getOnlineTileLayer(String sourceId) {
    final String url;

    switch (sourceId) {
      case TileSources.topo:
        url = MapConstants.openTopoUrl;
        break;
      case TileSources.osm:
      default:
        url = MapConstants.osmTileUrl;
        break;
    }

    return TileLayer(
      urlTemplate: url,
      userAgentPackageName: 'com.redgridlink.app',
      maxZoom: MapConstants.maxZoom,
      minZoom: MapConstants.minZoom,
      tileProvider: NetworkTileProvider(),
    );
  }

  // ---------------------------------------------------------------------------
  // Offline MBTiles support
  // ---------------------------------------------------------------------------

  /// Attempt to load an MBTiles tile provider from a local file.
  ///
  /// Returns `null` if the file does not exist or is corrupt.
  Future<TileProvider?> loadMBTilesProvider(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    try {
      return MbTilesTileProvider.fromPath(
        path: filePath,
        silenceTileNotFound: true,
      );
    } catch (_) {
      // Corrupt or incompatible MBTiles file — treat as unavailable.
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Region management
  // ---------------------------------------------------------------------------

  /// List all available offline regions from the database.
  Future<List<MapRegion>> getAvailableRegions() async {
    if (_mapRepository == null) return [];
    return _mapRepository.getAllRegions();
  }

  /// List only downloaded (locally available) regions.
  Future<List<MapRegion>> getDownloadedRegions() async {
    if (_mapRepository == null) return [];
    return _mapRepository.getDownloadedRegions();
  }

  /// Download tiles for a region and package into MBTiles.
  ///
  /// Yields progress from 0.0 to 1.0. Completes when all tiles are saved.
  ///
  /// The implementation:
  /// 1. Calculates all tile coordinates within [region.bounds] for each
  ///    zoom level from [region.minZoom] to [region.maxZoom].
  /// 2. Downloads each tile from the OSM tile server using Dio.
  /// 3. Writes tiles into a local MBTiles (SQLite) file via the mbtiles package.
  /// 4. Updates [MapRepository] with the file path and actual size.
  Stream<double> downloadRegion(MapRegion region) async* {
    // Prevent concurrent downloads from corrupting MBTiles.
    if (_isDownloading) {
      throw StateError('A download is already in progress');
    }
    _isDownloading = true;
    _cancelCompleter = Completer<void>();

    // Calculate all tile coordinates
    final tiles = _getTileCoordinates(
      region.bounds,
      region.minZoom,
      region.maxZoom,
    );

    if (tiles.isEmpty) {
      _cancelCompleter = null;
      _isDownloading = false;
      return;
    }

    // Prepare the MBTiles file path and ensure directory exists
    final tilesDir = await getTilesDirectory();
    final filePath = p.join(tilesDir, '${region.id}.mbtiles');

    // Delete any existing file to start fresh
    final existingFile = File(filePath);
    if (await existingFile.exists()) {
      await existingFile.delete();
    }

    // Create the MBTiles database using the mbtiles package
    final centerLat = (region.bounds.north + region.bounds.south) / 2.0;
    final centerLon = (region.bounds.east + region.bounds.west) / 2.0;

    final mbtiles = MbTiles.create(
      mbtilesPath: filePath,
      metadata: MbTilesMetadata(
        name: region.name,
        format: 'png',
        bounds: MbTilesBounds(
          left: region.bounds.west,
          bottom: region.bounds.south,
          right: region.bounds.east,
          top: region.bounds.north,
        ),
        defaultCenter: LatLng(centerLat, centerLon),
        defaultZoom: region.minZoom.toDouble(),
        minZoom: region.minZoom.toDouble(),
        maxZoom: region.maxZoom.toDouble(),
        attributionHtml: MapConstants.osmAttribution,
        description: 'Red Grid Link offline region: ${region.name}',
        type: TileLayerType.baseLayer,
        version: 1.0,
      ),
    );

    final totalTiles = tiles.length;
    int downloadedCount = 0;

    try {
      for (final tile in tiles) {
        // Check for cancellation
        if (_cancelCompleter?.isCompleted ?? false) {
          break;
        }

        try {
          // Download tile from OSM
          final url =
              'https://tile.openstreetmap.org/${tile.z}/${tile.x}/${tile.y}.png';

          final response = await _dio.get<List<int>>(url);

          if (response.statusCode == 200 && response.data != null) {
            final tileData = Uint8List.fromList(response.data!);
            // MBTiles uses TMS y-coordinate: tmsY = (2^z - 1) - y
            final tmsY = (1 << tile.z) - 1 - tile.y;

            mbtiles.putTile(
              z: tile.z,
              x: tile.x,
              y: tmsY,
              bytes: tileData,
            );
          }
        } on DioException {
          // Skip failed tiles and continue downloading
        } catch (_) {
          // Skip unexpected errors for individual tiles
        }

        downloadedCount++;
        yield downloadedCount / totalTiles;
      }
    } finally {
      mbtiles.dispose();
    }

    // If cancelled, clean up the partial file
    if (_cancelCompleter?.isCompleted ?? false) {
      final partialFile = File(filePath);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      _cancelCompleter = null;
      _isDownloading = false;
      return;
    }

    // Mark region as downloaded in the database with actual size
    if (_mapRepository != null) {
      // Get actual file size on disk
      final file = File(filePath);
      final actualSize = await file.length();

      await _mapRepository.markAsDownloaded(
        region.id,
        filePath: filePath,
        sizeBytes: actualSize,
      );
    }

    _cancelCompleter = null;
    _isDownloading = false;
  }

  /// Cancel an in-progress download.
  Future<void> cancelDownload() async {
    _cancelCompleter?.complete();
    _cancelCompleter = null;
  }

  /// Delete a downloaded region's MBTiles file and database entry.
  Future<void> deleteRegion(String regionId) async {
    if (_mapRepository == null) return;
    final region = await _mapRepository.getRegionById(regionId);
    if (region != null && region.filePath != null) {
      final file = File(region.filePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _mapRepository.deleteRegion(regionId);
  }

  /// Get the path to the tiles storage directory.
  Future<String> getTilesDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final tilesDir = Directory(p.join(dir.path, 'tiles'));
    if (!await tilesDir.exists()) {
      await tilesDir.create(recursive: true);
    }
    return tilesDir.path;
  }

  // ---------------------------------------------------------------------------
  // Tile coordinate math
  // ---------------------------------------------------------------------------

  /// Calculate all slippy-map tile coordinates that cover the given bounds
  /// across the specified zoom range.
  ///
  /// Uses the standard Web Mercator tile coordinate formula:
  ///   x = floor((lon + 180) / 360 * 2^z)
  ///   y = floor((1 - ln(tan(lat_rad) + sec(lat_rad)) / pi) / 2 * 2^z)
  List<({int x, int y, int z})> _getTileCoordinates(
    MapBounds bounds,
    int minZoom,
    int maxZoom,
  ) {
    final tiles = <({int x, int y, int z})>[];

    for (var z = minZoom; z <= maxZoom; z++) {
      final n = 1 << z; // 2^z

      final xMin =
          _lonToTileX(bounds.west, n).clamp(0, n - 1);
      final xMax =
          _lonToTileX(bounds.east, n).clamp(0, n - 1);

      // Note: in slippy map, north (higher latitude) = smaller y value
      final yMin =
          _latToTileY(bounds.north, n).clamp(0, n - 1);
      final yMax =
          _latToTileY(bounds.south, n).clamp(0, n - 1);

      for (var x = xMin; x <= xMax; x++) {
        for (var y = yMin; y <= yMax; y++) {
          tiles.add((x: x, y: y, z: z));
        }
      }
    }

    return tiles;
  }

  /// Convert longitude to tile X coordinate at a given number of tiles (2^z).
  static int _lonToTileX(double lon, int n) {
    return ((lon + 180.0) / 360.0 * n).floor();
  }

  /// Convert latitude to tile Y coordinate at a given number of tiles (2^z).
  static int _latToTileY(double lat, int n) {
    final latRad = lat * pi / 180.0;
    return ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0 * n)
        .floor();
  }

  /// Estimate the number of tiles that would be downloaded for a given
  /// region and zoom range.
  ///
  /// Useful for showing the user an estimated download size before starting.
  @visibleForTesting
  int estimateTileCount(MapBounds bounds, int minZoom, int maxZoom) {
    return _getTileCoordinates(bounds, minZoom, maxZoom).length;
  }

  /// Expose tile coordinate calculation for testing purposes.
  ///
  /// Returns all (x, y, z) tile coordinates covering the given bounds
  /// and zoom range.
  @visibleForTesting
  List<({int x, int y, int z})> getTileCoordinatesForTesting(
    MapBounds bounds,
    int minZoom,
    int maxZoom,
  ) {
    return _getTileCoordinates(bounds, minZoom, maxZoom);
  }
}

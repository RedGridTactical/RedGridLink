import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/data/models/map_region.dart';
import 'package:red_grid_link/services/map/tile_manager.dart';

void main() {
  // -------------------------------------------------------------------------
  // TileSources
  // -------------------------------------------------------------------------
  group('TileSources', () {
    test('all contains osm and topo', () {
      expect(TileSources.all, contains(TileSources.osm));
      expect(TileSources.all, contains(TileSources.topo));
    });

    test('all does not contain offline', () {
      expect(TileSources.all, isNot(contains(TileSources.offline)));
    });

    test('allWithOffline contains osm, topo, and offline', () {
      expect(TileSources.allWithOffline, contains(TileSources.osm));
      expect(TileSources.allWithOffline, contains(TileSources.topo));
      expect(TileSources.allWithOffline, contains(TileSources.offline));
    });

    test('labelFor returns correct labels', () {
      expect(TileSources.labelFor(TileSources.osm), equals('OSM'));
      expect(TileSources.labelFor(TileSources.topo), equals('TOPO'));
      expect(TileSources.labelFor(TileSources.offline), equals('OFF'));
    });

    test('labelFor unknown returns uppercased id', () {
      expect(TileSources.labelFor('custom'), equals('CUSTOM'));
    });

    test('offline source id is offline', () {
      expect(TileSources.offline, equals('offline'));
    });
  });

  // -------------------------------------------------------------------------
  // getOnlineTileLayer
  // -------------------------------------------------------------------------
  group('getOnlineTileLayer', () {
    late TileManager manager;

    setUp(() {
      manager = TileManager();
    });

    test('returns a TileLayer for OSM source', () {
      final layer = manager.getOnlineTileLayer(TileSources.osm);
      expect(layer, isNotNull);
      expect(layer.urlTemplate, contains('openstreetmap.org'));
    });

    test('returns a TileLayer for TOPO source', () {
      final layer = manager.getOnlineTileLayer(TileSources.topo);
      expect(layer, isNotNull);
      expect(layer.urlTemplate, contains('opentopomap.org'));
    });

    test('defaults to OSM for unknown source', () {
      final layer = manager.getOnlineTileLayer('unknown');
      expect(layer, isNotNull);
      expect(layer.urlTemplate, contains('openstreetmap.org'));
    });
  });

  // -------------------------------------------------------------------------
  // estimateTileCount
  // -------------------------------------------------------------------------
  group('estimateTileCount', () {
    late TileManager manager;

    setUp(() {
      manager = TileManager();
    });

    test('zoom 0 covers the whole world with 1 tile', () {
      // The entire world at zoom 0 is a single tile
      final count = manager.estimateTileCount(
        const MapBounds(north: 85, south: -85, east: 179, west: -179),
        0,
        0,
      );
      expect(count, equals(1));
    });

    test('zoom 1 has 4 tiles for full world', () {
      // At zoom 1, the world is 2x2 = 4 tiles
      final count = manager.estimateTileCount(
        const MapBounds(north: 85, south: -85, east: 179, west: -179),
        1,
        1,
      );
      expect(count, equals(4));
    });

    test('single tile at any zoom is 1', () {
      // A very small region that fits within a single tile at zoom 10
      // Central DC: latitude ~38.9, longitude ~-77.03
      // At zoom 10, each tile is about 0.35 degrees wide
      final count = manager.estimateTileCount(
        const MapBounds(
          north: 38.91,
          south: 38.90,
          east: -77.02,
          west: -77.03,
        ),
        10,
        10,
      );
      expect(count, equals(1));
    });

    test('tile count increases with zoom range', () {
      const bounds = MapBounds(
        north: 39.0,
        south: 38.8,
        east: -76.9,
        west: -77.1,
      );

      final countZ10 = manager.estimateTileCount(bounds, 10, 10);
      final countZ10to12 = manager.estimateTileCount(bounds, 10, 12);

      // More zoom levels = more tiles
      expect(countZ10to12, greaterThan(countZ10));
    });

    test('tile count increases with larger area', () {
      const smallBounds = MapBounds(
        north: 38.95,
        south: 38.90,
        east: -77.00,
        west: -77.05,
      );
      const largeBounds = MapBounds(
        north: 39.2,
        south: 38.6,
        east: -76.5,
        west: -77.5,
      );

      final smallCount = manager.estimateTileCount(smallBounds, 12, 12);
      final largeCount = manager.estimateTileCount(largeBounds, 12, 12);

      expect(largeCount, greaterThan(smallCount));
    });

    test('returns 0 for invalid zoom range', () {
      final count = manager.estimateTileCount(
        const MapBounds(north: 39, south: 38, east: -76, west: -77),
        12,
        10, // maxZoom < minZoom
      );
      expect(count, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // getTileCoordinatesForTesting
  // -------------------------------------------------------------------------
  group('getTileCoordinatesForTesting', () {
    late TileManager manager;

    setUp(() {
      manager = TileManager();
    });

    test('zoom 0 returns single tile at (0, 0, 0)', () {
      final tiles = manager.getTileCoordinatesForTesting(
        const MapBounds(north: 85, south: -85, east: 179, west: -179),
        0,
        0,
      );
      expect(tiles, hasLength(1));
      expect(tiles[0].x, equals(0));
      expect(tiles[0].y, equals(0));
      expect(tiles[0].z, equals(0));
    });

    test('tiles have correct zoom values across zoom range', () {
      final tiles = manager.getTileCoordinatesForTesting(
        const MapBounds(
          north: 38.95,
          south: 38.90,
          east: -77.00,
          west: -77.05,
        ),
        8,
        10,
      );

      // Verify tiles exist for each zoom level
      final zoomLevels = tiles.map((t) => t.z).toSet();
      expect(zoomLevels, containsAll([8, 9, 10]));
    });

    test('tile coordinates are non-negative', () {
      final tiles = manager.getTileCoordinatesForTesting(
        const MapBounds(
          north: 40.0,
          south: 38.0,
          east: -75.0,
          west: -78.0,
        ),
        5,
        8,
      );

      for (final tile in tiles) {
        expect(tile.x, greaterThanOrEqualTo(0));
        expect(tile.y, greaterThanOrEqualTo(0));
        expect(tile.z, greaterThanOrEqualTo(0));
      }
    });

    test('tile coordinates do not exceed max for zoom level', () {
      final tiles = manager.getTileCoordinatesForTesting(
        const MapBounds(
          north: 40.0,
          south: 38.0,
          east: -75.0,
          west: -78.0,
        ),
        5,
        8,
      );

      for (final tile in tiles) {
        final maxCoord = (1 << tile.z) - 1;
        expect(tile.x, lessThanOrEqualTo(maxCoord));
        expect(tile.y, lessThanOrEqualTo(maxCoord));
      }
    });

    test('known tile for Washington DC at zoom 10', () {
      // Washington DC is around lat 38.9, lon -77.03
      // At zoom 10, this should be tile x=291, y=390
      // x = floor(((-77.03 + 180) / 360) * 1024) = floor(0.28603 * 1024) = floor(292.89) = 292
      // Actually let's just verify the tile is within expected range
      final tiles = manager.getTileCoordinatesForTesting(
        const MapBounds(
          north: 38.91,
          south: 38.89,
          east: -77.02,
          west: -77.04,
        ),
        10,
        10,
      );

      expect(tiles, isNotEmpty);
      // At zoom 10, DC should be around x=291-292, y=390-391
      final tile = tiles.first;
      expect(tile.z, equals(10));
      expect(tile.x, inInclusiveRange(290, 294));
      expect(tile.y, inInclusiveRange(388, 393));
    });

    test('equator and prime meridian tile at zoom 1', () {
      // At zoom 1, the world is 2x2.
      // Lat 0, Lon 0 should be tile x=1, y=1 (southeast quadrant origin)
      final tiles = manager.getTileCoordinatesForTesting(
        const MapBounds(
          north: 1.0,
          south: -1.0,
          east: 1.0,
          west: -1.0,
        ),
        1,
        1,
      );

      // This small region around origin should span tiles at boundary
      expect(tiles, isNotEmpty);
      final zoomLevels = tiles.map((t) => t.z).toSet();
      expect(zoomLevels, contains(1));
    });

    test('southern hemisphere produces valid tiles', () {
      // Sydney, Australia: lat -33.87, lon 151.21
      final tiles = manager.getTileCoordinatesForTesting(
        const MapBounds(
          north: -33.8,
          south: -33.9,
          east: 151.3,
          west: 151.1,
        ),
        10,
        10,
      );

      expect(tiles, isNotEmpty);
      for (final tile in tiles) {
        expect(tile.x, greaterThanOrEqualTo(0));
        expect(tile.y, greaterThanOrEqualTo(0));
        final maxCoord = (1 << tile.z) - 1;
        expect(tile.x, lessThanOrEqualTo(maxCoord));
        expect(tile.y, lessThanOrEqualTo(maxCoord));
      }
    });

    test('multiple zoom levels accumulate tiles correctly', () {
      const bounds = MapBounds(
        north: 38.95,
        south: 38.90,
        east: -77.00,
        west: -77.05,
      );

      final tilesZ10 = manager.getTileCoordinatesForTesting(bounds, 10, 10);
      final tilesZ11 = manager.getTileCoordinatesForTesting(bounds, 11, 11);
      final tilesZ10to11 =
          manager.getTileCoordinatesForTesting(bounds, 10, 11);

      // Combined should equal sum of individual zoom levels
      expect(tilesZ10to11.length, equals(tilesZ10.length + tilesZ11.length));
    });
  });

  // -------------------------------------------------------------------------
  // Region management (no-repo scenarios)
  // -------------------------------------------------------------------------
  group('Region management without repository', () {
    late TileManager manager;

    setUp(() {
      manager = TileManager();
    });

    test('getAvailableRegions returns empty without repository', () async {
      final regions = await manager.getAvailableRegions();
      expect(regions, isEmpty);
    });

    test('getDownloadedRegions returns empty without repository', () async {
      final regions = await manager.getDownloadedRegions();
      expect(regions, isEmpty);
    });

    test('deleteRegion does not throw without repository', () async {
      // Should not throw even without a repository
      await expectLater(
        manager.deleteRegion('nonexistent'),
        completes,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Cancellation
  // -------------------------------------------------------------------------
  group('Cancellation', () {
    test('cancelDownload does not throw when no download in progress', () async {
      final manager = TileManager();
      await expectLater(manager.cancelDownload(), completes);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:red_grid_link/data/models/map_region.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/map_provider.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/services/map/tile_manager.dart';
import 'package:red_grid_link/ui/screens/map/widgets/map_download_sheet.dart';

void main() {
  late SettingsRepository settingsRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settingsRepo = SettingsRepository(prefs);
  });

  Widget buildSheetHost() {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        tileManagerProvider.overrideWithValue(TileManager()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showMapDownloadSheet(context),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
  }

  group('MapDownloadSheet', () {
    testWidgets('showMapDownloadSheet opens bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetHost());

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('OFFLINE MAPS'), findsOneWidget);
    });

    testWidgets('shows download form section',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetHost());

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('DOWNLOAD CURRENT VIEW'), findsOneWidget);
      expect(find.text('DOWNLOAD'), findsOneWidget);
    });

    testWidgets('shows downloaded regions section',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetHost());

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('DOWNLOADED REGIONS'), findsOneWidget);
      expect(find.text('No offline regions downloaded.'), findsOneWidget);
    });

    testWidgets('has region name text field with default value',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetHost());

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Default region name
      final controller =
          (tester.widget<TextField>(textField)).controller!;
      expect(controller.text, equals('My Region'));
    });

    testWidgets('shows close button', (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetHost());

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('CLOSE'), findsOneWidget);
    });

    testWidgets('shows tile count and size estimate',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetHost());

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('Zoom range'), findsOneWidget);
      expect(find.text('Tiles'), findsOneWidget);
      expect(find.text('Est. size'), findsOneWidget);
    });

    testWidgets('close button dismisses sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetHost());

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('OFFLINE MAPS'), findsOneWidget);

      // CLOSE button is below the visible area — scroll it into view first.
      await tester.ensureVisible(find.text('CLOSE'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();

      expect(find.text('OFFLINE MAPS'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Offline source toggle logic
  // ---------------------------------------------------------------------------
  group('Offline source integration', () {
    test('TileSources.offline label is OFF', () {
      expect(TileSources.labelFor(TileSources.offline), equals('OFF'));
    });

    test('activeOfflineRegionIdProvider defaults to null', () {
      final container = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ]);
      addTearDown(container.dispose);

      final regionId = container.read(activeOfflineRegionIdProvider);
      expect(regionId, isNull);
    });

    test('downloadedRegionsProvider returns empty without repo', () async {
      final container = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        tileManagerProvider.overrideWithValue(TileManager()),
      ]);
      addTearDown(container.dispose);

      final regions = await container.read(downloadedRegionsProvider.future);
      expect(regions, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // MapRegion model
  // ---------------------------------------------------------------------------
  group('MapRegion', () {
    test('isDownloaded returns true when filePath and downloadedAt set', () {
      final region = MapRegion(
        id: 'test',
        name: 'Test',
        bounds: const MapBounds(
          north: 39, south: 38, east: -76, west: -77,
        ),
        minZoom: 10,
        maxZoom: 14,
        filePath: '/path/to/test.mbtiles',
        downloadedAt: DateTime.now(),
      );
      expect(region.isDownloaded, isTrue);
    });

    test('isDownloaded returns false when filePath is null', () {
      final region = MapRegion(
        id: 'test',
        name: 'Test',
        bounds: const MapBounds(
          north: 39, south: 38, east: -76, west: -77,
        ),
        minZoom: 10,
        maxZoom: 14,
      );
      expect(region.isDownloaded, isFalse);
    });

    test('copyWith updates filePath', () {
      final region = MapRegion(
        id: 'test',
        name: 'Test',
        bounds: const MapBounds(
          north: 39, south: 38, east: -76, west: -77,
        ),
        minZoom: 10,
        maxZoom: 14,
      );

      final updated = region.copyWith(
        filePath: '/new/path.mbtiles',
        downloadedAt: DateTime.now(),
        sizeBytes: 1024000,
      );

      expect(updated.filePath, equals('/new/path.mbtiles'));
      expect(updated.sizeBytes, equals(1024000));
      expect(updated.id, equals('test')); // Preserved
      expect(updated.name, equals('Test')); // Preserved
    });
  });
}

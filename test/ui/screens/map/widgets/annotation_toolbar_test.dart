import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/data/models/annotation.dart';
import 'package:red_grid_link/data/models/marker.dart' as model;
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/map_provider.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/services/field_link/field_link_service.dart';
import 'package:red_grid_link/services/field_link/role_manager.dart';
import 'package:red_grid_link/ui/screens/map/widgets/annotation_toolbar.dart';

/// Minimal stub of FieldLinkService for testing.
class _FakeFieldLinkService implements FieldLinkService {
  final List<model.Marker> addedMarkers = [];
  final List<Annotation> addedAnnotations = [];

  @override
  String get localDeviceId => 'test-device-id';

  @override
  void addMarker(model.Marker marker) {
    addedMarkers.add(marker);
  }

  @override
  void addAnnotation(Annotation annotation) {
    addedAnnotations.add(annotation);
  }

  @override
  RoleManager get roleManager =>
      RoleManager(localDeviceId: 'test-device-id');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The red-light theme (default free theme) for testing.
const _testColors = TacticalColorScheme(
  id: 'red',
  label: 'RED LIGHT',
  sub: 'Default tactical display',
  pro: false,
  bg: Color(0xFF0A0000),
  text: Color(0xFFBB0000),
  text2: Color(0xFF880000),
  text3: Color(0xFF660000),
  text4: Color(0xFF440000),
  text5: Color(0xFF220000),
  accent: Color(0xFFBB0000),
  card: Color(0xFF100000),
  card2: Color(0xFF140000),
  border: Color(0xFF330000),
  border2: Color(0xFF220000),
);

void main() {
  late SettingsRepository settingsRepo;
  late _FakeFieldLinkService fakeService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settingsRepo = SettingsRepository(prefs);
    fakeService = _FakeFieldLinkService();
  });

  /// Build the toolbar in a test harness with optional provider overrides.
  Widget buildToolbar({
    DrawingMode drawingMode = DrawingMode.none,
    List<LatLng> drawingPoints = const [],
    int colorIndex = 0,
  }) {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        fieldLinkServiceProvider.overrideWithValue(fakeService),
        drawingModeProvider.overrideWith((ref) => drawingMode),
        drawingPointsProvider.overrideWith((ref) => drawingPoints),
        drawingColorIndexProvider.overrideWith((ref) => colorIndex),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: AnnotationToolbar(colors: _testColors),
        ),
      ),
    );
  }

  group('Color picker', () {
    testWidgets('has 6 color swatches including white', (tester) async {
      await tester.pumpWidget(buildToolbar());

      // The color picker renders one Container per color in annotationColors.
      // annotationColors should have 6 entries.
      expect(annotationColors.length, 6);

      // Verify white (0xFFFFFFFF) is in the list.
      expect(
        annotationColors.contains(const Color(0xFFFFFFFF)),
        isTrue,
        reason: 'White should be in the annotation color palette',
      );
    });

    testWidgets('renders all 6 color circles', (tester) async {
      await tester.pumpWidget(buildToolbar());

      // Each color swatch is a Container with BoxDecoration inside the
      // color picker. Count the colored circles by looking for Containers
      // with a circle shape that use annotation colors.
      // The color picker renders annotationColors.length items.
      // We can find GestureDetector widgets inside the color picker area.
      // Simple: look for containers with BoxShape.circle inside the toolbar.
      // The tool buttons also have containers, so let's count by the
      // number of annotation color values present.
      for (final color in annotationColors) {
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).shape == BoxShape.circle &&
                (w.decoration as BoxDecoration).color == color,
          ),
          findsOneWidget,
          reason: 'Should find a circle for color ${color.toARGB32().toRadixString(16)}',
        );
      }
    });
  });

  group('Undo button', () {
    testWidgets('appears during drawing mode', (tester) async {
      await tester.pumpWidget(buildToolbar(
        drawingMode: DrawingMode.polyline,
      ));

      expect(find.byIcon(Icons.undo), findsOneWidget);
    });

    testWidgets('does not appear when not drawing', (tester) async {
      await tester.pumpWidget(buildToolbar(
        drawingMode: DrawingMode.none,
      ));

      expect(find.byIcon(Icons.undo), findsNothing);
    });

    testWidgets('is present but visually dimmed when no points', (tester) async {
      await tester.pumpWidget(buildToolbar(
        drawingMode: DrawingMode.polyline,
        drawingPoints: [],
      ));

      // Undo icon should be present.
      expect(find.byIcon(Icons.undo), findsOneWidget);

      // The undo button should have reduced opacity (isDisabled = true).
      final opacityWidget = find.ancestor(
        of: find.byIcon(Icons.undo),
        matching: find.byType(Opacity),
      );
      expect(opacityWidget, findsOneWidget);

      final opacity = tester.widget<Opacity>(opacityWidget);
      expect(opacity.opacity, 0.35,
          reason: 'Undo button should be dimmed when no drawing points');
    });

    testWidgets('removes last point from provider on tap', (tester) async {
      final points = [
        const LatLng(39.0, -105.0),
        const LatLng(39.1, -105.1),
        const LatLng(39.2, -105.2),
      ];

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(settingsRepo),
            fieldLinkServiceProvider.overrideWithValue(fakeService),
            drawingModeProvider.overrideWith((ref) => DrawingMode.polyline),
            drawingPointsProvider.overrideWith((ref) => List.from(points)),
            drawingColorIndexProvider.overrideWith((ref) => 0),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              // Capture the container reference.
              return const MaterialApp(
                home: Scaffold(
                  body: AnnotationToolbar(colors: _testColors),
                ),
              );
            },
          ),
        ),
      );

      // Get the container from the element tree.
      final element = tester.element(find.byType(AnnotationToolbar));
      container = ProviderScope.containerOf(element);

      // Verify initial state.
      expect(container.read(drawingPointsProvider).length, 3);

      // Tap undo.
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();

      // One point should be removed.
      expect(container.read(drawingPointsProvider).length, 2);

      // Tap undo again.
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(container.read(drawingPointsProvider).length, 1);
    });
  });

  group('Done and Cancel buttons', () {
    testWidgets('Done button appears when >= 2 points in drawing mode',
        (tester) async {
      await tester.pumpWidget(buildToolbar(
        drawingMode: DrawingMode.polyline,
        drawingPoints: [
          const LatLng(39.0, -105.0),
          const LatLng(39.1, -105.1),
        ],
      ));

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Done button hidden when < 2 points', (tester) async {
      await tester.pumpWidget(buildToolbar(
        drawingMode: DrawingMode.polyline,
        drawingPoints: [const LatLng(39.0, -105.0)],
      ));

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('Cancel button appears during drawing mode', (tester) async {
      await tester.pumpWidget(buildToolbar(
        drawingMode: DrawingMode.polyline,
      ));

      expect(find.text('CANCEL'), findsOneWidget);
    });

    testWidgets('Close button appears when not drawing', (tester) async {
      await tester.pumpWidget(buildToolbar(
        drawingMode: DrawingMode.none,
      ));

      expect(find.text('CLOSE'), findsOneWidget);
    });
  });

  group('Tool buttons', () {
    testWidgets('LINE, AREA, MARK labels present', (tester) async {
      await tester.pumpWidget(buildToolbar());

      expect(find.text('LINE'), findsOneWidget);
      expect(find.text('AREA'), findsOneWidget);
      expect(find.text('MARK'), findsOneWidget);
    });

    testWidgets('drawing status shows point count', (tester) async {
      await tester.pumpWidget(buildToolbar(
        drawingMode: DrawingMode.polyline,
        drawingPoints: [
          const LatLng(39.0, -105.0),
          const LatLng(39.1, -105.1),
          const LatLng(39.2, -105.2),
        ],
      ));

      expect(find.text('3 pts'), findsOneWidget);
      expect(find.text('DRAWING LINE'), findsOneWidget);
    });
  });
}

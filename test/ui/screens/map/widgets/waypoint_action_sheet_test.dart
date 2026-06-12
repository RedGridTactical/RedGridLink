import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:red_grid_link/data/models/marker.dart' as model;
import 'package:red_grid_link/data/models/operational_mode.dart';
import 'package:red_grid_link/data/models/session.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/data/repositories/waypoint_repository.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/location_provider.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/services/field_link/field_link_service.dart';
import 'package:red_grid_link/services/field_link/role_manager.dart';
import 'package:red_grid_link/ui/screens/map/widgets/waypoint_action_sheet.dart';

/// Minimal stub of FieldLinkService for testing.
class _FakeFieldLinkService implements FieldLinkService {
  final List<model.Marker> addedMarkers = [];

  @override
  String get localDeviceId => 'test-device-id';

  @override
  void addMarker(model.Marker marker) {
    addedMarkers.add(marker);
  }

  @override
  RoleManager get roleManager =>
      RoleManager(localDeviceId: 'test-device-id');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SettingsRepository settingsRepo;
  late WaypointRepository waypointRepo;
  late _FakeFieldLinkService fakeService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settingsRepo = SettingsRepository(prefs);
    waypointRepo = WaypointRepository(prefs);
    fakeService = _FakeFieldLinkService();
  });

  /// Build the test host with a button that opens the waypoint action sheet.
  Widget buildHost({bool sessionActive = false}) {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        waypointRepositoryProvider.overrideWithValue(waypointRepo),
        fieldLinkServiceProvider.overrideWithValue(fakeService),
        activeSessionProvider.overrideWith((ref) => Stream.value(
              sessionActive
                  ? Session(
                      id: 'test-session',
                      name: 'Test',
                      createdAt: DateTime.now(),
                      operationalMode: OperationalMode.sar,
                      pin: '1234',
                    )
                  : null,
            )),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showWaypointActionSheet(
                context,
                lat: 38.897957,
                lon: -77.036560,
                mgrs: '18SUJ2337506519',
              ),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
  }

  group('WaypointActionSheet', () {
    testWidgets('shows MGRS coordinate', (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Should show formatted MGRS
      expect(find.textContaining('18S UJ'), findsOneWidget);
    });

    testWidgets('shows lat/lon', (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.textContaining('38.897957'), findsOneWidget);
      expect(find.textContaining('-77.036560'), findsOneWidget);
    });

    testWidgets('shows name input field', (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('WAYPOINT NAME'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows Save to My Waypoints button', (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('SAVE TO MY WAYPOINTS'), findsOneWidget);
    });

    testWidgets('shows Share with Team button when session is active',
        (tester) async {
      await tester.pumpWidget(buildHost(sessionActive: true));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('SHARE WITH TEAM'), findsOneWidget);
    });

    testWidgets('hides Share with Team button when no session',
        (tester) async {
      await tester.pumpWidget(buildHost(sessionActive: false));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('SHARE WITH TEAM'), findsNothing);
    });

    testWidgets('tapping save creates a local waypoint', (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Enter a waypoint name
      await tester.enterText(find.byType(TextField), 'Rally Point');
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.text('SAVE TO MY WAYPOINTS'));
      await tester.pumpAndSettle();

      // Verify waypoint was created in the repository
      final waypoints = waypointRepo.getAll();
      expect(waypoints, hasLength(1));
      expect(waypoints.first.name, 'Rally Point');
      expect(waypoints.first.lat, 38.897957);
      expect(waypoints.first.lon, -77.036560);
    });

    testWidgets('tapping share creates a shared marker', (tester) async {
      await tester.pumpWidget(buildHost(sessionActive: true));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Enter a waypoint name
      await tester.enterText(find.byType(TextField), 'Observation Post');
      await tester.pumpAndSettle();

      // Tap share
      await tester.tap(find.text('SHARE WITH TEAM'));
      await tester.pumpAndSettle();

      // Verify marker was shared via field link service
      expect(fakeService.addedMarkers, hasLength(1));
      expect(fakeService.addedMarkers.first.label, 'Observation Post');
      expect(
        fakeService.addedMarkers.first.origin,
        model.MarkerOrigin.sharedWaypoint,
      );
    });

    testWidgets('save button does nothing when name is empty',
        (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Don't enter a name, just tap save
      await tester.tap(find.text('SAVE TO MY WAYPOINTS'));
      await tester.pumpAndSettle();

      // Sheet should still be visible (not dismissed)
      expect(find.text('NEW WAYPOINT'), findsOneWidget);
      expect(waypointRepo.getAll(), isEmpty);
    });
  });
}

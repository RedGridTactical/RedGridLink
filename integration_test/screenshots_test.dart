// Screenshot capture test for Play Store / App Store marketing.
//
// Boots the app in demo mode with ALL required provider overrides
// (mirrors main.dart setup) and captures 8 PNGs matching composite-android.html.
//
// To run (Android emulator):
//   DEVICE_TARGET=raw_android/phone flutter drive \
//     --driver=integration_test/test_driver/screenshot_driver.dart \
//     --target=integration_test/screenshots_test.dart \
//     -d emulator-5554
//
// To run (iOS simulator):
//   DEVICE_TARGET=iphone_17_pro_max flutter drive \
//     --driver=integration_test/test_driver/screenshot_driver.dart \
//     --target=integration_test/screenshots_test.dart \
//     -d "<simulator name>"
//
// Screens captured (10):
//   01_map_team         Red theme — map with 4 peers, markers, boundary
//   02_grid_mgrs        NVG Green — GRID tab, live 10-digit MGRS
//   03_field_link       Blue Force — LINK tab, active session roster
//   04_tools            Day White — TOOLS grid (11 tools)
//   05_themes           Red theme — SETTINGS, theme selector visible
//   06_peer_popup       Red theme — MAP, VIPER peer popup open
//   07_dead_reckoning   NVG Green — Dead Reckoning tool
//   08_celestial        Blue Force — Celestial Navigation tool
//   09_search_area      Day White — MAP with annotation drawing toolbar open
//   10_roster           Day White — LINK tab with team roster sheet open
//
// Why pumpWidget instead of attachRootWidget:
//   pumpWidget() internally calls wrapWithDefaultView(widget) before
//   attachRootWidget(), which wraps the tree in a View that provides
//   MediaQuery, Semantics root, etc.  Skipping this step (calling
//   attachRootWidget directly) triggers "No MediaQuery ancestor" and
//   "Semantics cannot find ancestor render object" crashes.
//
// Why pumpWidget doesn't deadlock here:
//   In LiveTestWidgetsFlutterBinding (integration tests on real device),
//   the real engine's vsync loop fires normally — "Skipped N frames" in
//   logcat confirms frames ARE rendered.  pump() sets _expectingFrame=true,
//   schedules a frame, and handleDrawFrame() completes _pendingFrame within
//   one vsync cycle (~16ms).  No deadlock.
//
// Android screenshot sequence (documented):
//   1. convertFlutterSurfaceToImage() — converts FlutterSurfaceView to
//      FlutterImageView, which itself schedules one new frame.
//   2. pump()                         — waits for that frame (~16ms).
//   3. takeScreenshot()               — captures the rendered image.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:red_grid_link/app.dart';
import 'package:red_grid_link/core/utils/crypto_utils.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/repositories/annotation_repository.dart';
import 'package:red_grid_link/data/repositories/map_repository.dart';
import 'package:red_grid_link/data/repositories/marker_repository.dart';
import 'package:red_grid_link/data/repositories/peer_repository.dart';
import 'package:red_grid_link/data/repositories/session_repository.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/data/repositories/track_repository.dart';
import 'package:red_grid_link/data/repositories/waypoint_repository.dart';
import 'package:red_grid_link/providers/aar_provider.dart';
import 'package:red_grid_link/providers/field_link_provider.dart';
import 'package:red_grid_link/providers/location_provider.dart';
import 'package:red_grid_link/providers/map_provider.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/services/field_link/battery/battery_manager.dart';
import 'package:red_grid_link/services/field_link/field_link_service.dart';
import 'package:red_grid_link/services/field_link/ghost/ghost_manager.dart';
import 'package:red_grid_link/services/field_link/sync/sync_engine.dart';
import 'package:red_grid_link/services/field_link/transport/ble_transport.dart';
import 'package:red_grid_link/services/map/tile_manager.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Shared services (created once, reused across test cases) ──────────────

  late AppDatabase db;
  late TrackRepository trackRepo;
  late SessionRepository sessionRepo;
  late PeerRepository peerRepo;
  late MarkerRepository markerRepo;
  late AnnotationRepository annotationRepo;
  late WaypointRepository waypointRepo;
  late FieldLinkService fieldLinkService;
  late TileManager tileManager;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    db = constructDb();
    trackRepo = TrackRepository(db);
    sessionRepo = SessionRepository(db);
    peerRepo = PeerRepository(db);
    markerRepo = MarkerRepository(db);
    annotationRepo = AnnotationRepository(db);

    final prefs = await SharedPreferences.getInstance();
    waypointRepo = WaypointRepository(prefs);

    final deviceId = generateDeviceId();
    final transport = BleTransport();
    final syncEngine = SyncEngine(
      transport: transport,
      peerRepository: peerRepo,
      markerRepository: markerRepo,
      localDeviceId: deviceId,
    );
    fieldLinkService = FieldLinkService(
      transport: transport,
      syncEngine: syncEngine,
      ghostManager: GhostManager(),
      batteryManager: BatteryManager(),
      sessionRepository: sessionRepo,
      peerRepository: peerRepo,
      localDeviceId: deviceId,
    );
    tileManager = TileManager(mapRepository: MapRepository(db));
  });

  tearDownAll(() async {
    await db.close();
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Mounts the full app in demo mode with the given theme.
  ///
  /// Uses [pumpWidget] so that [wrapWithDefaultView] is applied internally,
  /// giving the widget tree a [View] root (required for MediaQuery, Semantics,
  /// and all Material widgets).  On a real device [pump()] completes within
  /// one vsync cycle since the engine's frame scheduler runs normally.
  Future<void> bootApp(
    WidgetTester tester, {
    String themeId = 'red',
    bool waitForTiles = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'settings_has_completed_onboarding': true,
      'settings_demo_mode': true,
      'settings_theme_id': themeId,
      'settings_operational_mode': 'sar',
      'settings_display_name': 'OVERWATCH',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          trackRepositoryProvider.overrideWithValue(trackRepo),
          sessionRepositoryProvider.overrideWithValue(sessionRepo),
          peerRepositoryProvider.overrideWithValue(peerRepo),
          markerRepositoryProvider.overrideWithValue(markerRepo),
          annotationRepositoryProvider.overrideWithValue(annotationRepo),
          fieldLinkServiceProvider.overrideWithValue(fieldLinkService),
          tileManagerProvider.overrideWithValue(tileManager),
          waypointRepositoryProvider.overrideWithValue(waypointRepo),
        ],
        child: const RedGridLinkApp(),
      ),
    );
    // Real-time wait: lets the device event loop render the full UI
    // (map tiles, animations, demo data seeding) without calling pump().
    //
    // Map-heavy screens (01, 06, 09) need significantly longer — OSM tiles
    // download over the network, and on the very first test the Dart VM
    // cold-start, first provider construction, first DB open, and first
    // network connection all happen inside this window.  25s gives the
    // full tile pipeline room to paint the visible viewport at zoom 15
    // before the screenshot is captured.
    await Future<void>.delayed(
      Duration(seconds: waitForTiles ? 25 : 5),
    );
  }

  /// Taps a bottom-nav tab by label and waits for the new screen to render.
  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  /// Captures a named screenshot via the integration_test binding.
  ///
  /// Android documented sequence:
  ///   1. convertFlutterSurfaceToImage() — schedules one new frame
  ///   2. pump()                         — waits for that frame (~16ms)
  ///   3. takeScreenshot()               — captures the image
  Future<void> capture(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot(name);
  }

  // ── Test cases ─────────────────────────────────────────────────────────────

  group('Play Store screenshots', () {
    // Warm-up run — NOT saved as a screenshot.  Absorbs the one-time
    // cold-start cost (Dart VM plugin init, first Drift connection, first
    // shared_preferences hit, first frame raster pipeline) that would
    // otherwise eat into 01_map_team's tile-load budget and leave the
    // viewport painted gray.  After this run, subsequent bootApp() calls
    // land on a warm VM and tiles render well within their time budget.
    testWidgets('00_warmup', (tester) async {
      await bootApp(tester, themeId: 'red', waitForTiles: true);
      // No capture — this run exists solely to warm the engine so that
      // 01_map_team renders with actual map tiles painted.
    });

    testWidgets('01_map_team', (tester) async {
      await bootApp(tester, themeId: 'red', waitForTiles: true);
      await capture(tester, '01_map_team');
    });

    testWidgets('02_grid_mgrs', (tester) async {
      await bootApp(tester, themeId: 'green');
      await tapTab(tester, 'GRID');
      await capture(tester, '02_grid_mgrs');
    });

    testWidgets('03_field_link', (tester) async {
      await bootApp(tester, themeId: 'blue');
      await tapTab(tester, 'LINK');
      await capture(tester, '03_field_link');
    });

    testWidgets('04_tools', (tester) async {
      await bootApp(tester, themeId: 'white');
      await tapTab(tester, 'TOOLS');
      await capture(tester, '04_tools');
    });

    testWidgets('05_themes', (tester) async {
      await bootApp(tester, themeId: 'red');
      await tapTab(tester, 'SETTINGS');
      await capture(tester, '05_themes');
    });

    testWidgets('06_peer_popup', (tester) async {
      await bootApp(tester, themeId: 'red', waitForTiles: true);
      // Pump one frame so the element tree reflects the latest vsync build
      // (stream providers have emitted, map markers are in the widget tree).
      await tester.pump();
      // Try to tap by widget text.  If flutter_map's viewport culling has
      // still removed the marker (e.g. layout not settled), fall back to
      // tapping the centre of the map — at zoom=15 all demo peers are
      // within a few hundred metres of map centre, so the topmost
      // GestureDetector there opens a popup for whichever peer is on top.
      final viperFinder = find.text('VIPER');
      if (viperFinder.evaluate().isNotEmpty) {
        await tester.tap(viperFinder.first);
      } else {
        // Approximate centre of the map body on a 1080-wide phone viewport.
        await tester.tapAt(const Offset(540, 1060));
      }
      await Future<void>.delayed(const Duration(seconds: 1));
      await capture(tester, '06_peer_popup');
    });

    testWidgets('07_dead_reckoning', (tester) async {
      await bootApp(tester, themeId: 'green');
      await tapTab(tester, 'TOOLS');
      await tester.tap(find.text('DEAD\nRECKONING').first);
      await Future<void>.delayed(const Duration(seconds: 2));
      await capture(tester, '07_dead_reckoning');
    });

    testWidgets('08_celestial', (tester) async {
      await bootApp(tester, themeId: 'blue');
      await tapTab(tester, 'TOOLS');
      await tester.tap(find.text('CELESTIAL\nNAVIGATION').first);
      await Future<void>.delayed(const Duration(seconds: 2));
      await capture(tester, '08_celestial');
    });

    testWidgets('09_search_area', (tester) async {
      await bootApp(tester, themeId: 'white', waitForTiles: true);
      await tester.pump();
      // Tap the "Draw annotation" floating button (bottom-right of the map)
      // to expand the annotation drawing toolbar.  Visible only when a
      // session is active — demo mode gives us that automatically.
      final drawBtn = find.byTooltip('Draw annotation');
      if (drawBtn.evaluate().isNotEmpty) {
        await tester.tap(drawBtn.first);
      } else {
        // Fallback: tap approximately where the button renders on a
        // 1080-wide viewport (right: 12, bottom: 100 from the map body).
        await tester.tapAt(const Offset(1046, 2080));
      }
      await Future<void>.delayed(const Duration(seconds: 1));
      await capture(tester, '09_search_area');
    });

    testWidgets('10_roster', (tester) async {
      await bootApp(tester, themeId: 'white');
      await tapTab(tester, 'LINK');
      // The SessionInfoCard on the active-session view has a "Roster"
      // action button that opens the TeamRosterSheet as a modal bottom
      // sheet.  In demo mode the session is active from the first frame.
      final rosterBtn = find.text('Roster');
      if (rosterBtn.evaluate().isNotEmpty) {
        await tester.tap(rosterBtn.first);
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      await capture(tester, '10_roster');
    });
  });
}

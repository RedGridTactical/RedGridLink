import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
// android_p2p_transport.dart: scaffolded but intentionally not wired
// here yet (see transport-stack comment below for the Codex review
// finding). Import re-added when Nearby Connections publishes the
// per-session id in discovery events.
import 'package:red_grid_link/services/field_link/transport/ble_transport.dart';
import 'package:red_grid_link/services/field_link/transport/ios_p2p_transport.dart';
import 'package:red_grid_link/services/field_link/transport/multi_transport.dart';
import 'package:red_grid_link/services/field_link/transport/transport_service.dart';
import 'package:red_grid_link/services/location/location_service.dart';
import 'package:red_grid_link/services/map/tile_manager.dart';

/// Key used to persist the local device ID across launches.
const _deviceIdKey = 'red_grid_link_device_id';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // In debug mode, log errors but keep the widget tree functional.
  // The default red error screen replaces the ENTIRE widget, making
  // the app unusable. This logs the error and shows a minimal indicator.
  if (kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      return Container(
        color: const Color(0x88FF0000),
        padding: const EdgeInsets.all(8),
        child: Text(
          details.exceptionAsString().split('\n').first,
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 10),
        ),
      );
    };
  }

  // Lock to portrait by default (landscape supported in-app)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Dark status bar for tactical appearance
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize SharedPreferences before app starts so settings are
  // available synchronously through the repository.
  final prefs = await SharedPreferences.getInstance();
  final settingsRepo = SettingsRepository(prefs);

  // ---------------------------------------------------------------------------
  // Database & repositories
  // ---------------------------------------------------------------------------
  final db = constructDb();
  final trackRepo = TrackRepository(db);
  final sessionRepo = SessionRepository(db);
  final peerRepo = PeerRepository(db);
  final markerRepo = MarkerRepository(db);
  final annotationRepo = AnnotationRepository(db);
  final mapRepo = MapRepository(db);
  final waypointRepo = WaypointRepository(prefs);

  // ---------------------------------------------------------------------------
  // Stable device ID (persisted across launches)
  // ---------------------------------------------------------------------------
  var deviceId = prefs.getString(_deviceIdKey);
  if (deviceId == null) {
    deviceId = generateDeviceId();
    await prefs.setString(_deviceIdKey, deviceId);
  }

  // ---------------------------------------------------------------------------
  // Field Link sub-services
  // ---------------------------------------------------------------------------

  // The transport stack runs BLE everywhere with a platform-specific
  // higher-bandwidth secondary on iOS:
  //   - iOS: Apple Multipeer Connectivity (AWDL) keeps peers
  //     discoverable when iOS suppresses BLE service-UUID emission
  //     in the background (motivated the v1.5.4 reviewer reports).
  //   - Android: BLE only. AndroidP2pTransport (Nearby Connections)
  //     remains in the tree but is NOT wired here — Codex review
  //     2026-05-03 P1 flagged that the native NearbyConnectionsChannel
  //     advertises the shared SERVICE_ID without the per-session id, so
  //     two Android teams in proximity would auto-connect across
  //     sessions. Re-enable this path only after the native channel
  //     publishes `sessionId` in DiscoveredDevice / connection events
  //     so the existing `device.sessionId` filters in FieldLinkService
  //     can drop foreign sessions.
  final BleTransport bleTransport = BleTransport();
  final TransportService transport;
  if (Platform.isIOS) {
    transport = MultiTransport(
      primary: bleTransport,
      secondaries: [IosP2pTransport()],
    );
  } else {
    // Android + other platforms: BLE only.
    transport = bleTransport;
  }

  final ghostManager = GhostManager();
  final batteryManager = BatteryManager();
  final syncEngine = SyncEngine(
    transport: transport,
    peerRepository: peerRepo,
    markerRepository: markerRepo,
    annotationRepository: annotationRepo,
    localDeviceId: deviceId,
  );

  // Shared LocationService instance — one GPS subscription for the whole
  // app. Used by FieldLinkService for session-scoped track recording AND
  // by the UI via locationServiceProvider override below. Two instances
  // would double GPS battery cost for no functional benefit.
  final locationService = LocationService(
    trackRepository: trackRepo,
  );

  final fieldLinkService = FieldLinkService(
    transport: transport,
    syncEngine: syncEngine,
    ghostManager: ghostManager,
    batteryManager: batteryManager,
    sessionRepository: sessionRepo,
    peerRepository: peerRepo,
    localDeviceId: deviceId,
    locationService: locationService,
  );

  // Wire up transport/sync state stream listeners so the service can
  // observe BLE state transitions and CRDT updates. Without this call,
  // session creation silently fails because status changes are never
  // propagated to the UI.
  await fieldLinkService.initialize();

  // ---------------------------------------------------------------------------
  // Tile manager with database-backed region storage
  // ---------------------------------------------------------------------------
  final tileManager = TileManager(mapRepository: mapRepo);

  // ---------------------------------------------------------------------------
  // Sentry crash reporting (release mode only)
  // ---------------------------------------------------------------------------
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (kReleaseMode && sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
        // Privacy: do not send PII or location data.
        options.sendDefaultPii = false;
        options.beforeSend = _stripLocationData;
      },
      appRunner: () => _launchApp(
        settingsRepo: settingsRepo,
        trackRepo: trackRepo,
        sessionRepo: sessionRepo,
        peerRepo: peerRepo,
        markerRepo: markerRepo,
        annotationRepo: annotationRepo,
        fieldLinkService: fieldLinkService,
        tileManager: tileManager,
        waypointRepo: waypointRepo,
        locationService: locationService,
      ),
    );
  } else {
    _launchApp(
      settingsRepo: settingsRepo,
      trackRepo: trackRepo,
      sessionRepo: sessionRepo,
      peerRepo: peerRepo,
      markerRepo: markerRepo,
      annotationRepo: annotationRepo,
      fieldLinkService: fieldLinkService,
      tileManager: tileManager,
      waypointRepo: waypointRepo,
      locationService: locationService,
    );
  }
}

/// Launch the app with all required provider overrides.
void _launchApp({
  required SettingsRepository settingsRepo,
  required TrackRepository trackRepo,
  required SessionRepository sessionRepo,
  required PeerRepository peerRepo,
  required MarkerRepository markerRepo,
  required AnnotationRepository annotationRepo,
  required FieldLinkService fieldLinkService,
  required TileManager tileManager,
  required WaypointRepository waypointRepo,
  required LocationService locationService,
}) {
  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        trackRepositoryProvider.overrideWithValue(trackRepo),
        sessionRepositoryProvider.overrideWithValue(sessionRepo),
        peerRepositoryProvider.overrideWithValue(peerRepo),
        markerRepositoryProvider.overrideWithValue(markerRepo),
        annotationRepositoryProvider.overrideWithValue(annotationRepo),
        fieldLinkServiceProvider.overrideWithValue(fieldLinkService),
        tileManagerProvider.overrideWithValue(tileManager),
        waypointRepositoryProvider.overrideWithValue(waypointRepo),
        // Override the LocationService provider with the same instance
        // FieldLinkService holds, so the UI position stream and the
        // FieldLink track recorder share one GPS subscription.
        locationServiceProvider.overrideWithValue(locationService),
      ],
      child: const RedGridLinkApp(),
    ),
  );
}

/// Strip location-related data from Sentry events for privacy.
///
/// Removes latitude/longitude from breadcrumb data to prevent
/// accidental transmission of user GPS positions.
SentryEvent? _stripLocationData(SentryEvent event, Hint hint) {
  // Strip location-related breadcrumb data.
  final cleanBreadcrumbs = event.breadcrumbs?.map((b) {
    if (b.data != null) {
      final data = Map<String, dynamic>.from(b.data!);
      data.remove('lat');
      data.remove('lon');
      data.remove('latitude');
      data.remove('longitude');
      data.remove('position');
      data.remove('mgrs');
      return b.copyWith(data: data);
    }
    return b;
  }).toList();

  return event.copyWith(breadcrumbs: cleanBreadcrumbs);
}

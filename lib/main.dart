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

/// Key used to persist the local device ID across launches.
const _deviceIdKey = 'red_grid_link_device_id';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final transport = BleTransport();
  final ghostManager = GhostManager();
  final batteryManager = BatteryManager();
  final syncEngine = SyncEngine(
    transport: transport,
    peerRepository: peerRepo,
    markerRepository: markerRepo,
    localDeviceId: deviceId,
  );

  final fieldLinkService = FieldLinkService(
    transport: transport,
    syncEngine: syncEngine,
    ghostManager: ghostManager,
    batteryManager: batteryManager,
    sessionRepository: sessionRepo,
    peerRepository: peerRepo,
    localDeviceId: deviceId,
  );

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

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:red_grid_link/data/database/tables/sessions_table.dart';
import 'package:red_grid_link/data/database/tables/peers_table.dart';
import 'package:red_grid_link/data/database/tables/markers_table.dart';
import 'package:red_grid_link/data/database/tables/tracks_table.dart';
import 'package:red_grid_link/data/database/tables/annotations_table.dart';
import 'package:red_grid_link/data/database/tables/map_regions_table.dart';
import 'package:red_grid_link/data/database/tables/session_history_table.dart';
import 'package:red_grid_link/data/database/tables/boundary_events_table.dart';

import 'package:red_grid_link/data/database/daos/sessions_dao.dart';
import 'package:red_grid_link/data/database/daos/peers_dao.dart';
import 'package:red_grid_link/data/database/daos/markers_dao.dart';
import 'package:red_grid_link/data/database/daos/tracks_dao.dart';
import 'package:red_grid_link/data/database/daos/annotations_dao.dart';
import 'package:red_grid_link/data/database/daos/map_regions_dao.dart';
import 'package:red_grid_link/data/database/daos/session_history_dao.dart';
import 'package:red_grid_link/data/database/daos/boundary_event_dao.dart';

part 'app_database.g.dart';

/// Main Drift database for Red Grid Link.
///
/// Includes all six tables and their corresponding DAOs for
/// sessions, peers, markers, tracks, annotations, and map regions.
@DriftDatabase(
  tables: [
    Sessions,
    Peers,
    Markers,
    Tracks,
    Annotations,
    MapRegions,
    SessionHistoryEntries,
    BoundaryEvents,
  ],
  daos: [
    SessionsDao,
    PeersDao,
    MarkersDao,
    TracksDao,
    AnnotationsDao,
    MapRegionsDao,
    SessionHistoryDao,
    BoundaryEventDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(sessionHistoryEntries);
          }
          if (from < 3) {
            await m.addColumn(peers, peers.role);
            await m.addColumn(peers, peers.callsign);
            await m.addColumn(peers, peers.customRoleLabel);
            await m.addColumn(markers, markers.origin);
            await m.addColumn(tracks, tracks.peerId);
            await m.createTable(boundaryEvents);
          }
        },
      );
}

/// Constructs the [AppDatabase] using a native SQLite file.
///
/// The database file is stored in the app's documents directory
/// as `red_grid_link.sqlite`.
AppDatabase constructDb() {
  final db = LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'red_grid_link.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
  return AppDatabase(db);
}

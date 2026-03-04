import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/tables/peers_table.dart';

part 'peers_dao.g.dart';

/// Data access object for [Peers] table operations.
@DriftAccessor(tables: [Peers])
class PeersDao extends DatabaseAccessor<AppDatabase> with _$PeersDaoMixin {
  PeersDao(super.db);

  /// Get all peers for a given session.
  Future<List<Peer>> getPeersBySession(String sessionId) =>
      (select(peers)..where((t) => t.sessionId.equals(sessionId))).get();

  /// Watch all peers for a given session.
  Stream<List<Peer>> watchPeersBySession(String sessionId) =>
      (select(peers)..where((t) => t.sessionId.equals(sessionId))).watch();

  /// Get only connected peers for a given session.
  Future<List<Peer>> getConnectedPeers(String sessionId) =>
      (select(peers)
            ..where((t) =>
                t.sessionId.equals(sessionId) &
                t.isConnected.equals(true)))
          .get();

  /// Watch connected peers for a given session.
  Stream<List<Peer>> watchConnectedPeers(String sessionId) =>
      (select(peers)
            ..where((t) =>
                t.sessionId.equals(sessionId) &
                t.isConnected.equals(true)))
          .watch();

  /// Get a single peer by ID.
  Future<Peer?> getPeerById(String id) =>
      (select(peers)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Insert a new peer.
  Future<int> insertPeer(PeersCompanion peer) => into(peers).insert(peer);

  /// Insert or update a peer (upsert).
  Future<int> upsertPeer(PeersCompanion peer) =>
      into(peers).insertOnConflictUpdate(peer);

  /// Update a peer's position data.
  Future<bool> updatePeerPosition(
    String id, {
    required double lat,
    required double lon,
    String? mgrs,
    required DateTime lastSeen,
    double? altitude,
    double? speed,
    double? heading,
    double? accuracy,
    int? batteryLevel,
  }) =>
      (update(peers)..where((t) => t.id.equals(id)))
          .write(PeersCompanion(
            lat: Value(lat),
            lon: Value(lon),
            mgrsRaw: Value(mgrs),
            lastSeen: Value(lastSeen),
            altitude: Value(altitude),
            speed: Value(speed),
            heading: Value(heading),
            accuracy: Value(accuracy),
            batteryLevel: Value(batteryLevel),
          ))
          .then((rows) => rows > 0);

  /// Mark a peer as disconnected.
  Future<bool> disconnectPeer(String id) =>
      (update(peers)..where((t) => t.id.equals(id)))
          .write(const PeersCompanion(isConnected: Value(false)))
          .then((rows) => rows > 0);

  /// Disconnect all peers in a session.
  Future<int> disconnectAllInSession(String sessionId) =>
      (update(peers)..where((t) => t.sessionId.equals(sessionId)))
          .write(const PeersCompanion(isConnected: Value(false)));

  /// Delete a peer by ID.
  Future<int> deletePeer(String id) =>
      (delete(peers)..where((t) => t.id.equals(id))).go();

  /// Delete all peers for a session.
  Future<int> deletePeersBySession(String sessionId) =>
      (delete(peers)..where((t) => t.sessionId.equals(sessionId))).go();
}

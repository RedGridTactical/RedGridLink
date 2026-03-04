import 'package:drift/drift.dart';
import 'package:red_grid_link/data/database/app_database.dart';
import 'package:red_grid_link/data/database/daos/peers_dao.dart';
import 'package:red_grid_link/data/models/peer.dart' as model;
import 'package:red_grid_link/data/models/position.dart';

/// Repository for managing peers in Field Link sessions.
///
/// Wraps [PeersDao] and converts between Drift data classes
/// and the application's [model.Peer] model objects.
class PeerRepository {
  final AppDatabase _db;

  PeerRepository(this._db);

  PeersDao get _dao => _db.peersDao;

  /// Get all peers for a session.
  Future<List<model.Peer>> getPeersBySession(String sessionId) async {
    final rows = await _dao.getPeersBySession(sessionId);
    return rows.map(_toModel).toList();
  }

  /// Watch all peers for a session.
  Stream<List<model.Peer>> watchPeersBySession(String sessionId) =>
      _dao.watchPeersBySession(sessionId).map(
        (rows) => rows.map(_toModel).toList(),
      );

  /// Get only connected peers for a session.
  Future<List<model.Peer>> getConnectedPeers(String sessionId) async {
    final rows = await _dao.getConnectedPeers(sessionId);
    return rows.map(_toModel).toList();
  }

  /// Watch connected peers for a session.
  Stream<List<model.Peer>> watchConnectedPeers(String sessionId) =>
      _dao.watchConnectedPeers(sessionId).map(
        (rows) => rows.map(_toModel).toList(),
      );

  /// Get a single peer by ID.
  Future<model.Peer?> getPeerById(String id) async {
    final row = await _dao.getPeerById(id);
    return row != null ? _toModel(row) : null;
  }

  /// Add or update a peer in a session.
  Future<void> upsertPeer(String sessionId, model.Peer peer) =>
      _dao.upsertPeer(_toCompanion(sessionId, peer));

  /// Update a peer's position.
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
      _dao.updatePeerPosition(
        id,
        lat: lat,
        lon: lon,
        mgrs: mgrs,
        lastSeen: lastSeen,
        altitude: altitude,
        speed: speed,
        heading: heading,
        accuracy: accuracy,
        batteryLevel: batteryLevel,
      );

  /// Mark a peer as disconnected.
  Future<bool> disconnectPeer(String id) => _dao.disconnectPeer(id);

  /// Disconnect all peers in a session.
  Future<int> disconnectAllInSession(String sessionId) =>
      _dao.disconnectAllInSession(sessionId);

  /// Delete a peer by ID.
  Future<int> deletePeer(String id) => _dao.deletePeer(id);

  /// Delete all peers for a session.
  Future<int> deletePeersBySession(String sessionId) =>
      _dao.deletePeersBySession(sessionId);

  // --- Conversion helpers ---

  model.Peer _toModel(Peer row) {
    Position? position;
    if (row.lat != null && row.lon != null) {
      position = Position(
        lat: row.lat!,
        lon: row.lon!,
        altitude: row.altitude,
        speed: row.speed,
        heading: row.heading,
        accuracy: row.accuracy,
        mgrsRaw: row.mgrsRaw ?? '',
        mgrsFormatted: '', // Computed on-demand from mgrsRaw
        timestamp: row.lastSeen,
      );
    }

    return model.Peer(
      id: row.id,
      displayName: row.displayName,
      deviceType: model.DeviceType.fromString(row.deviceType),
      position: position,
      lastSeen: row.lastSeen,
      isConnected: row.isConnected,
      batteryLevel: row.batteryLevel,
      syncMode: model.SyncMode.fromString(row.syncMode),
    );
  }

  PeersCompanion _toCompanion(String sessionId, model.Peer peer) =>
      PeersCompanion(
        id: Value(peer.id),
        sessionId: Value(sessionId),
        displayName: Value(peer.displayName),
        deviceType: Value(peer.deviceType.name),
        lat: Value(peer.position?.lat),
        lon: Value(peer.position?.lon),
        altitude: Value(peer.position?.altitude),
        speed: Value(peer.position?.speed),
        heading: Value(peer.position?.heading),
        accuracy: Value(peer.position?.accuracy),
        mgrsRaw: Value(peer.position?.mgrsRaw),
        lastSeen: Value(peer.lastSeen),
        isConnected: Value(peer.isConnected),
        batteryLevel: Value(peer.batteryLevel),
        syncMode: Value(peer.syncMode.name),
      );
}

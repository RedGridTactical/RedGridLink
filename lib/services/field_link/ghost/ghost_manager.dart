import 'dart:async';

import 'package:red_grid_link/core/constants/sync_constants.dart';
import 'package:red_grid_link/data/models/ghost.dart';
import 'package:red_grid_link/data/models/peer.dart';

/// Ghost marker lifecycle manager.
///
/// When a peer disconnects, the [GhostManager] creates a [Ghost] at the
/// peer's last known position. If the peer was moving (speed above
/// [SyncConstants.ghostVelocityThreshold]), the velocity vector is
/// recorded so the ghost's estimated position can be projected forward.
///
/// **Decay schedule** (from [SyncConstants]):
/// | Elapsed         | State           | Opacity |
/// |-----------------|-----------------|---------|
/// | 0 - 5 min       | [GhostState.full]   | 1.0     |
/// | 5 - 15 min      | [GhostState.faded]  | 0.5     |
/// | 15 - 30 min     | [GhostState.dim]    | 0.25    |
/// | 30+ min         | [GhostState.outline]| 0.1     |
///
/// When a peer reconnects ([onPeerReconnected]), the ghost is instantly
/// removed (snap-to-live), and the live peer marker takes over.
///
/// Users can manually remove a ghost via long-press
/// ([removeGhost] / [removeAllGhosts]).
class GhostManager {
  /// Interval for the periodic ghost state update timer.
  static const Duration _updateInterval = Duration(seconds: 30);

  final Map<String, Ghost> _ghosts = {};
  Timer? _updateTimer;

  final StreamController<List<Ghost>> _ghostController =
      StreamController<List<Ghost>>.broadcast();

  /// Stream of current ghost list, emitted whenever any ghost changes.
  Stream<List<Ghost>> get ghostStream => _ghostController.stream;

  /// Current snapshot of all active (non-removed) ghosts.
  List<Ghost> get currentGhosts =>
      _ghosts.values.where((g) => g.ghostState != GhostState.removed).toList();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Start the periodic ghost state update timer.
  ///
  /// Clears any ghosts from a previous session to prevent carry-over.
  Future<void> start() async {
    _updateTimer?.cancel();
    if (_ghosts.isNotEmpty) {
      _ghosts.clear();
      _emit();
    }
    _updateTimer = Timer.periodic(_updateInterval, (_) {
      _updateGhostStates();
    });
  }

  /// Dispose all resources. The manager should not be used after this.
  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _ghosts.clear();
    _ghostController.close();
  }

  // ---------------------------------------------------------------------------
  // Peer events
  // ---------------------------------------------------------------------------

  /// Called when a peer disconnects.
  ///
  /// Creates a [Ghost] from the peer's last known state. Records the
  /// velocity vector if the peer was moving above the threshold.
  void onPeerDisconnected(Peer peer) {
    if (peer.position == null) return;

    double? velocityBearing;
    double? velocitySpeed;

    // Record velocity if the peer was moving.
    if (peer.position!.speed != null &&
        peer.position!.speed! > SyncConstants.ghostVelocityThreshold) {
      velocitySpeed = peer.position!.speed;
      velocityBearing = peer.position!.heading;
    }

    final ghost = Ghost(
      peerId: peer.id,
      displayName: peer.displayName,
      lastPosition: peer.position!,
      disconnectedAt: DateTime.now(),
      ghostState: GhostState.full,
      velocityBearing: velocityBearing,
      velocitySpeed: velocitySpeed,
    );

    _ghosts[peer.id] = ghost;
    _emit();
  }

  /// Called when a previously disconnected peer reconnects.
  ///
  /// Instantly removes the ghost (snap-to-live). The live peer marker
  /// will take over in the UI.
  void onPeerReconnected(String peerId) {
    if (_ghosts.containsKey(peerId)) {
      _ghosts.remove(peerId);
      _emit();
    }
  }

  /// Manually remove a specific ghost (e.g., via long-press).
  void removeGhost(String peerId) {
    if (_ghosts.containsKey(peerId)) {
      _ghosts.remove(peerId);
      _emit();
    }
  }

  /// Remove all ghosts.
  void removeAllGhosts() {
    if (_ghosts.isNotEmpty) {
      _ghosts.clear();
      _emit();
    }
  }

  // ---------------------------------------------------------------------------
  // State machine
  // ---------------------------------------------------------------------------

  /// Periodic tick: update all ghost states based on elapsed time.
  ///
  /// State transitions:
  /// - Full -> Faded at [SyncConstants.ghostFadedMs]
  /// - Faded -> Dim at [SyncConstants.ghostDimMs]
  /// - Dim -> Outline at [SyncConstants.ghostOutlineMs]
  ///
  /// Outline ghosts remain until manually removed or peer reconnects.
  void _updateGhostStates() {
    if (_ghosts.isEmpty) return;

    bool changed = false;
    final now = DateTime.now();

    for (final entry in _ghosts.entries.toList()) {
      final ghost = entry.value;
      final elapsed = now.difference(ghost.disconnectedAt).inMilliseconds;

      final GhostState newState;
      if (elapsed >= SyncConstants.ghostOutlineMs) {
        newState = GhostState.outline;
      } else if (elapsed >= SyncConstants.ghostDimMs) {
        newState = GhostState.dim;
      } else if (elapsed >= SyncConstants.ghostFadedMs) {
        newState = GhostState.faded;
      } else {
        newState = GhostState.full;
      }

      if (newState != ghost.ghostState) {
        _ghosts[entry.key] = ghost.copyWith(ghostState: newState);
        changed = true;
      }
    }

    if (changed) {
      _emit();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Emit the current ghost list to stream subscribers.
  void _emit() {
    if (!_ghostController.isClosed) {
      _ghostController.add(currentGhosts);
    }
  }
}

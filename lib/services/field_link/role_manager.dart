import 'package:red_grid_link/data/models/team_role.dart';

/// Manages team role assignments and callsigns for a Field Link session.
///
/// The session creator is automatically assigned [TeamRole.lead]. Only the
/// lead can assign roles to other peers or promote another peer to lead
/// (which demotes the current lead to scout).
///
/// Role changes and callsign updates are encoded as compact control messages
/// for broadcast over the BLE transport.
class RoleManager {
  final String localDeviceId;
  TeamRole _localRole = TeamRole.scout;
  final Map<String, TeamRole> _peerRoles = {};
  String? _callsign;
  final Map<String, String> _peerCallsigns = {};
  final Map<String, String?> _peerCustomLabels = {};

  RoleManager({required this.localDeviceId});

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The local device's current role.
  TeamRole get localRole => _localRole;

  /// The local device's callsign, or empty string if unset.
  String get callsign => _callsign ?? '';

  /// Whether the local device is the session lead.
  bool get isLead => _localRole.isLead;

  /// Get the custom role label for a specific peer, or null if unset.
  String? customLabelForPeer(String peerId) => _peerCustomLabels[peerId];

  // ---------------------------------------------------------------------------
  // Setters
  // ---------------------------------------------------------------------------

  /// Set the local device's callsign.
  void setCallsign(String value) => _callsign = value;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize as session creator (lead role).
  void initializeAsCreator() => _localRole = TeamRole.lead;

  /// Initialize as session joiner (scout role).
  void initializeAsJoiner() => _localRole = TeamRole.scout;

  // ---------------------------------------------------------------------------
  // Peer queries
  // ---------------------------------------------------------------------------

  /// Get the role for a specific peer. Defaults to [TeamRole.scout].
  TeamRole roleForPeer(String peerId) => _peerRoles[peerId] ?? TeamRole.scout;

  /// Get the callsign for a specific peer. Defaults to empty string.
  String callsignForPeer(String peerId) => _peerCallsigns[peerId] ?? '';

  // ---------------------------------------------------------------------------
  // Role assignment (Lead only)
  // ---------------------------------------------------------------------------

  /// Assign a role to a peer. Only the lead can assign roles.
  ///
  /// Returns `true` if the assignment was accepted, `false` if the local
  /// device is not the lead.
  bool assignRole(String peerId, TeamRole role, {String? customLabel}) {
    if (!isLead) return false;
    _peerRoles[peerId] = role;
    return true;
  }

  /// Promote a peer to lead, transferring the lead role and demoting
  /// the local device to scout.
  ///
  /// No-op if the local device is not currently the lead.
  void promotePeerToLead(String peerId) {
    if (!isLead) return;
    _peerRoles[peerId] = TeamRole.lead;
    _localRole = TeamRole.scout;
  }

  // ---------------------------------------------------------------------------
  // Remote state application
  // ---------------------------------------------------------------------------

  /// Returns `true` if [deviceId] currently holds the lead role.
  bool _isLeader(String deviceId) {
    if (deviceId == localDeviceId) return isLead;
    return _peerRoles[deviceId] == TeamRole.lead;
  }

  /// Apply an incoming role change from the session leader.
  ///
  /// If [targetId] matches the local device, the local role is updated.
  /// Otherwise the peer role map is updated.
  ///
  /// **Note:** Caller is responsible for verifying the sender is the lead
  /// before invoking this method (see [handleControlEvent]).
  void applyRemoteRoleChange(
    String targetId,
    TeamRole role, {
    required String fromLeader,
    String? customLabel,
  }) {
    if (targetId == localDeviceId) {
      _localRole = role;
    } else {
      _peerRoles[targetId] = role;
    }

    if (customLabel != null) {
      _peerCustomLabels[targetId] = customLabel;
    }
  }

  /// Apply an incoming callsign update from a peer.
  void applyRemoteCallsign(String peerId, String callsign) {
    _peerCallsigns[peerId] = callsign;
  }

  // ---------------------------------------------------------------------------
  // Wire encoding
  // ---------------------------------------------------------------------------

  /// Encode a role assignment as a control message payload.
  ///
  /// Returns `null` if the local device is not the lead.
  Map<String, dynamic>? encodeRoleAssignment(
    String targetId,
    TeamRole role, {
    String? customLabel,
  }) {
    if (!isLead) return null;
    return {
      'evt': 'role_assign',
      'target': targetId,
      'role': role.toShortString(),
      if (customLabel != null) 'crl': customLabel,
    };
  }

  /// Encode a callsign update as a control message payload.
  Map<String, dynamic> encodeCallsignUpdate() {
    return {'evt': 'callsign_update', 'cs': callsign};
  }

  // ---------------------------------------------------------------------------
  // Incoming control event handling
  // ---------------------------------------------------------------------------

  /// Handle an incoming control event from a peer.
  ///
  /// Dispatches based on the `evt` field to the appropriate handler.
  void handleControlEvent(Map<String, dynamic> data, String senderId) {
    final evt = data['evt'] as String?;
    switch (evt) {
      case 'role_assign':
        if (!_isLeader(senderId)) break; // ignore unauthorized role assignments
        final target = data['target'] as String;
        final role = TeamRole.fromString(data['role'] as String);
        final customLabel = data['crl'] as String?;
        applyRemoteRoleChange(
          target,
          role,
          fromLeader: senderId,
          customLabel: customLabel,
        );
        break;
      case 'callsign_update':
        applyRemoteCallsign(senderId, data['cs'] as String? ?? '');
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Reset all state. Called when leaving a session.
  void reset() {
    _localRole = TeamRole.scout;
    _peerRoles.clear();
    _callsign = null;
    _peerCallsigns.clear();
    _peerCustomLabels.clear();
  }
}

import 'key_exchange.dart';

/// Manages ECDH key exchange state for all connected peers.
///
/// Each peer connection gets its own derived shared secret via P-256 ECDH.
/// The QR code session key is used as a fallback for peers that haven't
/// completed key exchange yet (backwards compatibility).
class KeyExchangeManager {
  final KeyExchange _keyExchange = KeyExchange();
  final Map<String, String> _peerKeys = {};
  String? _localPublicKey;

  /// Initialize and generate a new key pair for this session.
  void initialize() {
    _localPublicKey = _keyExchange.generateKeyPair();
  }

  /// Get the local public key to send to peers.
  String? get localPublicKey => _localPublicKey;

  /// Process a received public key from a peer.
  /// Returns the derived shared secret.
  String? handlePeerPublicKey(String peerId, String peerPublicKey) {
    try {
      final sharedKey = _keyExchange.deriveSharedKey(peerPublicKey);
      _peerKeys[peerId] = sharedKey;
      return sharedKey;
    } catch (_) {
      return null;
    }
  }

  /// Get the derived encryption key for a specific peer.
  /// Returns null if key exchange hasn't completed for this peer.
  String? keyForPeer(String peerId) => _peerKeys[peerId];

  /// Check if key exchange is complete for a peer.
  bool hasKeyForPeer(String peerId) => _peerKeys.containsKey(peerId);

  /// Remove a peer's key (on disconnect).
  void removePeer(String peerId) => _peerKeys.remove(peerId);

  /// Per-peer ECDH-derived shared keys (read-only view).
  Map<String, String> get peerKeys => Map.unmodifiable(_peerKeys);

  /// Clear all state (on session end).
  void reset() {
    _keyExchange.reset();
    _peerKeys.clear();
    _localPublicKey = null;
  }
}

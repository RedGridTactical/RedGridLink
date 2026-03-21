import 'dart:async';
import 'dart:collection';

import 'package:flutter_tts/flutter_tts.dart';

import 'nato_phonetic.dart';

/// Queued text-to-speech service for NATO phonetic position callouts.
///
/// Maintains a FIFO queue of callout strings and speaks them sequentially.
/// Includes debounce logic so a peer's grid is only announced when it
/// changes and enough time has elapsed since the last callout for that peer.
class VoiceCalloutService {
  final FlutterTts _tts;
  final Queue<String> _queue = Queue();
  bool _isSpeaking = false;
  bool _isEnabled = false;

  /// Minimum seconds between callouts for the same peer.
  static const debounceSeconds = 30;

  // Debounce: only callout a peer if their grid changed.
  final Map<String, String> _lastAnnouncedGrid = {};
  final Map<String, DateTime> _lastCalloutTime = {};

  /// Create the service, optionally injecting a [FlutterTts] instance
  /// for testing.
  VoiceCalloutService({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });
  }

  /// Whether voice callouts are currently enabled.
  bool get isEnabled => _isEnabled;

  /// The number of items waiting in the queue.
  int get queueLength => _queue.length;

  /// Enable or disable voice callouts.
  ///
  /// Disabling immediately stops any in-progress speech and clears the
  /// queue.
  void setEnabled(bool value) {
    _isEnabled = value;
    if (!value) {
      stop();
    }
  }

  /// Enqueue a callout if the peer's grid has changed and enough time
  /// has passed since the last callout for this peer.
  void enqueueIfChanged(String peerId, String callsign, String mgrs) {
    if (!_isEnabled) return;

    // Use first 10 chars as grid key (1m precision).
    final gridKey = mgrs.length >= 10 ? mgrs.substring(0, 10) : mgrs;

    // If grid hasn't changed, skip entirely.
    if (_lastAnnouncedGrid[peerId] == gridKey) return;

    // Rate-limit: if not enough time has passed since the last callout
    // for this peer, update the stored grid but skip the announcement
    // to avoid flooding during rapid movement.
    final lastTime = _lastCalloutTime[peerId];
    if (lastTime != null &&
        DateTime.now().difference(lastTime).inSeconds < debounceSeconds) {
      _lastAnnouncedGrid[peerId] = gridKey;
      return;
    }

    _lastAnnouncedGrid[peerId] = gridKey;
    _lastCalloutTime[peerId] = DateTime.now();

    final text = NatoPhonetic.buildCallout(callsign, mgrs);
    _queue.add(text);
    _processQueue();
  }

  /// Process the next item in the queue if not already speaking.
  Future<void> _processQueue() async {
    if (_isSpeaking || _queue.isEmpty) return;
    _isSpeaking = true;
    final text = _queue.removeFirst();
    await _tts.speak(text);
  }

  /// Stop all speech and clear the queue.
  void stop() {
    _queue.clear();
    _tts.stop();
    _isSpeaking = false;
  }

  /// Reset all state including debounce tracking.
  void reset() {
    stop();
    _lastAnnouncedGrid.clear();
    _lastCalloutTime.clear();
  }

  /// Clean up resources.
  Future<void> dispose() async {
    stop();
  }
}

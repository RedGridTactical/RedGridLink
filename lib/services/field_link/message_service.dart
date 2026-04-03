import 'dart:async';
import '../../data/models/tactical_message.dart';

/// Manages tactical message history and notifications.
class MessageService {
  final _messageController = StreamController<TacticalMessage>.broadcast();
  final List<TacticalMessage> _history = [];
  static const int maxHistory = 50;

  /// Stream of incoming messages for UI consumption.
  Stream<TacticalMessage> get onMessage => _messageController.stream;

  /// Message history (most recent first).
  List<TacticalMessage> get history => List.unmodifiable(_history);

  /// Add a received message to history and notify listeners.
  void addMessage(TacticalMessage message) {
    _history.insert(0, message);
    if (_history.length > maxHistory) {
      _history.removeLast();
    }
    _messageController.add(message);
  }

  /// Clear history (on session end).
  void clear() {
    _history.clear();
  }

  void dispose() {
    _messageController.close();
  }
}

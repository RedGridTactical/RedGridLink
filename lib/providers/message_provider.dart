import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'field_link_provider.dart';
import '../services/field_link/message_service.dart';
import '../data/models/tactical_message.dart';

/// Provides the message service from the active [FieldLinkService].
///
/// Falls back to a standalone instance when the service is not overridden
/// (e.g., in widget tests).
final messageServiceProvider = Provider<MessageService>((ref) {
  try {
    return ref.watch(fieldLinkServiceProvider).messageService;
  } catch (_) {
    return MessageService();
  }
});

/// Latest received message (for banner display).
final latestMessageProvider = StateProvider<TacticalMessage?>((ref) => null);

/// Full message history.
final messageHistoryProvider = StateProvider<List<TacticalMessage>>((ref) => []);

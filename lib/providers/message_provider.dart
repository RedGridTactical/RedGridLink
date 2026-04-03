import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/field_link/message_service.dart';
import '../data/models/tactical_message.dart';

final messageServiceProvider = Provider<MessageService>((ref) => MessageService());

/// Latest received message (for banner display).
final latestMessageProvider = StateProvider<TacticalMessage?>((ref) => null);

/// Full message history.
final messageHistoryProvider = StateProvider<List<TacticalMessage>>((ref) => []);

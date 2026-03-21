import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/voice/voice_callout_service.dart';

/// Singleton [VoiceCalloutService] provider.
///
/// Disposes the service when the provider is torn down.
final voiceCalloutServiceProvider = Provider<VoiceCalloutService>((ref) {
  final service = VoiceCalloutService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Whether voice callouts are enabled.
///
/// Toggled from the Settings screen. When changed, also updates the
/// underlying [VoiceCalloutService] via [voiceCalloutServiceProvider].
final voiceCalloutEnabledProvider = StateProvider<bool>((ref) => false);

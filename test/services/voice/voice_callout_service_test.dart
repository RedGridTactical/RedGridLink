import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:red_grid_link/services/voice/voice_callout_service.dart';

/// A minimal mock for [FlutterTts] that records speak calls.
class MockFlutterTts extends FlutterTts {
  final List<String> spokenTexts = [];
  VoidCallback? _completionHandler;
  bool stopped = false;

  @override
  dynamic setCompletionHandler(VoidCallback callback) {
    _completionHandler = callback;
    return null;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spokenTexts.add(text);
    stopped = false;
    // Simulate instant completion.
    _completionHandler?.call();
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    stopped = true;
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceCalloutService', () {
    late MockFlutterTts mockTts;
    late VoiceCalloutService service;

    setUp(() {
      mockTts = MockFlutterTts();
      service = VoiceCalloutService(tts: mockTts);
    });

    test('enqueueIfChanged does nothing when disabled', () {
      // Service starts disabled by default.
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      expect(mockTts.spokenTexts, isEmpty);
    });

    test('enqueueIfChanged works when enabled', () {
      service.setEnabled(true);
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      expect(mockTts.spokenTexts, hasLength(1));
      expect(mockTts.spokenTexts.first, contains('ALPHA'));
      expect(mockTts.spokenTexts.first, contains('grid'));
    });

    test('same grid does not re-queue (debounce)', () {
      service.setEnabled(true);
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      // Only the first call should trigger a speak.
      expect(mockTts.spokenTexts, hasLength(1));
    });

    test('different grid within debounce window updates stored grid but does not queue', () {
      service.setEnabled(true);
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      // Different grid within debounce window: stored grid updates but
      // no new callout to avoid flooding during rapid movement.
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC99999');
      expect(mockTts.spokenTexts, hasLength(1));
    });

    test('different grid after reset does queue', () {
      service.setEnabled(true);
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      // Reset clears debounce, so next call should queue.
      service.reset();
      service.setEnabled(true);
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC99999');
      expect(mockTts.spokenTexts, hasLength(2));
    });

    test('different peers are tracked independently', () {
      service.setEnabled(true);
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      service.enqueueIfChanged('peer2', 'BRAVO', '18SUC12345');
      expect(mockTts.spokenTexts, hasLength(2));
    });

    test('stop clears queue', () {
      service.setEnabled(true);
      service.stop();
      expect(service.queueLength, 0);
    });

    test('reset clears debounce state', () {
      service.setEnabled(true);
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      expect(mockTts.spokenTexts, hasLength(1));

      service.reset();

      // Same grid should now queue again after reset.
      service.setEnabled(true);
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      expect(mockTts.spokenTexts, hasLength(2));
    });

    test('disabling stops speech and clears queue', () {
      service.setEnabled(true);
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC12345');
      service.setEnabled(false);
      expect(mockTts.stopped, isTrue);
      expect(service.queueLength, 0);
    });

    test('isEnabled reflects current state', () {
      expect(service.isEnabled, isFalse);
      service.setEnabled(true);
      expect(service.isEnabled, isTrue);
      service.setEnabled(false);
      expect(service.isEnabled, isFalse);
    });

    test('short grid keys under 10 chars still work', () {
      service.setEnabled(true);
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC');
      expect(mockTts.spokenTexts, hasLength(1));

      // Same short grid should not re-queue.
      service.enqueueIfChanged('peer1', 'ALPHA', '18SUC');
      expect(mockTts.spokenTexts, hasLength(1));
    });
  });
}

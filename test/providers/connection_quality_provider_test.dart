import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/providers/connection_quality_provider.dart';

void main() {
  group('ConnectionQuality', () {
    test('averageRssi computes rolling average', () {
      final cq = ConnectionQuality();
      cq.addReading(-60);
      cq.addReading(-70);
      cq.addReading(-80);
      expect(cq.averageRssi, -70);
    });

    test('keeps only last 5 readings', () {
      final cq = ConnectionQuality();
      for (final r in [-50, -55, -60, -65, -70, -75]) {
        cq.addReading(r);
      }
      // Last 5: -55, -60, -65, -70, -75 → avg = -65
      expect(cq.averageRssi, -65);
    });

    test('empty readings returns -100', () {
      expect(ConnectionQuality().averageRssi, -100);
    });

    test('tier classifies RSSI correctly', () {
      expect(ConnectionQuality.tierFor(-50), SignalTier.excellent);
      expect(ConnectionQuality.tierFor(-60), SignalTier.excellent);
      expect(ConnectionQuality.tierFor(-65), SignalTier.good);
      expect(ConnectionQuality.tierFor(-70), SignalTier.good);
      expect(ConnectionQuality.tierFor(-75), SignalTier.fair);
      expect(ConnectionQuality.tierFor(-80), SignalTier.fair);
      expect(ConnectionQuality.tierFor(-85), SignalTier.weak);
      expect(ConnectionQuality.tierFor(-95), SignalTier.weak);
    });

    test('bars returns correct count', () {
      final cq = ConnectionQuality();
      cq.addReading(-50);
      expect(cq.bars, 4);

      final cq2 = ConnectionQuality();
      cq2.addReading(-90);
      expect(cq2.bars, 1);
    });

    test('isWarning true after 3 consecutive weak readings', () {
      final cq = ConnectionQuality();
      cq.addReading(-90);
      cq.addReading(-88);
      cq.addReading(-92);
      expect(cq.isWarning, isTrue);
    });

    test('isWarning false with mixed readings', () {
      final cq = ConnectionQuality();
      cq.addReading(-90);
      cq.addReading(-60); // good reading breaks streak
      cq.addReading(-92);
      expect(cq.isWarning, isFalse);
    });

    test('isWarning false with insufficient readings', () {
      final cq = ConnectionQuality();
      cq.addReading(-90);
      cq.addReading(-90);
      expect(cq.isWarning, isFalse);
    });
  });

  group('ConnectionQualityNotifier', () {
    test('updateRssi creates new entry for unknown peer', () {
      final notifier = ConnectionQualityNotifier();
      notifier.updateRssi('peer1', -60);
      expect(notifier.state.containsKey('peer1'), isTrue);
      expect(notifier.state['peer1']!.averageRssi, -60);
    });

    test('updateRssi updates existing peer', () {
      final notifier = ConnectionQualityNotifier();
      notifier.updateRssi('peer1', -60);
      notifier.updateRssi('peer1', -80);
      expect(notifier.state['peer1']!.averageRssi, -70);
    });

    test('removePeer removes entry', () {
      final notifier = ConnectionQualityNotifier();
      notifier.updateRssi('peer1', -60);
      notifier.removePeer('peer1');
      expect(notifier.state.containsKey('peer1'), isFalse);
    });

    test('clear removes all entries', () {
      final notifier = ConnectionQualityNotifier();
      notifier.updateRssi('peer1', -60);
      notifier.updateRssi('peer2', -70);
      notifier.clear();
      expect(notifier.state, isEmpty);
    });
  });
}

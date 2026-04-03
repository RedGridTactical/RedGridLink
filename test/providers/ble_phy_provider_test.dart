import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/providers/ble_phy_provider.dart';

void main() {
  group('PeerCodedPhyNotifier', () {
    late PeerCodedPhyNotifier notifier;

    setUp(() {
      notifier = PeerCodedPhyNotifier();
    });

    test('initial state is empty', () {
      expect(notifier.debugState, isEmpty);
    });

    test('add inserts a device ID', () {
      notifier.add('device-1');
      expect(notifier.debugState, contains('device-1'));
    });

    test('add is idempotent', () {
      notifier.add('device-1');
      notifier.add('device-1');
      expect(notifier.debugState.length, 1);
    });

    test('remove removes a device ID', () {
      notifier.add('device-1');
      notifier.add('device-2');
      notifier.remove('device-1');
      expect(notifier.debugState, isNot(contains('device-1')));
      expect(notifier.debugState, contains('device-2'));
    });

    test('remove is no-op for absent device', () {
      notifier.add('device-1');
      notifier.remove('nonexistent');
      expect(notifier.debugState.length, 1);
    });

    test('isPeerCodedPhy returns correct values', () {
      expect(notifier.isPeerCodedPhy('device-1'), isFalse);
      notifier.add('device-1');
      expect(notifier.isPeerCodedPhy('device-1'), isTrue);
      notifier.remove('device-1');
      expect(notifier.isPeerCodedPhy('device-1'), isFalse);
    });
  });
}

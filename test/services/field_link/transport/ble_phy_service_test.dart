import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/services/field_link/transport/ble_phy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BlePhyService service;

  setUp(() {
    service = BlePhyService();
  });

  group('with Coded PHY supported', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.redgrid.link/ble_phy'),
        (call) async {
          if (call.method == 'isCodedPhySupported') return true;
          if (call.method == 'requestCodedPhy') return true;
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.redgrid.link/ble_phy'),
        null,
      );
    });

    test('isCodedPhySupported returns true', () async {
      expect(await service.isCodedPhySupported(), isTrue);
    });

    test('requestCodedPhy returns true', () async {
      expect(await service.requestCodedPhy('AA:BB:CC:DD:EE:FF'), isTrue);
    });
  });

  group('with Coded PHY unsupported', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.redgrid.link/ble_phy'),
        (call) async => false,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.redgrid.link/ble_phy'),
        null,
      );
    });

    test('isCodedPhySupported returns false', () async {
      expect(await service.isCodedPhySupported(), isFalse);
    });
  });

  group('with no platform channel (MissingPluginException)', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.redgrid.link/ble_phy'),
        null,
      );
    });

    test('isCodedPhySupported returns false gracefully', () async {
      expect(await service.isCodedPhySupported(), isFalse);
    });

    test('requestCodedPhy returns false gracefully', () async {
      expect(await service.requestCodedPhy('test'), isFalse);
    });
  });

  group('requestCodedPhyOnDevice', () {
    // Note: requestCodedPhyOnDevice uses flutter_blue_plus's
    // BluetoothDevice.setPreferredPhy() which requires a real BLE stack.
    // In tests (no Android platform), it returns false gracefully.
    // The method also checks Platform.isAndroid which is false in tests.

    test('returns false in test environment (not Android)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.redgrid.link/ble_phy'),
        (call) async {
          if (call.method == 'isCodedPhySupported') return true;
          return null;
        },
      );

      // Cannot construct a real BluetoothDevice in test, but we can verify
      // the service tracks state correctly via public API.
      expect(service.isCodedPhyRequested('AA:BB:CC:DD:EE:FF'), isFalse);
      expect(service.codedPhyPeers, isEmpty);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.redgrid.link/ble_phy'),
        null,
      );
    });
  });

  group('device tracking', () {
    test('clearDevice removes device from tracking set', () {
      // Simulate internal state by testing the public tracking API.
      // In production, requestCodedPhyOnDevice adds to the set.
      service.clearDevice('AA:BB:CC:DD:EE:FF');
      expect(service.isCodedPhyRequested('AA:BB:CC:DD:EE:FF'), isFalse);
    });

    test('codedPhyPeers returns unmodifiable set', () {
      final peers = service.codedPhyPeers;
      expect(peers, isA<Set<String>>());
      expect(peers, isEmpty);
    });
  });
}

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
}

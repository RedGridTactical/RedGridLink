/// BLE constants for Field Link
class BleConstants {
  BleConstants._();

  // Custom service UUID for Red Grid Link Field Link
  // Generated once, never change
  static const String fieldLinkServiceUuid = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';

  // Characteristic UUIDs
  static const String positionCharUuid = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5e';
  static const String markerCharUuid = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5f';
  static const String controlCharUuid = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c60';
  static const String annotationCharUuid = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c61';

  // BLE advertising
  static const int advertisingIntervalMs = 100;
  static const int scanTimeoutMs = 5000;

  // MTU
  static const int preferredMtu = 512;
  static const int minMtu = 23;
}

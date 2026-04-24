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

  // ---------------------------------------------------------------------------
  // Session ID encoding for advertisement payload
  // ---------------------------------------------------------------------------

  /// Encode a UUID v4 sessionId string (e.g. "550e8400-e29b-41d4-a716-...")
  /// into the 16 raw bytes that go into BLE serviceData.
  ///
  /// Strips hyphens, parses as hex, returns 16 bytes. Returns null if the
  /// input is not a parseable hex UUID.
  static List<int>? encodeSessionIdToBytes(String sessionId) {
    final hex = sessionId.replaceAll('-', '');
    if (hex.length != 32) return null;
    final bytes = <int>[];
    for (var i = 0; i < 32; i += 2) {
      final byte = int.tryParse(hex.substring(i, i + 2), radix: 16);
      if (byte == null) return null;
      bytes.add(byte);
    }
    return bytes;
  }

  /// Decode 16 raw bytes from BLE serviceData back into a canonical UUID v4
  /// string with hyphens. Returns null if the input is not 16 bytes.
  static String? decodeSessionIdFromBytes(List<int> bytes) {
    if (bytes.length != 16) return null;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}

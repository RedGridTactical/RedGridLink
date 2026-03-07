/// Sync engine constants for Field Link
class SyncConstants {
  SyncConstants._();

  // Heartbeat intervals (milliseconds)
  static const int ultraExpeditionIntervalMs = 60000; // 60s - minimal power
  static const int expeditionIntervalMs = 30000; // 30s - BLE only
  static const int normalIntervalMs = 15000;     // 15s
  static const int activeIntervalMs = 5000;      // 5s
  static const int urgentIntervalMs = 2000;      // 2s - high battery cost

  // Payload limits
  static const int maxPayloadBytes = 200;
  static const int maxBulkPayloadBytes = 50000; // 50KB for photos/routes via P2P

  // Ghost decay thresholds (milliseconds)
  static const int ghostFadedMs = 5 * 60 * 1000;   // 5 min → 50% opacity
  static const int ghostDimMs = 15 * 60 * 1000;     // 15 min → 25% opacity
  static const int ghostOutlineMs = 30 * 60 * 1000;  // 30 min → outline only

  // Ghost velocity vector threshold (m/s)
  static const double ghostVelocityThreshold = 0.5;

  // Session limits
  static const int maxSessionDevices = 8;
  static const int sessionPinLength = 4;
}

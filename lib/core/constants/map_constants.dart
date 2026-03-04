/// Map constants for offline tile rendering
class MapConstants {
  MapConstants._();

  // Default map center (CONUS center)
  static const double defaultLat = 39.8283;
  static const double defaultLon = -98.5795;
  static const double defaultZoom = 4.0;

  // Zoom limits
  static const double minZoom = 2.0;
  static const double maxZoom = 18.0;
  static const double maxDownloadZoom = 16.0; // Cap for region pack downloads

  // Tile sources
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String openTopoUrl = 'https://tile.opentopomap.org/{z}/{x}/{y}.png';

  // MGRS grid density by zoom
  // <8: Grid Zone Designators only
  // 8-12: 100km grid squares
  // 12-15: 1km grid lines
  // 15+: 100m grid lines
  static const int gzdZoomThreshold = 8;
  static const int gridSquareZoomThreshold = 12;
  static const int kmGridZoomThreshold = 15;

  // Attribution
  static const String osmAttribution = '© OpenStreetMap contributors';
  static const String openTopoAttribution = '© OpenTopoMap (CC-BY-SA)';
  static const String usgsAttribution = 'USGS National Map (Public Domain)';
}

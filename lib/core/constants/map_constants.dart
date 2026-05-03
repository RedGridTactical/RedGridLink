/// Map constants for offline tile rendering.
///
/// Audit 2026-05-03 P1: the configured `tile.openstreetmap.org` and
/// `tile.opentopomap.org` endpoints are public, donation-funded servers.
/// Their tile usage policies prohibit bulk download / offline prefetch,
/// so [tilePolicyFor] returns a [TilePolicy] flag the UI uses to warn
/// the user before kicking off a region download. A licensed provider
/// (Mapbox, MapTiler, self-hosted PMTiles, etc.) should be wired in
/// before scaling the offline-map feature commercially.
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

  /// Maximum tile count any single offline region download is permitted
  /// to issue. Sized so an inadvertent country-wide rectangle at zoom
  /// 16 cannot drop a 5 GB request on a public tile server. Roughly
  /// equivalent to ~50 km × 50 km at z=16, which fits the SAR / hike
  /// region size users actually need.
  static const int maxTilesPerRegionDownload = 200000;

  /// Throttle: minimum gap between successive tile requests in
  /// milliseconds. 100 ms = 10 req/s, well under the OpenStreetMap
  /// usage policy's heavy-use threshold.
  static const int interTileDelayMs = 100;

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

  /// Returns the tile URL template for the given source identifier.
  static String tileUrlFor(String sourceId) {
    switch (sourceId) {
      case 'topo':
        return openTopoUrl;
      case 'osm':
      default:
        return osmTileUrl;
    }
  }

  /// Returns the attribution string for the given source identifier.
  static String attributionFor(String sourceId) {
    switch (sourceId) {
      case 'topo':
        return openTopoAttribution;
      case 'osm':
      default:
        return osmAttribution;
    }
  }

  /// Returns the licensing posture of the tile source for offline
  /// download purposes. Used by the map download UI to surface a clear
  /// warning before downloading a region pack from a server whose
  /// terms restrict bulk offline use.
  static TilePolicy tilePolicyFor(String sourceId) {
    switch (sourceId) {
      case 'topo':
        // OpenTopoMap public tiles — community donation-funded, sustained
        // bulk downloads are explicitly discouraged.
        return const TilePolicy(
          providerName: 'OpenTopoMap (public)',
          allowsBulkOffline: false,
          policyUrl: 'https://opentopomap.org/about',
        );
      case 'osm':
      default:
        // OpenStreetMap public tile server — bulk download / offline
        // prefetch from tile.openstreetmap.org is explicitly prohibited
        // by the OSMF tile usage policy.
        return const TilePolicy(
          providerName: 'OpenStreetMap (public)',
          allowsBulkOffline: false,
          policyUrl: 'https://operations.osmfoundation.org/policies/tiles/',
        );
    }
  }
}

/// Licensing / acceptable-use information for a tile provider. Lets the
/// UI ask "is it OK to download this region pack from here?" without the
/// download path itself having to know about the underlying provider.
class TilePolicy {
  /// Human-readable provider name shown in download warnings.
  final String providerName;

  /// True when the provider's terms allow bulk / offline downloads.
  /// False for public OSM-style donation-funded servers.
  final bool allowsBulkOffline;

  /// URL to the provider's tile usage / terms-of-service page.
  final String policyUrl;

  const TilePolicy({
    required this.providerName,
    required this.allowsBulkOffline,
    required this.policyUrl,
  });
}

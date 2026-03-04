/// MGRS Coordinate Conversion Utility
///
/// Pure Dart implementation — no external dependencies, no network calls.
/// Based on the Defense Mapping Agency Technical Manual (DMA TM 8358.1).

import 'dart:math';

const double _wgs84A = 6378137.0;
const double _wgs84F = 1 / 298.257223563;
final double _wgs84E2 = 2 * _wgs84F - _wgs84F * _wgs84F;
final double _wgs84Ep2 = _wgs84E2 / (1 - _wgs84E2);

double _degToRad(double deg) {
  return (deg * pi) / 180;
}

int _getZoneNumber(double lat, double lon) {
  // Special zones for Norway/Svalbard
  if (lat >= 56 && lat < 64 && lon >= 3 && lon < 12) return 32;
  if (lat >= 72 && lat < 84) {
    if (lon >= 0 && lon < 9) return 31;
    if (lon >= 9 && lon < 21) return 33;
    if (lon >= 21 && lon < 33) return 35;
    if (lon >= 33 && lon < 42) return 37;
  }
  return ((lon + 180) / 6).floor() + 1;
}

String? _getZoneLetter(double lat) {
  const letters = 'CDEFGHJKLMNPQRSTUVWXX';
  if (lat >= -80 && lat <= 84) {
    return letters[((lat + 80) / 8).floor()];
  }
  return null;
}

({int easting, int northing, int zoneNum, String? zoneLetter}) _latLonToUTM(
    double lat, double lon) {
  final double latRad = _degToRad(lat);
  final double lonRad = _degToRad(lon);
  final int zoneNum = _getZoneNumber(lat, lon);
  final double lonOrigin = (zoneNum - 1) * 6.0 - 180 + 3;
  final double lonOriginRad = _degToRad(lonOrigin);

  final double a = _wgs84A;
  final double e2 = _wgs84E2;
  final double ep2 = _wgs84Ep2;

  final double N = a / sqrt(1 - e2 * pow(sin(latRad), 2).toDouble());
  final double T = pow(tan(latRad), 2).toDouble();
  final double C = ep2 * pow(cos(latRad), 2).toDouble();
  final double A2 = cos(latRad) * (lonRad - lonOriginRad);

  final double M = a *
      ((1 - e2 / 4 - (3 * pow(e2, 2).toDouble()) / 64 - (5 * pow(e2, 3).toDouble()) / 256) *
              latRad -
          ((3 * e2) / 8 +
                  (3 * pow(e2, 2).toDouble()) / 32 +
                  (45 * pow(e2, 3).toDouble()) / 1024) *
              sin(2 * latRad) +
          ((15 * pow(e2, 2).toDouble()) / 256 +
                  (45 * pow(e2, 3).toDouble()) / 1024) *
              sin(4 * latRad) -
          ((35 * pow(e2, 3).toDouble()) / 3072) * sin(6 * latRad));

  double easting = 0.9996 *
          N *
          (A2 +
              ((1 - T + C) * pow(A2, 3).toDouble()) / 6 +
              ((5 - 18 * T + pow(T, 2).toDouble() + 72 * C - 58 * ep2) *
                      pow(A2, 5).toDouble()) /
                  120) +
      500000;

  double northing = 0.9996 *
      (M +
          N *
              tan(latRad) *
              (pow(A2, 2).toDouble() / 2 +
                  ((5 - T + 9 * C + 4 * pow(C, 2).toDouble()) *
                          pow(A2, 4).toDouble()) /
                      24 +
                  ((61 -
                              58 * T +
                              pow(T, 2).toDouble() +
                              600 * C -
                              330 * ep2) *
                          pow(A2, 6).toDouble()) /
                      720));

  if (lat < 0) northing += 10000000;

  return (
    easting: easting.round(),
    northing: northing.round(),
    zoneNum: zoneNum,
    zoneLetter: _getZoneLetter(lat),
  );
}

String _utmToMGRS(
    int easting, int northing, int zoneNum, String? zoneLetter,
    [int precision = 5]) {
  const int colSets = 6;
  const List<String> colOrigins = ['ABCDEFGH', 'JKLMNPQR', 'STUVWXYZ'];
  const List<String> rowOrigins = [
    'ABCDEFGHJKLMNPQRSTUV',
    'FGHJKLMNPQRSTUVABCDE'
  ];

  final int setNum = ((zoneNum - 1) % colSets) + 1;
  final String colSet = colOrigins[((setNum - 1) / 2).floor()];
  final String rowSet = rowOrigins[(setNum - 1) % 2];

  final int colIdx = (easting / 100000).floor() - 1;
  final String colLetter = colSet[colIdx];

  final int rowIdx = ((northing % 2000000) / 100000).floor();
  final String rowLetter = rowSet[rowIdx];

  final int e = (easting % 100000).floor();
  final int n = (northing % 100000).floor();

  final int divisor = pow(10, 5 - precision).toInt();
  final String eStr = (e ~/ divisor).toString().padLeft(precision, '0');
  final String nStr = (n ~/ divisor).toString().padLeft(precision, '0');

  return '$zoneNum$zoneLetter$colLetter$rowLetter$eStr$nStr';
}

/// Convert WGS84 lat/lon to MGRS string.
///
/// [lat] Latitude in decimal degrees.
/// [lon] Longitude in decimal degrees.
/// [precision] Grid precision (1-5, default 5 = 1m).
/// Returns MGRS coordinate string.
String toMGRS(double lat, double lon, [int precision = 5]) {
  try {
    if (lat < -80 || lat > 84) return 'OUT OF RANGE';
    final utm = _latLonToUTM(lat, lon);
    return _utmToMGRS(
        utm.easting, utm.northing, utm.zoneNum, utm.zoneLetter, precision);
  } catch (e) {
    return 'ERROR';
  }
}

/// Format MGRS string with spaces for readability: 18S UJ 12345 67890.
///
/// [mgrs] Raw MGRS string.
/// Returns formatted MGRS string.
String formatMGRS(String? mgrs) {
  if (mgrs == null || mgrs.length < 5) return mgrs ?? '';
  // Parse: zone number (1-2 digits) + zone letter (1) + grid square (2) + easting/northing
  final match = RegExp(r'^(\d{1,2})([A-Z])([A-Z]{2})(\d+)$').firstMatch(mgrs);
  if (match == null) return mgrs;
  final zone = match.group(1)!;
  final band = match.group(2)!;
  final sq = match.group(3)!;
  final nums = match.group(4)!;
  final half = nums.length ~/ 2;
  final e = nums.substring(0, half);
  final n = nums.substring(half);
  return '$zone$band $sq $e $n';
}

/// Calculate bearing from point A to point B.
///
/// [lat1] Source latitude.
/// [lon1] Source longitude.
/// [lat2] Destination latitude.
/// [lon2] Destination longitude.
/// Returns bearing in degrees (0-360, 0=North).
double calculateBearing(
    double lat1, double lon1, double lat2, double lon2) {
  final double phi1 = _degToRad(lat1);
  final double phi2 = _degToRad(lat2);
  final double dLambda = _degToRad(lon2 - lon1);

  final double y = sin(dLambda) * cos(phi2);
  final double x =
      cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLambda);
  final double theta = atan2(y, x);

  return ((theta * 180) / pi + 360) % 360;
}

/// Calculate distance between two points in meters (Haversine formula).
double calculateDistance(
    double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371000; // Earth radius in meters
  final double phi1 = _degToRad(lat1);
  final double phi2 = _degToRad(lat2);
  final double dPhi = _degToRad(lat2 - lat1);
  final double dLambda = _degToRad(lon2 - lon1);

  final double a = pow(sin(dPhi / 2), 2).toDouble() +
      cos(phi1) * cos(phi2) * pow(sin(dLambda / 2), 2).toDouble();
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c;
}

/// Format distance to human-readable string.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()}m';
  return '${(meters / 1000).toStringAsFixed(1)}km';
}

/// Parse an MGRS coordinate string to WGS84 lat/lon.
///
/// [mgrs] MGRS string (with or without spaces).
/// Returns parsed coordinates or null if invalid.
({double lat, double lon})? parseMGRSToLatLon(String mgrs) {
  try {
    final cleaned = mgrs.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final match = RegExp(r'^(\d{1,2})([C-HJ-NP-X])([A-HJ-NP-Z]{2})(\d{4,10})$',
            caseSensitive: false)
        .firstMatch(cleaned);
    if (match == null) return null;

    final zone = int.parse(match.group(1)!);
    final band = match.group(2)!;
    final sq = match.group(3)!;
    final nums = match.group(4)!;
    final half = nums.length ~/ 2;
    final scale = pow(10, 5 - half).toInt();
    final easting = int.parse(nums.substring(0, half)) * scale;
    final northing = int.parse(nums.substring(half)) * scale;

    final setNum = ((zone - 1) % 6) + 1;
    final colSet = ['ABCDEFGH', 'JKLMNPQR', 'STUVWXYZ'][((setNum - 1) / 2).floor()];
    final rowSet = [
      'ABCDEFGHJKLMNPQRSTUV',
      'FGHJKLMNPQRSTUVABCDE'
    ][(setNum - 1) % 2];

    final colIdx = colSet.indexOf(sq[0].toUpperCase());
    final rowIdx = rowSet.indexOf(sq[1].toUpperCase());
    if (colIdx == -1 || rowIdx == -1) return null;

    final fullEasting = (colIdx + 1) * 100000 + easting;

    final bandLatMin =
        'CDEFGHJKLMNPQRSTUVWX'.indexOf(band.toUpperCase()) * 8 - 80;
    final latRad = ((bandLatMin + 4) * pi) / 180;

    const double a = 6378137.0;
    const double f = 1 / 298.257223563;
    const double e2 = 2 * f - f * f;

    final mApprox = a *
        ((1 - e2 / 4 - (3 * pow(e2, 2).toDouble()) / 64) * latRad -
            ((3 * e2) / 8 + (3 * pow(e2, 2).toDouble()) / 32) *
                sin(2 * latRad));

    double fullNorthing =
        (mApprox / 2000000).round() * 2000000.0 + rowIdx * 100000 + northing;
    if (bandLatMin < 0) fullNorthing -= 10000000;

    const double k0 = 0.9996;
    const double ep2 = e2 / (1 - e2);
    final double lonOrigin = ((zone - 1) * 6 - 180 + 3) * (pi / 180);

    final double mVal = fullNorthing / k0;
    final double mu = mVal /
        (a *
            (1 -
                e2 / 4 -
                (3 * pow(e2, 2).toDouble()) / 64 -
                (5 * pow(e2, 3).toDouble()) / 256));
    final double e1 = (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2));

    final double phi1 = mu +
        (3 * e1) / 2 * sin(2 * mu) +
        (27 * pow(e1, 2).toDouble()) / 16 * sin(4 * mu) +
        (151 * pow(e1, 3).toDouble()) / 96 * sin(6 * mu);

    final double N1 = a / sqrt(1 - e2 * pow(sin(phi1), 2).toDouble());
    final double T1 = pow(tan(phi1), 2).toDouble();
    final double C1 = ep2 * pow(cos(phi1), 2).toDouble();
    final double R1 = (a * (1 - e2)) /
        pow(1 - e2 * pow(sin(phi1), 2).toDouble(), 1.5).toDouble();
    final double D = (fullEasting - 500000) / (N1 * k0);

    final double lat2 = phi1 -
        (N1 * tan(phi1)) /
            R1 *
            (pow(D, 2).toDouble() / 2 -
                ((5 +
                            3 * T1 +
                            10 * C1 -
                            4 * pow(C1, 2).toDouble() -
                            9 * ep2) *
                        pow(D, 4).toDouble()) /
                    24 +
                ((61 +
                            90 * T1 +
                            298 * C1 +
                            45 * pow(T1, 2).toDouble() -
                            252 * ep2 -
                            3 * pow(C1, 2).toDouble()) *
                        pow(D, 6).toDouble()) /
                    720);

    final double lon2 = lonOrigin +
        (D -
                ((1 + 2 * T1 + C1) * pow(D, 3).toDouble()) / 6 +
                ((5 -
                            2 * C1 +
                            28 * T1 -
                            3 * pow(C1, 2).toDouble() +
                            8 * ep2 +
                            24 * pow(T1, 2).toDouble()) *
                        pow(D, 5).toDouble()) /
                    120) /
            cos(phi1);

    return (lat: (lat2 * 180) / pi, lon: (lon2 * 180) / pi);
  } catch (_) {
    return null;
  }
}

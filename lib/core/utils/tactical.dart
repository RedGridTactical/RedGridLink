/// tactical.dart — Pure math utilities for tactical land navigation tools.
///
/// No external dependencies. No network. No storage.

import 'dart:math';

import 'package:red_grid_link/core/utils/mgrs.dart';

const double deg = pi / 180;
const double rad = 180 / pi;

// --- BACK AZIMUTH ---

/// Returns the back azimuth (reciprocal bearing) in degrees 0-360.
double backAzimuth(double bearing) {
  return (bearing + 180) % 360;
}

// --- DEAD RECKONING ---

/// From a known position, compute new position after traveling
/// [distanceM] meters on [headingDeg] (true/grid north).
///
/// Returns `({double lat, double lon, String mgrs, String mgrsFormatted})?`
/// or null if inputs are invalid.
({double lat, double lon, String mgrs, String mgrsFormatted})? deadReckoning(
    double startLat, double startLon, double headingDeg, double distanceM) {
  if (!distanceM.isFinite || distanceM < 0) return null;

  const double R = 6371000; // Earth radius metres
  final double delta = distanceM / R;
  final double theta = headingDeg * deg;
  final double phi1 = startLat * deg;
  final double lambda1 = startLon * deg;

  final double phi2 = asin(
      sin(phi1) * cos(delta) + cos(phi1) * sin(delta) * cos(theta));
  final double lambda2 = lambda1 +
      atan2(sin(theta) * sin(delta) * cos(phi1),
          cos(delta) - sin(phi1) * sin(phi2));

  final double lat = phi2 * rad;
  final double lon = ((lambda2 * rad) + 540) % 360 - 180;
  final String mgrsStr = toMGRS(lat, lon, 5);
  return (lat: lat, lon: lon, mgrs: mgrsStr, mgrsFormatted: formatMGRS(mgrsStr));
}

// --- RESECTION ---

/// Two-point resection: given two known points (lat/lon) and the magnetic
/// bearing FROM your position TO each, compute your position.
///
/// Uses intersection of two bearing lines (forward intersection geometry).
/// Returns `({double lat, double lon, String mgrs, String mgrsFormatted})?`
/// or null if lines are parallel/coincident.
({double lat, double lon, String mgrs, String mgrsFormatted})? resection(
    double lat1,
    double lon1,
    double bearing1Deg,
    double lat2,
    double lon2,
    double bearing2Deg) {
  // Convert to radians
  final double phi1 = lat1 * deg;
  final double lambda1 = lon1 * deg;
  final double phi2 = lat2 * deg;
  final double lambda2 = lon2 * deg;
  final double theta13 = bearing1Deg * deg; // bearing from pt1 toward unknown
  final double theta23 = bearing2Deg * deg; // bearing from pt2 toward unknown

  final double dPhi = phi2 - phi1;
  final double dLambda = lambda2 - lambda1;

  final double delta12 = 2 *
      asin(sqrt(pow(sin(dPhi / 2), 2).toDouble() +
          cos(phi1) * cos(phi2) * pow(sin(dLambda / 2), 2).toDouble()));

  if (delta12.abs() < 1e-6) return null; // same point

  // Initial/final bearings between the two known points
  final double thetaA = acos(max(
      -1.0,
      min(
          1.0,
          (sin(phi2) - sin(phi1) * cos(delta12)) /
              (sin(delta12) * cos(phi1)))));
  final double thetaB = acos(max(
      -1.0,
      min(
          1.0,
          (sin(phi1) - sin(phi2) * cos(delta12)) /
              (sin(delta12) * cos(phi2)))));

  final double theta12 =
      sin(lambda2 - lambda1) > 0 ? thetaA : (2 * pi - thetaA);
  final double theta21 =
      sin(lambda2 - lambda1) > 0 ? (2 * pi - thetaB) : thetaB;

  final double alpha1 = theta13 - theta12; // angle at pt1
  final double alpha2 = theta21 - theta23; // angle at pt2
  final double alpha3 = acos(max(
      -1.0,
      min(
          1.0,
          -cos(alpha1) * cos(alpha2) +
              sin(alpha1) * sin(alpha2) * cos(delta12))));

  final double delta13 = atan2(
      sin(delta12) * sin(alpha1) * sin(alpha2),
      cos(alpha2) + cos(alpha1) * cos(alpha3));

  final double phi3 = asin(
      sin(phi1) * cos(delta13) + cos(phi1) * sin(delta13) * cos(theta13));
  final double lambda3 = lambda1 +
      atan2(sin(theta13) * sin(delta13) * cos(phi1),
          cos(delta13) - sin(phi1) * sin(phi3));

  final double latResult = phi3 * rad;
  final double lonResult = ((lambda3 * rad) + 540) % 360 - 180;

  if (latResult.isNaN || lonResult.isNaN) return null;

  final String mgrsStr = toMGRS(latResult, lonResult, 5);
  return (
    lat: latResult,
    lon: lonResult,
    mgrs: mgrsStr,
    mgrsFormatted: formatMGRS(mgrsStr)
  );
}

// --- PACE COUNT ---

/// Convert total paces to distance in metres.
///
/// [pacesPerHundredMeters]: user-calibrated (typical: 62-66 for adult male).
double pacesToDistance(double paces, double pacesPerHundredMeters) {
  return (paces / pacesPerHundredMeters) * 100;
}

/// Convert distance in metres to paces.
int distanceToPaces(double meters, double pacesPerHundredMeters) {
  return ((meters / 100) * pacesPerHundredMeters).round();
}

// --- MAGNETIC DECLINATION ---

/// Apply declination correction to a magnetic bearing.
///
/// [declinationDeg]: positive = east, negative = west.
/// Returns grid/true bearing (0-360).
double applyDeclination(double magneticBearing, double declinationDeg) {
  return ((magneticBearing + declinationDeg) + 360) % 360;
}

/// Remove declination correction from a true bearing.
///
/// Returns magnetic bearing (0-360).
double removeDeclination(double trueBearing, double declinationDeg) {
  return ((trueBearing - declinationDeg) + 360) % 360;
}

// --- TIME-DISTANCE-SPEED ---

/// Given distance (m) and speed (km/h), returns travel time in minutes.
double? timeToTravel(double distanceM, double speedKmh) {
  if (speedKmh <= 0) return null;
  return (distanceM / 1000 / speedKmh) * 60;
}

/// Format minutes as "Xhr Ymin" or just "Ymin".
String formatMinutes(double? mins) {
  if (mins == null || mins.isNaN) return '--';
  final int h = (mins / 60).floor();
  final int m = (mins % 60).round();
  if (h == 0) return '${m}min';
  return '${h}hr ${m}min';
}

// --- SOLAR BEARING ---

/// Compute approximate solar azimuth (bearing from north, clockwise) for a
/// given date/time and location (decimal degrees).
///
/// Accurate to ~1 degree -- sufficient for field orientation.
({double azimuth, double altitude, bool isDay}) solarBearing(
    DateTime date, double lat, double lon) {
  final double jd = dateToJD(date);
  final double n = jd - 2451545.0;
  final double L = (280.46 + 0.9856474 * n) % 360;
  final double g = ((357.528 + 0.9856003 * n) % 360) * deg;
  final double lambdaSun =
      (L + 1.915 * sin(g) + 0.020 * sin(2 * g)) * deg;
  final double epsilon = (23.439 - 0.0000004 * n) * deg;
  final double sinDec = sin(epsilon) * sin(lambdaSun);
  final double dec = asin(sinDec);

  // Hour angle
  final double ut = date.toUtc().hour +
      date.toUtc().minute / 60 +
      date.toUtc().second / 3600;
  final double gmst = (6.697375 + 0.0657098242 * n + ut) % 24;
  final double lmst = (gmst + lon / 15 + 24) % 24;
  final double ha =
      (lmst - (lambdaSun * rad / 15) + 12 + 24) % 24 - 12; // hours
  final double H = ha * 15 * deg; // radians

  final double phi = lat * deg;
  final double sinAlt =
      sin(phi) * sinDec + cos(phi) * cos(dec) * cos(H);
  final double alt = asin(sinAlt);
  final double cosAz =
      (sinDec - sin(phi) * sinAlt) / (cos(phi) * cos(alt));
  double az = acos(max(-1.0, min(1.0, cosAz))) * rad;
  if (sin(H) > 0) az = 360 - az;

  final double altDeg = alt * rad;
  return (azimuth: az, altitude: altDeg, isDay: altDeg > -0.833);
}

// --- LUNAR BEARING ---

/// Compute approximate lunar azimuth.
({double azimuth, double altitude, bool isUp}) lunarBearing(
    DateTime date, double lat, double lon) {
  final double jd = dateToJD(date);
  final double n = jd - 2451545.0;
  // Simplified lunar position
  final double L = (218.316 + 13.176396 * n) % 360;
  final double M = ((134.963 + 13.064993 * n) % 360) * deg;
  final double F = ((93.272 + 13.229350 * n) % 360) * deg;
  final double lambda = (L + 6.289 * sin(M)) * deg;
  final double beta = (5.128 * sin(F)) * deg;
  final double epsilon = (23.439 - 0.0000004 * n) * deg;

  final double sinDec = sin(epsilon) * sin(lambda) * cos(beta) +
      cos(epsilon) * sin(beta);
  final double dec = asin(sinDec);

  final double ut = date.toUtc().hour + date.toUtc().minute / 60.0;
  final double gmst = (6.697375 + 0.0657098242 * n + ut) % 24;
  final double lmst = (gmst + lon / 15 + 24) % 24;
  final double ra = atan2(
          cos(epsilon) * sin(lambda) * cos(beta) - sin(epsilon) * sin(beta),
          cos(lambda) * cos(beta)) *
      rad /
      15;
  final double ha = (lmst - (ra + 24)) % 24;
  final double H = ha * 15 * deg;

  final double phi = lat * deg;
  final double sinAlt =
      sin(phi) * sinDec + cos(phi) * cos(dec) * cos(H);
  final double alt = asin(sinAlt);
  final double cosAz =
      (sinDec - sin(phi) * sinAlt) / (cos(phi) * cos(alt));
  double az = acos(max(-1.0, min(1.0, cosAz))) * rad;
  if (sin(H) > 0) az = 360 - az;

  return (azimuth: az, altitude: alt * rad, isUp: alt * rad > 0);
}

/// Convert a DateTime to Julian Date.
double dateToJD(DateTime date) {
  return date.millisecondsSinceEpoch / 86400000 + 2440587.5;
}

// --- RANGE ESTIMATION ---

/// Estimate range to target using the mil-relation formula.
///
/// Military mil-relation: Range = objectSize × 1000 / angularSize
/// One mil subtends 1 metre at 1000 metres distance.
///
/// [objectSizeMeters]: known height/width of target in metres.
/// [angularSizeMils]: apparent size through optics in mils.
/// Returns estimated range in metres, or null for invalid inputs.
double? estimateRange(
    {required double objectSizeMeters, required double angularSizeMils}) {
  if (angularSizeMils <= 0 || !angularSizeMils.isFinite) return null;
  if (objectSizeMeters <= 0 || !objectSizeMeters.isFinite) return null;
  return objectSizeMeters * 1000 / angularSizeMils;
}

// --- SLOPE CALCULATOR ---

/// Calculate slope as a percentage.
///
/// [horizontalDist]: horizontal distance in metres.
/// [elevationChange]: vertical change in metres (positive = uphill).
/// Returns slope percentage, or null for invalid inputs.
double? slopePercent(
    {required double horizontalDist, required double elevationChange}) {
  if (horizontalDist <= 0 || !horizontalDist.isFinite) return null;
  if (!elevationChange.isFinite) return null;
  return (elevationChange / horizontalDist) * 100;
}

/// Calculate slope angle in degrees.
///
/// [horizontalDist]: horizontal distance in metres.
/// [elevationChange]: vertical change in metres.
/// Returns angle in degrees (0-90), or null for invalid inputs.
double? slopeAngle(
    {required double horizontalDist, required double elevationChange}) {
  if (horizontalDist <= 0 || !horizontalDist.isFinite) return null;
  if (!elevationChange.isFinite) return null;
  return atan2(elevationChange.abs(), horizontalDist) * rad;
}

// --- MGRS PRECISION ---

/// Labels describing MGRS grid precision levels.
const Map<int, String> precisionLabels = {
  1: '10km (2-digit)',
  2: '1km  (4-digit)',
  3: '100m (6-digit)',
  4: '10m  (8-digit)',
  5: '1m  (10-digit)',
};

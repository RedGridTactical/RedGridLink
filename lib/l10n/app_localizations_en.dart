// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'MAP';

  @override
  String get tabGrid => 'GRID';

  @override
  String get tabLink => 'LINK';

  @override
  String get tabTools => 'TOOLS';

  @override
  String get tabSettings => 'SETTINGS';

  @override
  String get waitingForGps => 'Waiting for GPS fix...';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get reconnecting => 'Reconnecting';

  @override
  String get scanning => 'Scanning';

  @override
  String get expedition => 'EXPEDITION';

  @override
  String get ultraExpedition => 'ULTRA EXP';

  @override
  String get active => 'ACTIVE';

  @override
  String get offlineMaps => 'OFFLINE MAPS';

  @override
  String get downloadCurrentView => 'DOWNLOAD CURRENT VIEW';

  @override
  String get download => 'DOWNLOAD';

  @override
  String get downloadedRegions => 'DOWNLOADED REGIONS';

  @override
  String get noOfflineRegions => 'No offline regions downloaded.';

  @override
  String get createSession => 'CREATE SESSION';

  @override
  String get joinSession => 'JOIN SESSION';

  @override
  String get leaveSession => 'LEAVE SESSION';

  @override
  String get close => 'CLOSE';

  @override
  String get cancel => 'CANCEL';

  @override
  String get confirm => 'CONFIRM';

  @override
  String get delete => 'DELETE';

  @override
  String get save => 'SAVE';

  @override
  String get settings => 'SETTINGS';

  @override
  String get theme => 'THEME';

  @override
  String get mode => 'MODE';

  @override
  String get about => 'ABOUT';

  @override
  String get tools => 'TOOLS';

  @override
  String get deadReckoning => 'Dead Reckoning';

  @override
  String get resection => 'Two-Point Resection';

  @override
  String get paceCount => 'Pace Count';

  @override
  String get backAzimuth => 'Back Azimuth';

  @override
  String get coordinateConverter => 'Coordinate Converter';

  @override
  String get rangeEstimation => 'Range Estimation';

  @override
  String get slopeCalculator => 'Slope Calculator';

  @override
  String get etaSpeed => 'ETA / Speed';

  @override
  String get declination => 'Declination';

  @override
  String get celestialNav => 'Celestial Nav';

  @override
  String get mgrsReference => 'MGRS Reference';

  @override
  String get teamRoster => 'TEAM ROSTER';

  @override
  String get roleLead => 'Lead';

  @override
  String get roleScout => 'Scout';

  @override
  String get roleMedic => 'Medic';

  @override
  String get roleComms => 'Comms';

  @override
  String get roleCustom => 'Custom';

  @override
  String get changeRole => 'CHANGE ROLE';

  @override
  String get promoteToLead => 'PROMOTE TO LEAD';

  @override
  String get saveToMyWaypoints => 'SAVE TO MY WAYPOINTS';

  @override
  String get shareWithTeam => 'SHARE WITH TEAM';

  @override
  String get setBoundary => 'SET BOUNDARY';

  @override
  String get boundaryAlert => 'BOUNDARY ALERT';

  @override
  String get youLeftBoundary => 'You left the team boundary';

  @override
  String peerLeftBoundary(String callsign) {
    return '$callsign left the boundary';
  }

  @override
  String get voiceCallouts => 'Voice Callouts';

  @override
  String get voiceCalloutsSubtitle => 'NATO phonetic position updates';

  @override
  String get exportSession => 'EXPORT SESSION';

  @override
  String get importSession => 'IMPORT SESSION';

  @override
  String get sessionHistory => 'SESSION HISTORY';

  @override
  String get deleteAnnotation => 'Delete annotation?';

  @override
  String get waypointName => 'Waypoint Name';

  @override
  String get undo => 'UNDO';

  @override
  String get done => 'DONE';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'KORT';

  @override
  String get tabGrid => 'GITTER';

  @override
  String get tabLink => 'LINK';

  @override
  String get tabTools => 'VÆRKTØJ';

  @override
  String get tabSettings => 'INDST';

  @override
  String get waitingForGps => 'Venter på GPS-signal...';

  @override
  String get connected => 'Forbundet';

  @override
  String get disconnected => 'Afbrudt';

  @override
  String get reconnecting => 'Genopretter forbindelse';

  @override
  String get scanning => 'Søger';

  @override
  String get expedition => 'EKSPEDITION';

  @override
  String get ultraExpedition => 'ULTRA EKSP';

  @override
  String get active => 'AKTIV';

  @override
  String get offlineMaps => 'OFFLINE KORT';

  @override
  String get downloadCurrentView => 'DOWNLOAD AKTUEL VISNING';

  @override
  String get download => 'DOWNLOAD';

  @override
  String get downloadedRegions => 'DOWNLOADEDE REGIONER';

  @override
  String get noOfflineRegions => 'Ingen offline regioner downloadet.';

  @override
  String get createSession => 'OPRET SESSION';

  @override
  String get joinSession => 'DELTAG I SESSION';

  @override
  String get leaveSession => 'FORLAD SESSION';

  @override
  String get close => 'LUK';

  @override
  String get cancel => 'ANNULLER';

  @override
  String get confirm => 'BEKRÆFT';

  @override
  String get delete => 'SLET';

  @override
  String get save => 'GEM';

  @override
  String get settings => 'INDSTILLINGER';

  @override
  String get theme => 'TEMA';

  @override
  String get mode => 'TILSTAND';

  @override
  String get about => 'OM';

  @override
  String get tools => 'VÆRKTØJER';

  @override
  String get deadReckoning => 'Bestiknavigation';

  @override
  String get resection => 'Topunkts tilbageskæring';

  @override
  String get paceCount => 'Skridttæller';

  @override
  String get backAzimuth => 'Tilbageazimut';

  @override
  String get coordinateConverter => 'Koordinatomregner';

  @override
  String get rangeEstimation => 'Afstandsvurdering';

  @override
  String get slopeCalculator => 'Hældningsberegner';

  @override
  String get etaSpeed => 'ETA / Hastighed';

  @override
  String get declination => 'Deklination';

  @override
  String get celestialNav => 'Astronomisk navigation';

  @override
  String get mgrsReference => 'MGRS-reference';

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

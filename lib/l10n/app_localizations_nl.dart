// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'KAART';

  @override
  String get tabGrid => 'RASTER';

  @override
  String get tabLink => 'LINK';

  @override
  String get tabTools => 'TOOLS';

  @override
  String get tabSettings => 'INST';

  @override
  String get waitingForGps => 'Wachten op GPS-signaal...';

  @override
  String get connected => 'Verbonden';

  @override
  String get disconnected => 'Niet verbonden';

  @override
  String get reconnecting => 'Opnieuw verbinden';

  @override
  String get scanning => 'Scannen';

  @override
  String get expedition => 'EXPEDITIE';

  @override
  String get ultraExpedition => 'ULTRA EXP';

  @override
  String get active => 'ACTIEF';

  @override
  String get offlineMaps => 'OFFLINE KAARTEN';

  @override
  String get downloadCurrentView => 'HUIDIGE WEERGAVE DOWNLOADEN';

  @override
  String get download => 'DOWNLOADEN';

  @override
  String get downloadedRegions => 'GEDOWNLOADE REGIO\'S';

  @override
  String get noOfflineRegions => 'Geen offline regio\'s gedownload.';

  @override
  String get createSession => 'SESSIE AANMAKEN';

  @override
  String get joinSession => 'SESSIE DEELNEMEN';

  @override
  String get leaveSession => 'SESSIE VERLATEN';

  @override
  String get close => 'SLUITEN';

  @override
  String get cancel => 'ANNULEREN';

  @override
  String get confirm => 'BEVESTIGEN';

  @override
  String get delete => 'VERWIJDEREN';

  @override
  String get save => 'OPSLAAN';

  @override
  String get settings => 'INSTELLINGEN';

  @override
  String get theme => 'THEMA';

  @override
  String get mode => 'MODUS';

  @override
  String get about => 'OVER';

  @override
  String get tools => 'GEREEDSCHAPPEN';

  @override
  String get deadReckoning => 'Gegist bestek';

  @override
  String get resection => 'Tweepunts terugwaartse insnijding';

  @override
  String get paceCount => 'Stappenteller';

  @override
  String get backAzimuth => 'Terug-azimut';

  @override
  String get coordinateConverter => 'Coordinatenomzetter';

  @override
  String get rangeEstimation => 'Afstandsschatting';

  @override
  String get slopeCalculator => 'Hellingcalculator';

  @override
  String get etaSpeed => 'ETA / Snelheid';

  @override
  String get declination => 'Declinatie';

  @override
  String get celestialNav => 'Hemelnavigatie';

  @override
  String get mgrsReference => 'MGRS-referentie';

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

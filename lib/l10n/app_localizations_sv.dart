// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'KARTA';

  @override
  String get tabGrid => 'RUTNÄT';

  @override
  String get tabLink => 'LÄNK';

  @override
  String get tabTools => 'VERKTYG';

  @override
  String get tabSettings => 'INST';

  @override
  String get waitingForGps => 'Väntar på GPS-signal...';

  @override
  String get connected => 'Ansluten';

  @override
  String get disconnected => 'Frånkopplad';

  @override
  String get reconnecting => 'Återansluter';

  @override
  String get scanning => 'Söker';

  @override
  String get expedition => 'EXPEDITION';

  @override
  String get ultraExpedition => 'ULTRA EXP';

  @override
  String get active => 'AKTIV';

  @override
  String get offlineMaps => 'OFFLINEKARTOR';

  @override
  String get downloadCurrentView => 'LADDA NER AKTUELL VY';

  @override
  String get download => 'LADDA NER';

  @override
  String get downloadedRegions => 'NEDLADDADE REGIONER';

  @override
  String get noOfflineRegions => 'Inga offlineregioner nedladdade.';

  @override
  String get createSession => 'SKAPA SESSION';

  @override
  String get joinSession => 'GÅ MED I SESSION';

  @override
  String get leaveSession => 'LÄMNA SESSION';

  @override
  String get close => 'STÄNG';

  @override
  String get cancel => 'AVBRYT';

  @override
  String get confirm => 'BEKRÄFTA';

  @override
  String get delete => 'RADERA';

  @override
  String get save => 'SPARA';

  @override
  String get settings => 'INSTÄLLNINGAR';

  @override
  String get theme => 'TEMA';

  @override
  String get mode => 'LÄGE';

  @override
  String get about => 'OM';

  @override
  String get tools => 'VERKTYG';

  @override
  String get deadReckoning => 'Besticknavigering';

  @override
  String get resection => 'Tvåpunkts bakåtskärning';

  @override
  String get paceCount => 'Stegräknare';

  @override
  String get backAzimuth => 'Bakåtazimut';

  @override
  String get coordinateConverter => 'Koordinatomvandlare';

  @override
  String get rangeEstimation => 'Avståndsbedömning';

  @override
  String get slopeCalculator => 'Lutningskalkylator';

  @override
  String get etaSpeed => 'ETA / Hastighet';

  @override
  String get declination => 'Deklination';

  @override
  String get celestialNav => 'Astronomisk navigering';

  @override
  String get mgrsReference => 'MGRS-referens';

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

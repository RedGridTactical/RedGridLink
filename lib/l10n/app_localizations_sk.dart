// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'MAPA';

  @override
  String get tabGrid => 'MRIEŽKA';

  @override
  String get tabLink => 'SPOJENIE';

  @override
  String get tabTools => 'NÁSTROJE';

  @override
  String get tabSettings => 'NASTAV';

  @override
  String get waitingForGps => 'Čakanie na signál GPS...';

  @override
  String get connected => 'Pripojené';

  @override
  String get disconnected => 'Odpojené';

  @override
  String get reconnecting => 'Opätovné pripájanie';

  @override
  String get scanning => 'Skenovanie';

  @override
  String get expedition => 'EXPEDÍCIA';

  @override
  String get ultraExpedition => 'ULTRA EXP';

  @override
  String get active => 'AKTÍVNE';

  @override
  String get offlineMaps => 'OFFLINE MAPY';

  @override
  String get downloadCurrentView => 'STIAHNUŤ AKTUÁLNE ZOBRAZENIE';

  @override
  String get download => 'STIAHNUŤ';

  @override
  String get downloadedRegions => 'STIAHNUTÉ OBLASTI';

  @override
  String get noOfflineRegions => 'Žiadne offline oblasti neboli stiahnuté.';

  @override
  String get createSession => 'VYTVORIŤ RELÁCIU';

  @override
  String get joinSession => 'PRIPOJIŤ SA K RELÁCII';

  @override
  String get leaveSession => 'OPUSTIŤ RELÁCIU';

  @override
  String get close => 'ZAVRIEŤ';

  @override
  String get cancel => 'ZRUŠIŤ';

  @override
  String get confirm => 'POTVRDIŤ';

  @override
  String get delete => 'VYMAZAŤ';

  @override
  String get save => 'ULOŽIŤ';

  @override
  String get settings => 'NASTAVENIA';

  @override
  String get theme => 'MOTÍV';

  @override
  String get mode => 'REŽIM';

  @override
  String get about => 'O APLIKÁCII';

  @override
  String get tools => 'NÁSTROJE';

  @override
  String get deadReckoning => 'Navigácia odhadom';

  @override
  String get resection => 'Dvojbodová resekcia';

  @override
  String get paceCount => 'Počítadlo krokov';

  @override
  String get backAzimuth => 'Spätný azimut';

  @override
  String get coordinateConverter => 'Prevodník súradníc';

  @override
  String get rangeEstimation => 'Odhad vzdialenosti';

  @override
  String get slopeCalculator => 'Kalkulačka sklonu';

  @override
  String get etaSpeed => 'ETA / Rýchlosť';

  @override
  String get declination => 'Deklinácia';

  @override
  String get celestialNav => 'Astronomická navigácia';

  @override
  String get mgrsReference => 'MGRS referencia';

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

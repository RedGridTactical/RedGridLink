// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class AppLocalizationsNo extends AppLocalizations {
  AppLocalizationsNo([String locale = 'no']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'KART';

  @override
  String get tabGrid => 'RUTENETT';

  @override
  String get tabLink => 'LINK';

  @override
  String get tabTools => 'VERKTØY';

  @override
  String get tabSettings => 'INNST';

  @override
  String get waitingForGps => 'Venter på GPS-signal...';

  @override
  String get connected => 'Tilkoblet';

  @override
  String get disconnected => 'Frakoblet';

  @override
  String get reconnecting => 'Kobler til igjen';

  @override
  String get scanning => 'Søker';

  @override
  String get expedition => 'EKSPEDISJON';

  @override
  String get ultraExpedition => 'ULTRA EKSP';

  @override
  String get active => 'AKTIV';

  @override
  String get offlineMaps => 'FRAKOBLEDE KART';

  @override
  String get downloadCurrentView => 'LAST NED GJELDENDE VISNING';

  @override
  String get download => 'LAST NED';

  @override
  String get downloadedRegions => 'NEDLASTEDE REGIONER';

  @override
  String get noOfflineRegions => 'Ingen frakoblede regioner lastet ned.';

  @override
  String get createSession => 'OPPRETT SESJON';

  @override
  String get joinSession => 'BLI MED I SESJON';

  @override
  String get leaveSession => 'FORLAT SESJON';

  @override
  String get close => 'LUKK';

  @override
  String get cancel => 'AVBRYT';

  @override
  String get confirm => 'BEKREFT';

  @override
  String get delete => 'SLETT';

  @override
  String get save => 'LAGRE';

  @override
  String get settings => 'INNSTILLINGER';

  @override
  String get theme => 'TEMA';

  @override
  String get mode => 'MODUS';

  @override
  String get about => 'OM';

  @override
  String get tools => 'VERKTØY';

  @override
  String get deadReckoning => 'Bestikknavigasjon';

  @override
  String get resection => 'Topunkts tilbakeskjæring';

  @override
  String get paceCount => 'Skrittteller';

  @override
  String get backAzimuth => 'Tilbakeazimut';

  @override
  String get coordinateConverter => 'Koordinatomregner';

  @override
  String get rangeEstimation => 'Avstandsvurdering';

  @override
  String get slopeCalculator => 'Helningskalkulator';

  @override
  String get etaSpeed => 'ETA / Hastighet';

  @override
  String get declination => 'Deklinasjon';

  @override
  String get celestialNav => 'Astronomisk navigasjon';

  @override
  String get mgrsReference => 'MGRS-referanse';

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

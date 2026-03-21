// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'MAPA';

  @override
  String get tabGrid => 'GRAELLA';

  @override
  String get tabLink => 'ENLLAÇ';

  @override
  String get tabTools => 'EINES';

  @override
  String get tabSettings => 'CONFIG';

  @override
  String get waitingForGps => 'Esperant senyal GPS...';

  @override
  String get connected => 'Connectat';

  @override
  String get disconnected => 'Desconnectat';

  @override
  String get reconnecting => 'Reconnectant';

  @override
  String get scanning => 'Escanejant';

  @override
  String get expedition => 'EXPEDICIÓ';

  @override
  String get ultraExpedition => 'ULTRA EXP';

  @override
  String get active => 'ACTIU';

  @override
  String get offlineMaps => 'MAPES FORA DE LÍNIA';

  @override
  String get downloadCurrentView => 'DESCARREGAR VISTA ACTUAL';

  @override
  String get download => 'DESCARREGAR';

  @override
  String get downloadedRegions => 'REGIONS DESCARREGADES';

  @override
  String get noOfflineRegions =>
      'No hi ha regions fora de línia descarregades.';

  @override
  String get createSession => 'CREAR SESSIÓ';

  @override
  String get joinSession => 'UNIR-SE A SESSIÓ';

  @override
  String get leaveSession => 'SORTIR DE SESSIÓ';

  @override
  String get close => 'TANCAR';

  @override
  String get cancel => 'CANCEL·LAR';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get delete => 'ELIMINAR';

  @override
  String get save => 'DESAR';

  @override
  String get settings => 'CONFIGURACIÓ';

  @override
  String get theme => 'TEMA';

  @override
  String get mode => 'MODE';

  @override
  String get about => 'QUANT A';

  @override
  String get tools => 'EINES';

  @override
  String get deadReckoning => 'Navegació estimada';

  @override
  String get resection => 'Resecció de dos punts';

  @override
  String get paceCount => 'Comptador de passos';

  @override
  String get backAzimuth => 'Azimut invers';

  @override
  String get coordinateConverter => 'Convertidor de coordenades';

  @override
  String get rangeEstimation => 'Estimació de distància';

  @override
  String get slopeCalculator => 'Calculadora de pendent';

  @override
  String get etaSpeed => 'ETA / Velocitat';

  @override
  String get declination => 'Declinació';

  @override
  String get celestialNav => 'Navegació astronòmica';

  @override
  String get mgrsReference => 'Referència MGRS';

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

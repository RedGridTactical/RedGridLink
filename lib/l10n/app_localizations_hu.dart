// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'TÉRKÉP';

  @override
  String get tabGrid => 'RÁCS';

  @override
  String get tabLink => 'KAPCSOLAT';

  @override
  String get tabTools => 'ESZKÖZÖK';

  @override
  String get tabSettings => 'BEÁLL';

  @override
  String get waitingForGps => 'GPS jel várakozás...';

  @override
  String get connected => 'Csatlakoztatva';

  @override
  String get disconnected => 'Leválasztva';

  @override
  String get reconnecting => 'Újracsatlakozás';

  @override
  String get scanning => 'Keresés';

  @override
  String get expedition => 'EXPEDÍCIÓ';

  @override
  String get ultraExpedition => 'ULTRA EXP';

  @override
  String get active => 'AKTÍV';

  @override
  String get offlineMaps => 'OFFLINE TÉRKÉPEK';

  @override
  String get downloadCurrentView => 'JELENLEGI NÉZET LETÖLTÉSE';

  @override
  String get download => 'LETÖLTÉS';

  @override
  String get downloadedRegions => 'LETÖLTÖTT TERÜLETEK';

  @override
  String get noOfflineRegions => 'Nincsenek letöltött offline területek.';

  @override
  String get createSession => 'MUNKAMENET LÉTREHOZÁSA';

  @override
  String get joinSession => 'CSATLAKOZÁS MUNKAMENETHEZ';

  @override
  String get leaveSession => 'MUNKAMENET ELHAGYÁSA';

  @override
  String get close => 'BEZÁRÁS';

  @override
  String get cancel => 'MÉGSE';

  @override
  String get confirm => 'MEGERŐSÍTÉS';

  @override
  String get delete => 'TÖRLÉS';

  @override
  String get save => 'MENTÉS';

  @override
  String get settings => 'BEÁLLÍTÁSOK';

  @override
  String get theme => 'TÉMA';

  @override
  String get mode => 'MÓD';

  @override
  String get about => 'NÉVJEGY';

  @override
  String get tools => 'ESZKÖZÖK';

  @override
  String get deadReckoning => 'Holtjáték-navigáció';

  @override
  String get resection => 'Kétpontos hátrametszés';

  @override
  String get paceCount => 'Lépésszámláló';

  @override
  String get backAzimuth => 'Visszairány azimut';

  @override
  String get coordinateConverter => 'Koordináta-átváltó';

  @override
  String get rangeEstimation => 'Távolságbecslés';

  @override
  String get slopeCalculator => 'Lejtőszámító';

  @override
  String get etaSpeed => 'ETA / Sebesség';

  @override
  String get declination => 'Deklináció';

  @override
  String get celestialNav => 'Csillagászati navigáció';

  @override
  String get mgrsReference => 'MGRS hivatkozás';

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

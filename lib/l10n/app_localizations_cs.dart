// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'MAPA';

  @override
  String get tabGrid => 'MŘÍŽKA';

  @override
  String get tabLink => 'SPOJENÍ';

  @override
  String get tabTools => 'NÁSTROJE';

  @override
  String get tabSettings => 'NASTAV';

  @override
  String get waitingForGps => 'Čekání na signál GPS...';

  @override
  String get connected => 'Připojeno';

  @override
  String get disconnected => 'Odpojeno';

  @override
  String get reconnecting => 'Opětovné připojování';

  @override
  String get scanning => 'Skenování';

  @override
  String get expedition => 'EXPEDICE';

  @override
  String get ultraExpedition => 'ULTRA EXP';

  @override
  String get active => 'AKTIVNÍ';

  @override
  String get offlineMaps => 'OFFLINE MAPY';

  @override
  String get downloadCurrentView => 'STÁHNOUT AKTUÁLNÍ ZOBRAZENÍ';

  @override
  String get download => 'STÁHNOUT';

  @override
  String get downloadedRegions => 'STAŽENÉ OBLASTI';

  @override
  String get noOfflineRegions => 'Žádné offline oblasti nebyly staženy.';

  @override
  String get createSession => 'VYTVOŘIT RELACI';

  @override
  String get joinSession => 'PŘIPOJIT SE K RELACI';

  @override
  String get leaveSession => 'OPUSTIT RELACI';

  @override
  String get close => 'ZAVŘÍT';

  @override
  String get cancel => 'ZRUŠIT';

  @override
  String get confirm => 'POTVRDIT';

  @override
  String get delete => 'SMAZAT';

  @override
  String get save => 'ULOŽIT';

  @override
  String get settings => 'NASTAVENÍ';

  @override
  String get theme => 'MOTIV';

  @override
  String get mode => 'REŽIM';

  @override
  String get about => 'O APLIKACI';

  @override
  String get tools => 'NÁSTROJE';

  @override
  String get deadReckoning => 'Navigace odhadem';

  @override
  String get resection => 'Dvou bodová resekce';

  @override
  String get paceCount => 'Počítadlo kroků';

  @override
  String get backAzimuth => 'Zpětný azimut';

  @override
  String get coordinateConverter => 'Převodník souřadnic';

  @override
  String get rangeEstimation => 'Odhad vzdálenosti';

  @override
  String get slopeCalculator => 'Kalkulačka sklonu';

  @override
  String get etaSpeed => 'ETA / Rychlost';

  @override
  String get declination => 'Deklinace';

  @override
  String get celestialNav => 'Astronomická navigace';

  @override
  String get mgrsReference => 'MGRS reference';

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

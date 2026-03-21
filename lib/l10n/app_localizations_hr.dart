// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'KARTA';

  @override
  String get tabGrid => 'MREŽA';

  @override
  String get tabLink => 'VEZA';

  @override
  String get tabTools => 'ALATI';

  @override
  String get tabSettings => 'POSTAV';

  @override
  String get waitingForGps => 'Čekanje GPS signala...';

  @override
  String get connected => 'Povezano';

  @override
  String get disconnected => 'Odspojeno';

  @override
  String get reconnecting => 'Ponovno povezivanje';

  @override
  String get scanning => 'Skeniranje';

  @override
  String get expedition => 'EKSPEDICIJA';

  @override
  String get ultraExpedition => 'ULTRA EKSP';

  @override
  String get active => 'AKTIVNO';

  @override
  String get offlineMaps => 'IZVANMREŽNE KARTE';

  @override
  String get downloadCurrentView => 'PREUZMI TRENUTNI PRIKAZ';

  @override
  String get download => 'PREUZMI';

  @override
  String get downloadedRegions => 'PREUZETE REGIJE';

  @override
  String get noOfflineRegions => 'Nema preuzetih izvanmrežnih regija.';

  @override
  String get createSession => 'STVORI SESIJU';

  @override
  String get joinSession => 'PRIDRUŽI SE SESIJI';

  @override
  String get leaveSession => 'NAPUSTI SESIJU';

  @override
  String get close => 'ZATVORI';

  @override
  String get cancel => 'ODUSTANI';

  @override
  String get confirm => 'POTVRDI';

  @override
  String get delete => 'OBRIŠI';

  @override
  String get save => 'SPREMI';

  @override
  String get settings => 'POSTAVKE';

  @override
  String get theme => 'TEMA';

  @override
  String get mode => 'NAČIN';

  @override
  String get about => 'O APLIKACIJI';

  @override
  String get tools => 'ALATI';

  @override
  String get deadReckoning => 'Plovidba procjenom';

  @override
  String get resection => 'Dvotočkasta resekcija';

  @override
  String get paceCount => 'Brojač koraka';

  @override
  String get backAzimuth => 'Povratni azimut';

  @override
  String get coordinateConverter => 'Pretvarač koordinata';

  @override
  String get rangeEstimation => 'Procjena udaljenosti';

  @override
  String get slopeCalculator => 'Kalkulator nagiba';

  @override
  String get etaSpeed => 'ETA / Brzina';

  @override
  String get declination => 'Deklinacija';

  @override
  String get celestialNav => 'Astronomska navigacija';

  @override
  String get mgrsReference => 'MGRS referenca';

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

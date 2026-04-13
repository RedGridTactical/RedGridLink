// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'MAPA';

  @override
  String get tabGrid => 'SIATKA';

  @override
  String get tabLink => 'LACZE';

  @override
  String get tabTools => 'NARZ';

  @override
  String get tabSettings => 'USTAW';

  @override
  String get waitingForGps => 'Oczekiwanie na sygnal GPS...';

  @override
  String get connected => 'Polaczono';

  @override
  String get disconnected => 'Rozlaczono';

  @override
  String get reconnecting => 'Ponowne laczenie';

  @override
  String get scanning => 'Skanowanie';

  @override
  String get expedition => 'EKSPEDYCJA';

  @override
  String get ultraExpedition => 'ULTRA EKSP';

  @override
  String get active => 'AKTYWNY';

  @override
  String get offlineMaps => 'MAPY OFFLINE';

  @override
  String get downloadCurrentView => 'POBIERZ BIEZACY WIDOK';

  @override
  String get download => 'POBIERZ';

  @override
  String get downloadedRegions => 'POBRANE REGIONY';

  @override
  String get noOfflineRegions => 'Brak pobranych regionow offline.';

  @override
  String get createSession => 'UTWORZ SESJE';

  @override
  String get joinSession => 'DOLACZ DO SESJI';

  @override
  String get leaveSession => 'OPUSC SESJE';

  @override
  String get close => 'ZAMKNIJ';

  @override
  String get cancel => 'ANULUJ';

  @override
  String get confirm => 'POTWIERDZ';

  @override
  String get delete => 'USUN';

  @override
  String get save => 'ZAPISZ';

  @override
  String get settings => 'USTAWIENIA';

  @override
  String get theme => 'MOTYW';

  @override
  String get mode => 'TRYB';

  @override
  String get about => 'O APLIKACJI';

  @override
  String get tools => 'NARZEDZIA';

  @override
  String get deadReckoning => 'Zliczanie drogi';

  @override
  String get resection => 'Wciecie wsteczne';

  @override
  String get paceCount => 'Licznik krokow';

  @override
  String get backAzimuth => 'Azymut odwrotny';

  @override
  String get coordinateConverter => 'Konwerter wspolrzednych';

  @override
  String get rangeEstimation => 'Szacowanie odleglosci';

  @override
  String get slopeCalculator => 'Kalkulator nachylenia';

  @override
  String get etaSpeed => 'ETA / Predkosc';

  @override
  String get declination => 'Deklinacja';

  @override
  String get celestialNav => 'Nawigacja astronomiczna';

  @override
  String get mgrsReference => 'Odniesienie MGRS';

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

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'KARTTA';

  @override
  String get tabGrid => 'RUUDUKKO';

  @override
  String get tabLink => 'LINKKI';

  @override
  String get tabTools => 'TYÖKALU';

  @override
  String get tabSettings => 'ASETUK';

  @override
  String get waitingForGps => 'Odotetaan GPS-signaalia...';

  @override
  String get connected => 'Yhdistetty';

  @override
  String get disconnected => 'Yhteys katkaistu';

  @override
  String get reconnecting => 'Yhdistetään uudelleen';

  @override
  String get scanning => 'Skannataan';

  @override
  String get expedition => 'RETKI';

  @override
  String get ultraExpedition => 'ULTRA RETKI';

  @override
  String get active => 'AKTIIVINEN';

  @override
  String get offlineMaps => 'OFFLINE-KARTAT';

  @override
  String get downloadCurrentView => 'LATAA NYKYINEN NÄKYMÄ';

  @override
  String get download => 'LATAA';

  @override
  String get downloadedRegions => 'LADATUT ALUEET';

  @override
  String get noOfflineRegions => 'Ei ladattuja offline-alueita.';

  @override
  String get createSession => 'LUO ISTUNTO';

  @override
  String get joinSession => 'LIITY ISTUNTOON';

  @override
  String get leaveSession => 'POISTU ISTUNNOSTA';

  @override
  String get close => 'SULJE';

  @override
  String get cancel => 'PERUUTA';

  @override
  String get confirm => 'VAHVISTA';

  @override
  String get delete => 'POISTA';

  @override
  String get save => 'TALLENNA';

  @override
  String get settings => 'ASETUKSET';

  @override
  String get theme => 'TEEMA';

  @override
  String get mode => 'TILA';

  @override
  String get about => 'TIETOJA';

  @override
  String get tools => 'TYÖKALUT';

  @override
  String get deadReckoning => 'Paikanlaskenta';

  @override
  String get resection => 'Kahden pisteen takaleikkaus';

  @override
  String get paceCount => 'Askelmittari';

  @override
  String get backAzimuth => 'Käänteisatsimuutti';

  @override
  String get coordinateConverter => 'Koordinaattimuunnin';

  @override
  String get rangeEstimation => 'Etäisyysarvio';

  @override
  String get slopeCalculator => 'Kaltevuuslaskin';

  @override
  String get etaSpeed => 'ETA / Nopeus';

  @override
  String get declination => 'Deklinaatio';

  @override
  String get celestialNav => 'Tähtitieteellinen navigointi';

  @override
  String get mgrsReference => 'MGRS-viite';

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

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'KARTE';

  @override
  String get tabGrid => 'GITTER';

  @override
  String get tabLink => 'LINK';

  @override
  String get tabTools => 'TOOLS';

  @override
  String get tabSettings => 'EINST';

  @override
  String get waitingForGps => 'Warte auf GPS-Signal...';

  @override
  String get connected => 'Verbunden';

  @override
  String get disconnected => 'Getrennt';

  @override
  String get reconnecting => 'Verbinde erneut';

  @override
  String get scanning => 'Suche';

  @override
  String get expedition => 'EXPEDITION';

  @override
  String get ultraExpedition => 'ULTRA EXP';

  @override
  String get active => 'AKTIV';

  @override
  String get offlineMaps => 'OFFLINE-KARTEN';

  @override
  String get downloadCurrentView => 'AKTUELLE ANSICHT HERUNTERLADEN';

  @override
  String get download => 'HERUNTERLADEN';

  @override
  String get downloadedRegions => 'HERUNTERGELADENE REGIONEN';

  @override
  String get noOfflineRegions => 'Keine Offline-Regionen heruntergeladen.';

  @override
  String get createSession => 'SITZUNG ERSTELLEN';

  @override
  String get joinSession => 'SITZUNG BEITRETEN';

  @override
  String get leaveSession => 'SITZUNG VERLASSEN';

  @override
  String get close => 'SCHLIESSEN';

  @override
  String get cancel => 'ABBRECHEN';

  @override
  String get confirm => 'BESTATIGEN';

  @override
  String get delete => 'LOSCHEN';

  @override
  String get save => 'SPEICHERN';

  @override
  String get settings => 'EINSTELLUNGEN';

  @override
  String get theme => 'DESIGN';

  @override
  String get mode => 'MODUS';

  @override
  String get about => 'INFO';

  @override
  String get tools => 'WERKZEUGE';

  @override
  String get deadReckoning => 'Koppelnavigation';

  @override
  String get resection => 'Zweipunkt-Ruckwartseinschnitt';

  @override
  String get paceCount => 'Schrittzahler';

  @override
  String get backAzimuth => 'Ruckwarts-Azimut';

  @override
  String get coordinateConverter => 'Koordinatenumrechner';

  @override
  String get rangeEstimation => 'Entfernungsschatzung';

  @override
  String get slopeCalculator => 'Neigungsrechner';

  @override
  String get etaSpeed => 'ETA / Geschwindigkeit';

  @override
  String get declination => 'Deklination';

  @override
  String get celestialNav => 'Astronomische Navigation';

  @override
  String get mgrsReference => 'MGRS-Referenz';

  @override
  String get teamRoster => 'TEAM';

  @override
  String get roleLead => 'Leiter';

  @override
  String get roleScout => 'Späher';

  @override
  String get roleMedic => 'Sanitäter';

  @override
  String get roleComms => 'Funk';

  @override
  String get roleCustom => 'Eigene';

  @override
  String get changeRole => 'ROLLE ÄNDERN';

  @override
  String get promoteToLead => 'ZUM LEITER BEFÖRDERN';

  @override
  String get saveToMyWaypoints => 'IN MEINEN PUNKTEN SPEICHERN';

  @override
  String get shareWithTeam => 'MIT TEAM TEILEN';

  @override
  String get setBoundary => 'GRENZE SETZEN';

  @override
  String get boundaryAlert => 'GRENZALARM';

  @override
  String get youLeftBoundary => 'Du hast die Teamgrenze verlassen';

  @override
  String peerLeftBoundary(String callsign) {
    return '$callsign hat die Grenze verlassen';
  }

  @override
  String get voiceCallouts => 'Sprachansagen';

  @override
  String get voiceCalloutsSubtitle => 'NATO-Positionsmeldungen';

  @override
  String get exportSession => 'SESSION EXPORTIEREN';

  @override
  String get importSession => 'SESSION IMPORTIEREN';

  @override
  String get sessionHistory => 'SITZUNGSVERLAUF';

  @override
  String get deleteAnnotation => 'Anmerkung löschen?';

  @override
  String get waypointName => 'Punktname';

  @override
  String get undo => 'RÜCKGÄNGIG';

  @override
  String get done => 'FERTIG';
}

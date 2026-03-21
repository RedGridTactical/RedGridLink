// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'MAPPA';

  @override
  String get tabGrid => 'GRIGLIA';

  @override
  String get tabLink => 'LINK';

  @override
  String get tabTools => 'STRUM';

  @override
  String get tabSettings => 'IMPOST';

  @override
  String get waitingForGps => 'In attesa del segnale GPS...';

  @override
  String get connected => 'Connesso';

  @override
  String get disconnected => 'Disconnesso';

  @override
  String get reconnecting => 'Riconnessione';

  @override
  String get scanning => 'Scansione';

  @override
  String get expedition => 'SPEDIZIONE';

  @override
  String get ultraExpedition => 'ULTRA SPED';

  @override
  String get active => 'ATTIVO';

  @override
  String get offlineMaps => 'MAPPE OFFLINE';

  @override
  String get downloadCurrentView => 'SCARICA VISTA ATTUALE';

  @override
  String get download => 'SCARICA';

  @override
  String get downloadedRegions => 'REGIONI SCARICATE';

  @override
  String get noOfflineRegions => 'Nessuna regione offline scaricata.';

  @override
  String get createSession => 'CREA SESSIONE';

  @override
  String get joinSession => 'UNISCITI ALLA SESSIONE';

  @override
  String get leaveSession => 'LASCIA SESSIONE';

  @override
  String get close => 'CHIUDI';

  @override
  String get cancel => 'ANNULLA';

  @override
  String get confirm => 'CONFERMA';

  @override
  String get delete => 'ELIMINA';

  @override
  String get save => 'SALVA';

  @override
  String get settings => 'IMPOSTAZIONI';

  @override
  String get theme => 'TEMA';

  @override
  String get mode => 'MODALITA';

  @override
  String get about => 'INFO';

  @override
  String get tools => 'STRUMENTI';

  @override
  String get deadReckoning => 'Navigazione Stimata';

  @override
  String get resection => 'Intersezione Inversa';

  @override
  String get paceCount => 'Contapassi';

  @override
  String get backAzimuth => 'Azimut Inverso';

  @override
  String get coordinateConverter => 'Convertitore Coordinate';

  @override
  String get rangeEstimation => 'Stima Distanza';

  @override
  String get slopeCalculator => 'Calcolatore Pendenza';

  @override
  String get etaSpeed => 'ETA / Velocita';

  @override
  String get declination => 'Declinazione';

  @override
  String get celestialNav => 'Navigazione Celeste';

  @override
  String get mgrsReference => 'Riferimento MGRS';

  @override
  String get teamRoster => 'SQUADRA';

  @override
  String get roleLead => 'Capo';

  @override
  String get roleScout => 'Esploratore';

  @override
  String get roleMedic => 'Medico';

  @override
  String get roleComms => 'Comunicazioni';

  @override
  String get roleCustom => 'Personalizzato';

  @override
  String get changeRole => 'CAMBIA RUOLO';

  @override
  String get promoteToLead => 'PROMUOVI A CAPO';

  @override
  String get saveToMyWaypoints => 'SALVA NEI MIEI PUNTI';

  @override
  String get shareWithTeam => 'CONDIVIDI CON SQUADRA';

  @override
  String get setBoundary => 'IMPOSTA CONFINE';

  @override
  String get boundaryAlert => 'ALLERTA CONFINE';

  @override
  String get youLeftBoundary => 'Hai lasciato il confine della squadra';

  @override
  String peerLeftBoundary(String callsign) {
    return '$callsign ha lasciato il confine';
  }

  @override
  String get voiceCallouts => 'Annunci vocali';

  @override
  String get voiceCalloutsSubtitle => 'Aggiornamenti posizione NATO';

  @override
  String get exportSession => 'ESPORTA SESSIONE';

  @override
  String get importSession => 'IMPORTA SESSIONE';

  @override
  String get sessionHistory => 'CRONOLOGIA SESSIONI';

  @override
  String get deleteAnnotation => 'Eliminare annotazione?';

  @override
  String get waypointName => 'Nome punto';

  @override
  String get undo => 'ANNULLA';

  @override
  String get done => 'FATTO';
}

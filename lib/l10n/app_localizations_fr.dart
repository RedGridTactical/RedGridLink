// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'CARTE';

  @override
  String get tabGrid => 'GRILLE';

  @override
  String get tabLink => 'LIEN';

  @override
  String get tabTools => 'OUTILS';

  @override
  String get tabSettings => 'PARAM';

  @override
  String get waitingForGps => 'En attente du signal GPS...';

  @override
  String get connected => 'Connecte';

  @override
  String get disconnected => 'Deconnecte';

  @override
  String get reconnecting => 'Reconnexion';

  @override
  String get scanning => 'Recherche';

  @override
  String get expedition => 'EXPEDITION';

  @override
  String get ultraExpedition => 'ULTRA EXP';

  @override
  String get active => 'ACTIF';

  @override
  String get offlineMaps => 'CARTES HORS LIGNE';

  @override
  String get downloadCurrentView => 'TELECHARGER LA VUE ACTUELLE';

  @override
  String get download => 'TELECHARGER';

  @override
  String get downloadedRegions => 'REGIONS TELECHARGEES';

  @override
  String get noOfflineRegions => 'Aucune region hors ligne telechargee.';

  @override
  String get createSession => 'CREER UNE SESSION';

  @override
  String get joinSession => 'REJOINDRE UNE SESSION';

  @override
  String get leaveSession => 'QUITTER LA SESSION';

  @override
  String get close => 'FERMER';

  @override
  String get cancel => 'ANNULER';

  @override
  String get confirm => 'CONFIRMER';

  @override
  String get delete => 'SUPPRIMER';

  @override
  String get save => 'ENREGISTRER';

  @override
  String get settings => 'PARAMETRES';

  @override
  String get theme => 'THEME';

  @override
  String get mode => 'MODE';

  @override
  String get about => 'A PROPOS';

  @override
  String get tools => 'OUTILS';

  @override
  String get deadReckoning => 'Navigation a l\'estime';

  @override
  String get resection => 'Relevement a deux points';

  @override
  String get paceCount => 'Compteur de pas';

  @override
  String get backAzimuth => 'Azimut inverse';

  @override
  String get coordinateConverter => 'Convertisseur de coordonnees';

  @override
  String get rangeEstimation => 'Estimation de distance';

  @override
  String get slopeCalculator => 'Calculateur de pente';

  @override
  String get etaSpeed => 'ETA / Vitesse';

  @override
  String get declination => 'Declinaison';

  @override
  String get celestialNav => 'Navigation celeste';

  @override
  String get mgrsReference => 'Reference MGRS';

  @override
  String get teamRoster => 'ÉQUIPE';

  @override
  String get roleLead => 'Chef';

  @override
  String get roleScout => 'Éclaireur';

  @override
  String get roleMedic => 'Médecin';

  @override
  String get roleComms => 'Comms';

  @override
  String get roleCustom => 'Personnalisé';

  @override
  String get changeRole => 'CHANGER RÔLE';

  @override
  String get promoteToLead => 'PROMOUVOIR CHEF';

  @override
  String get saveToMyWaypoints => 'ENREGISTRER DANS MES POINTS';

  @override
  String get shareWithTeam => 'PARTAGER AVEC L\'ÉQUIPE';

  @override
  String get setBoundary => 'DÉFINIR LIMITE';

  @override
  String get boundaryAlert => 'ALERTE DE LIMITE';

  @override
  String get youLeftBoundary => 'Vous avez quitté la limite d\'équipe';

  @override
  String peerLeftBoundary(String callsign) {
    return '$callsign a quitté la limite';
  }

  @override
  String get voiceCallouts => 'Appels vocaux';

  @override
  String get voiceCalloutsSubtitle => 'Mises à jour de position OTAN';

  @override
  String get exportSession => 'EXPORTER SESSION';

  @override
  String get importSession => 'IMPORTER SESSION';

  @override
  String get sessionHistory => 'HISTORIQUE DES SESSIONS';

  @override
  String get deleteAnnotation => 'Supprimer l\'annotation ?';

  @override
  String get waypointName => 'Nom du point';

  @override
  String get undo => 'ANNULER';

  @override
  String get done => 'TERMINÉ';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'ΧΑΡΤΗΣ';

  @override
  String get tabGrid => 'ΠΛΕΓΜΑ';

  @override
  String get tabLink => 'ΣΥΝΔΕΣΗ';

  @override
  String get tabTools => 'ΕΡΓΑΛΕΙΑ';

  @override
  String get tabSettings => 'ΡΥΘΜΙΣ';

  @override
  String get waitingForGps => 'Αναμονή σήματος GPS...';

  @override
  String get connected => 'Συνδεδεμένο';

  @override
  String get disconnected => 'Αποσυνδεδεμένο';

  @override
  String get reconnecting => 'Επανασύνδεση';

  @override
  String get scanning => 'Σάρωση';

  @override
  String get expedition => 'ΑΠΟΣΤΟΛΗ';

  @override
  String get ultraExpedition => 'ULTRA ΑΠΟΣΤ';

  @override
  String get active => 'ΕΝΕΡΓΟ';

  @override
  String get offlineMaps => 'ΧΑΡΤΕΣ ΕΚΤΟΣ ΣΥΝΔΕΣΗΣ';

  @override
  String get downloadCurrentView => 'ΛΗΨΗ ΤΡΕΧΟΥΣΑΣ ΠΡΟΒΟΛΗΣ';

  @override
  String get download => 'ΛΗΨΗ';

  @override
  String get downloadedRegions => 'ΛΗΦΘΕΙΣΕΣ ΠΕΡΙΟΧΕΣ';

  @override
  String get noOfflineRegions => 'Δεν έχουν ληφθεί περιοχές εκτός σύνδεσης.';

  @override
  String get createSession => 'ΔΗΜΙΟΥΡΓΙΑ ΣΥΝΕΔΡΙΑΣ';

  @override
  String get joinSession => 'ΣΥΜΜΕΤΟΧΗ ΣΕ ΣΥΝΕΔΡΙΑ';

  @override
  String get leaveSession => 'ΑΠΟΧΩΡΗΣΗ ΑΠΟ ΣΥΝΕΔΡΙΑ';

  @override
  String get close => 'ΚΛΕΙΣΙΜΟ';

  @override
  String get cancel => 'ΑΚΥΡΩΣΗ';

  @override
  String get confirm => 'ΕΠΙΒΕΒΑΙΩΣΗ';

  @override
  String get delete => 'ΔΙΑΓΡΑΦΗ';

  @override
  String get save => 'ΑΠΟΘΗΚΕΥΣΗ';

  @override
  String get settings => 'ΡΥΘΜΙΣΕΙΣ';

  @override
  String get theme => 'ΘΕΜΑ';

  @override
  String get mode => 'ΛΕΙΤΟΥΡΓΙΑ';

  @override
  String get about => 'ΣΧΕΤΙΚΑ';

  @override
  String get tools => 'ΕΡΓΑΛΕΙΑ';

  @override
  String get deadReckoning => 'Πλοήγηση εκτίμησης';

  @override
  String get resection => 'Αντιτομή δύο σημείων';

  @override
  String get paceCount => 'Μετρητής βημάτων';

  @override
  String get backAzimuth => 'Αντίστροφο αζιμούθιο';

  @override
  String get coordinateConverter => 'Μετατροπέας συντεταγμένων';

  @override
  String get rangeEstimation => 'Εκτίμηση απόστασης';

  @override
  String get slopeCalculator => 'Υπολογιστής κλίσης';

  @override
  String get etaSpeed => 'ETA / Ταχύτητα';

  @override
  String get declination => 'Μαγνητική απόκλιση';

  @override
  String get celestialNav => 'Αστρονομική πλοήγηση';

  @override
  String get mgrsReference => 'Αναφορά MGRS';

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

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'מפה';

  @override
  String get tabGrid => 'רשת';

  @override
  String get tabLink => 'קישור';

  @override
  String get tabTools => 'כלים';

  @override
  String get tabSettings => 'הגדרות';

  @override
  String get waitingForGps => 'ממתין לאות GPS...';

  @override
  String get connected => 'מחובר';

  @override
  String get disconnected => 'מנותק';

  @override
  String get reconnecting => 'מתחבר מחדש';

  @override
  String get scanning => 'סורק';

  @override
  String get expedition => 'משלחת';

  @override
  String get ultraExpedition => 'אולטרה משלחת';

  @override
  String get active => 'פעיל';

  @override
  String get offlineMaps => 'מפות לא מקוונות';

  @override
  String get downloadCurrentView => 'הורד תצוגה נוכחית';

  @override
  String get download => 'הורדה';

  @override
  String get downloadedRegions => 'אזורים שהורדו';

  @override
  String get noOfflineRegions => 'לא הורדו אזורים לא מקוונים.';

  @override
  String get createSession => 'צור הפעלה';

  @override
  String get joinSession => 'הצטרף להפעלה';

  @override
  String get leaveSession => 'עזוב הפעלה';

  @override
  String get close => 'סגור';

  @override
  String get cancel => 'ביטול';

  @override
  String get confirm => 'אישור';

  @override
  String get delete => 'מחק';

  @override
  String get save => 'שמור';

  @override
  String get settings => 'הגדרות';

  @override
  String get theme => 'ערכת נושא';

  @override
  String get mode => 'מצב';

  @override
  String get about => 'אודות';

  @override
  String get tools => 'כלים';

  @override
  String get deadReckoning => 'ניווט משוער';

  @override
  String get resection => 'חיתוך אחורי דו-נקודתי';

  @override
  String get paceCount => 'מונה צעדים';

  @override
  String get backAzimuth => 'אזימוט הפוך';

  @override
  String get coordinateConverter => 'ממיר קואורדינטות';

  @override
  String get rangeEstimation => 'הערכת טווח';

  @override
  String get slopeCalculator => 'מחשבון שיפוע';

  @override
  String get etaSpeed => 'ETA / מהירות';

  @override
  String get declination => 'סטיית מגנט';

  @override
  String get celestialNav => 'ניווט אסטרונומי';

  @override
  String get mgrsReference => 'ייחוס MGRS';

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

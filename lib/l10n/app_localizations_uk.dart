// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'КАРТА';

  @override
  String get tabGrid => 'СІТКА';

  @override
  String get tabLink => 'ЗВ\'ЯЗОК';

  @override
  String get tabTools => 'ІНСТРУМЕНТИ';

  @override
  String get tabSettings => 'НАЛАШТ';

  @override
  String get waitingForGps => 'Очікування сигналу GPS...';

  @override
  String get connected => 'Підключено';

  @override
  String get disconnected => 'Відключено';

  @override
  String get reconnecting => 'Перепідключення';

  @override
  String get scanning => 'Сканування';

  @override
  String get expedition => 'ЕКСПЕДИЦІЯ';

  @override
  String get ultraExpedition => 'УЛЬТРА ЕКСП';

  @override
  String get active => 'АКТИВНО';

  @override
  String get offlineMaps => 'ОФЛАЙН КАРТИ';

  @override
  String get downloadCurrentView => 'ЗАВАНТАЖИТИ ПОТОЧНИЙ ВИГЛЯД';

  @override
  String get download => 'ЗАВАНТАЖИТИ';

  @override
  String get downloadedRegions => 'ЗАВАНТАЖЕНІ РЕГІОНИ';

  @override
  String get noOfflineRegions => 'Немає завантажених офлайн регіонів.';

  @override
  String get createSession => 'СТВОРИТИ СЕАНС';

  @override
  String get joinSession => 'ПРИЄДНАТИСЯ ДО СЕАНСУ';

  @override
  String get leaveSession => 'ПОКИНУТИ СЕАНС';

  @override
  String get close => 'ЗАКРИТИ';

  @override
  String get cancel => 'СКАСУВАТИ';

  @override
  String get confirm => 'ПІДТВЕРДИТИ';

  @override
  String get delete => 'ВИДАЛИТИ';

  @override
  String get save => 'ЗБЕРЕГТИ';

  @override
  String get settings => 'НАЛАШТУВАННЯ';

  @override
  String get theme => 'ТЕМА';

  @override
  String get mode => 'РЕЖИМ';

  @override
  String get about => 'ПРО ДОДАТОК';

  @override
  String get tools => 'ІНСТРУМЕНТИ';

  @override
  String get deadReckoning => 'Зчислення шляху';

  @override
  String get resection => 'Двоточкова зворотна засічка';

  @override
  String get paceCount => 'Лічильник кроків';

  @override
  String get backAzimuth => 'Зворотний азимут';

  @override
  String get coordinateConverter => 'Конвертер координат';

  @override
  String get rangeEstimation => 'Оцінка відстані';

  @override
  String get slopeCalculator => 'Калькулятор нахилу';

  @override
  String get etaSpeed => 'ETA / Швидкість';

  @override
  String get declination => 'Магнітне схилення';

  @override
  String get celestialNav => 'Астрономічна навігація';

  @override
  String get mgrsReference => 'Довідка MGRS';

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

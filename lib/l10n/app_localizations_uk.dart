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
}

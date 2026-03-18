// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'КАРТА';

  @override
  String get tabGrid => 'СЕТКА';

  @override
  String get tabLink => 'СВЯЗЬ';

  @override
  String get tabTools => 'ИНСТР';

  @override
  String get tabSettings => 'НАСТР';

  @override
  String get waitingForGps => 'Ожидание сигнала GPS...';

  @override
  String get connected => 'Подключено';

  @override
  String get disconnected => 'Отключено';

  @override
  String get reconnecting => 'Переподключение';

  @override
  String get scanning => 'Сканирование';

  @override
  String get expedition => 'ЭКСПЕДИЦИЯ';

  @override
  String get ultraExpedition => 'УЛЬТРА ЭКСП';

  @override
  String get active => 'АКТИВНЫЙ';

  @override
  String get offlineMaps => 'ОФЛАЙН КАРТЫ';

  @override
  String get downloadCurrentView => 'СКАЧАТЬ ТЕКУЩИЙ ВИД';

  @override
  String get download => 'СКАЧАТЬ';

  @override
  String get downloadedRegions => 'СКАЧАННЫЕ РЕГИОНЫ';

  @override
  String get noOfflineRegions => 'Нет скачанных офлайн регионов.';

  @override
  String get createSession => 'СОЗДАТЬ СЕССИЮ';

  @override
  String get joinSession => 'ПРИСОЕДИНИТЬСЯ';

  @override
  String get leaveSession => 'ПОКИНУТЬ СЕССИЮ';

  @override
  String get close => 'ЗАКРЫТЬ';

  @override
  String get cancel => 'ОТМЕНА';

  @override
  String get confirm => 'ПОДТВЕРДИТЬ';

  @override
  String get delete => 'УДАЛИТЬ';

  @override
  String get save => 'СОХРАНИТЬ';

  @override
  String get settings => 'НАСТРОЙКИ';

  @override
  String get theme => 'ТЕМА';

  @override
  String get mode => 'РЕЖИМ';

  @override
  String get about => 'О ПРИЛОЖЕНИИ';

  @override
  String get tools => 'ИНСТРУМЕНТЫ';

  @override
  String get deadReckoning => 'Счисление пути';

  @override
  String get resection => 'Обратная засечка';

  @override
  String get paceCount => 'Счетчик шагов';

  @override
  String get backAzimuth => 'Обратный азимут';

  @override
  String get coordinateConverter => 'Конвертер координат';

  @override
  String get rangeEstimation => 'Оценка расстояния';

  @override
  String get slopeCalculator => 'Калькулятор уклона';

  @override
  String get etaSpeed => 'ETA / Скорость';

  @override
  String get declination => 'Склонение';

  @override
  String get celestialNav => 'Астронавигация';

  @override
  String get mgrsReference => 'Справка MGRS';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'HARITA';

  @override
  String get tabGrid => 'IZGARA';

  @override
  String get tabLink => 'BAG';

  @override
  String get tabTools => 'ARACLAR';

  @override
  String get tabSettings => 'AYARLAR';

  @override
  String get waitingForGps => 'GPS sinyali bekleniyor...';

  @override
  String get connected => 'Bagli';

  @override
  String get disconnected => 'Baglanti kesildi';

  @override
  String get reconnecting => 'Yeniden baglaniliyor';

  @override
  String get scanning => 'Taraniyor';

  @override
  String get expedition => 'KESFET';

  @override
  String get ultraExpedition => 'ULTRA KESF';

  @override
  String get active => 'AKTIF';

  @override
  String get offlineMaps => 'CEVRIMDISI HARITALAR';

  @override
  String get downloadCurrentView => 'MEVCUT GORUNUMU INDIR';

  @override
  String get download => 'INDIR';

  @override
  String get downloadedRegions => 'INDIRILEN BOLGELER';

  @override
  String get noOfflineRegions => 'Indirilmis cevrimdisi bolge yok.';

  @override
  String get createSession => 'OTURUM OLUSTUR';

  @override
  String get joinSession => 'OTURUMA KATIL';

  @override
  String get leaveSession => 'OTURUMDAN AYRIL';

  @override
  String get close => 'KAPAT';

  @override
  String get cancel => 'IPTAL';

  @override
  String get confirm => 'ONAYLA';

  @override
  String get delete => 'SIL';

  @override
  String get save => 'KAYDET';

  @override
  String get settings => 'AYARLAR';

  @override
  String get theme => 'TEMA';

  @override
  String get mode => 'MOD';

  @override
  String get about => 'HAKKINDA';

  @override
  String get tools => 'ARACLAR';

  @override
  String get deadReckoning => 'Tahmini Seyrüsefer';

  @override
  String get resection => 'Iki Noktali Geri Kesim';

  @override
  String get paceCount => 'Adim Sayaci';

  @override
  String get backAzimuth => 'Ters Azimut';

  @override
  String get coordinateConverter => 'Koordinat Donusturucu';

  @override
  String get rangeEstimation => 'Mesafe Tahmini';

  @override
  String get slopeCalculator => 'Egim Hesaplayici';

  @override
  String get etaSpeed => 'TVZ / Hiz';

  @override
  String get declination => 'Sapma';

  @override
  String get celestialNav => 'Goksel Navigasyon';

  @override
  String get mgrsReference => 'MGRS Referans';

  @override
  String get teamRoster => 'TAKIM';

  @override
  String get roleLead => 'Lider';

  @override
  String get roleScout => 'Keşif';

  @override
  String get roleMedic => 'Sağlık';

  @override
  String get roleComms => 'İletişim';

  @override
  String get roleCustom => 'Özel';

  @override
  String get changeRole => 'ROL DEĞİŞTİR';

  @override
  String get promoteToLead => 'LİDER YAP';

  @override
  String get saveToMyWaypoints => 'NOKTALARIMA KAYDET';

  @override
  String get shareWithTeam => 'TAKIMLA PAYLAŞ';

  @override
  String get setBoundary => 'SINIR BELİRLE';

  @override
  String get boundaryAlert => 'SINIR ALARMI';

  @override
  String get youLeftBoundary => 'Takım sınırını terk ettiniz';

  @override
  String peerLeftBoundary(String callsign) {
    return '$callsign sınırı terk etti';
  }

  @override
  String get voiceCallouts => 'Sesli bildirim';

  @override
  String get voiceCalloutsSubtitle => 'NATO fonetik konum güncellemeleri';

  @override
  String get exportSession => 'OTURUMU DIŞA AKTAR';

  @override
  String get importSession => 'OTURUM İÇE AKTAR';

  @override
  String get sessionHistory => 'OTURUM GEÇMİŞİ';

  @override
  String get deleteAnnotation => 'Açıklama silinsin mi?';

  @override
  String get waypointName => 'Nokta adı';

  @override
  String get undo => 'GERİ AL';

  @override
  String get done => 'BİTTİ';
}

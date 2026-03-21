// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'PETA';

  @override
  String get tabGrid => 'GRID';

  @override
  String get tabLink => 'LINK';

  @override
  String get tabTools => 'ALAT';

  @override
  String get tabSettings => 'SETELAN';

  @override
  String get waitingForGps => 'Menunggu sinyal GPS...';

  @override
  String get connected => 'Terhubung';

  @override
  String get disconnected => 'Terputus';

  @override
  String get reconnecting => 'Menghubungkan ulang';

  @override
  String get scanning => 'Memindai';

  @override
  String get expedition => 'EKSPEDISI';

  @override
  String get ultraExpedition => 'ULTRA EKSP';

  @override
  String get active => 'AKTIF';

  @override
  String get offlineMaps => 'PETA OFFLINE';

  @override
  String get downloadCurrentView => 'UNDUH TAMPILAN SAAT INI';

  @override
  String get download => 'UNDUH';

  @override
  String get downloadedRegions => 'WILAYAH TERUNDUH';

  @override
  String get noOfflineRegions => 'Tidak ada wilayah offline yang diunduh.';

  @override
  String get createSession => 'BUAT SESI';

  @override
  String get joinSession => 'GABUNG SESI';

  @override
  String get leaveSession => 'TINGGALKAN SESI';

  @override
  String get close => 'TUTUP';

  @override
  String get cancel => 'BATAL';

  @override
  String get confirm => 'KONFIRMASI';

  @override
  String get delete => 'HAPUS';

  @override
  String get save => 'SIMPAN';

  @override
  String get settings => 'PENGATURAN';

  @override
  String get theme => 'TEMA';

  @override
  String get mode => 'MODE';

  @override
  String get about => 'TENTANG';

  @override
  String get tools => 'PERALATAN';

  @override
  String get deadReckoning => 'Navigasi Perkiraan';

  @override
  String get resection => 'Reseksi Dua Titik';

  @override
  String get paceCount => 'Penghitung Langkah';

  @override
  String get backAzimuth => 'Azimut Balik';

  @override
  String get coordinateConverter => 'Konverter Koordinat';

  @override
  String get rangeEstimation => 'Estimasi Jarak';

  @override
  String get slopeCalculator => 'Kalkulator Kemiringan';

  @override
  String get etaSpeed => 'ETA / Kecepatan';

  @override
  String get declination => 'Deklinasi';

  @override
  String get celestialNav => 'Navigasi Astronomi';

  @override
  String get mgrsReference => 'Referensi MGRS';

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

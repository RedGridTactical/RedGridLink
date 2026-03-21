// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'PETA';

  @override
  String get tabGrid => 'GRID';

  @override
  String get tabLink => 'PAUTAN';

  @override
  String get tabTools => 'ALAT';

  @override
  String get tabSettings => 'TETAPAN';

  @override
  String get waitingForGps => 'Menunggu isyarat GPS...';

  @override
  String get connected => 'Disambungkan';

  @override
  String get disconnected => 'Terputus';

  @override
  String get reconnecting => 'Menyambung semula';

  @override
  String get scanning => 'Mengimbas';

  @override
  String get expedition => 'EKSPEDISI';

  @override
  String get ultraExpedition => 'ULTRA EKSP';

  @override
  String get active => 'AKTIF';

  @override
  String get offlineMaps => 'PETA LUAR TALIAN';

  @override
  String get downloadCurrentView => 'MUAT TURUN PAPARAN SEMASA';

  @override
  String get download => 'MUAT TURUN';

  @override
  String get downloadedRegions => 'KAWASAN DIMUAT TURUN';

  @override
  String get noOfflineRegions => 'Tiada kawasan luar talian dimuat turun.';

  @override
  String get createSession => 'CIPTA SESI';

  @override
  String get joinSession => 'SERTAI SESI';

  @override
  String get leaveSession => 'TINGGALKAN SESI';

  @override
  String get close => 'TUTUP';

  @override
  String get cancel => 'BATAL';

  @override
  String get confirm => 'SAHKAN';

  @override
  String get delete => 'PADAM';

  @override
  String get save => 'SIMPAN';

  @override
  String get settings => 'TETAPAN';

  @override
  String get theme => 'TEMA';

  @override
  String get mode => 'MOD';

  @override
  String get about => 'PERIHAL';

  @override
  String get tools => 'ALAT';

  @override
  String get deadReckoning => 'Pelayaran anggaran';

  @override
  String get resection => 'Reseksi dua titik';

  @override
  String get paceCount => 'Pengira langkah';

  @override
  String get backAzimuth => 'Azimut balik';

  @override
  String get coordinateConverter => 'Penukar koordinat';

  @override
  String get rangeEstimation => 'Anggaran jarak';

  @override
  String get slopeCalculator => 'Kalkulator cerun';

  @override
  String get etaSpeed => 'ETA / Kelajuan';

  @override
  String get declination => 'Deklinasi';

  @override
  String get celestialNav => 'Pelayaran astronomi';

  @override
  String get mgrsReference => 'Rujukan MGRS';

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

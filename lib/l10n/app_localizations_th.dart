// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'แผนที่';

  @override
  String get tabGrid => 'กริด';

  @override
  String get tabLink => 'ลิงก์';

  @override
  String get tabTools => 'เครื่องมือ';

  @override
  String get tabSettings => 'ตั้งค่า';

  @override
  String get waitingForGps => 'รอสัญญาณ GPS...';

  @override
  String get connected => 'เชื่อมต่อแล้ว';

  @override
  String get disconnected => 'ยกเลิกการเชื่อมต่อ';

  @override
  String get reconnecting => 'กำลังเชื่อมต่อใหม่';

  @override
  String get scanning => 'กำลังสแกน';

  @override
  String get expedition => 'สำรวจ';

  @override
  String get ultraExpedition => 'อัลตร้าสำรวจ';

  @override
  String get active => 'ใช้งาน';

  @override
  String get offlineMaps => 'แผนที่ออฟไลน์';

  @override
  String get downloadCurrentView => 'ดาวน์โหลดมุมมองปัจจุบัน';

  @override
  String get download => 'ดาวน์โหลด';

  @override
  String get downloadedRegions => 'พื้นที่ที่ดาวน์โหลดแล้ว';

  @override
  String get noOfflineRegions => 'ไม่มีพื้นที่ออฟไลน์ที่ดาวน์โหลด';

  @override
  String get createSession => 'สร้างเซสชัน';

  @override
  String get joinSession => 'เข้าร่วมเซสชัน';

  @override
  String get leaveSession => 'ออกจากเซสชัน';

  @override
  String get close => 'ปิด';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get delete => 'ลบ';

  @override
  String get save => 'บันทึก';

  @override
  String get settings => 'ตั้งค่า';

  @override
  String get theme => 'ธีม';

  @override
  String get mode => 'โหมด';

  @override
  String get about => 'เกี่ยวกับ';

  @override
  String get tools => 'เครื่องมือ';

  @override
  String get deadReckoning => 'การเดินเรือคาดคะเน';

  @override
  String get resection => 'การตัดกลับสองจุด';

  @override
  String get paceCount => 'นับก้าว';

  @override
  String get backAzimuth => 'มุมทิศย้อนกลับ';

  @override
  String get coordinateConverter => 'ตัวแปลงพิกัด';

  @override
  String get rangeEstimation => 'ประมาณระยะทาง';

  @override
  String get slopeCalculator => 'คำนวณความลาดชัน';

  @override
  String get etaSpeed => 'ETA / ความเร็ว';

  @override
  String get declination => 'ค่าเบี่ยงเบนแม่เหล็ก';

  @override
  String get celestialNav => 'การเดินเรือดาราศาสตร์';

  @override
  String get mgrsReference => 'อ้างอิง MGRS';

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

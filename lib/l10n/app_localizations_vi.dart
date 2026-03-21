// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'BẢN ĐỒ';

  @override
  String get tabGrid => 'LƯỚI';

  @override
  String get tabLink => 'LIÊN KẾT';

  @override
  String get tabTools => 'CÔNG CỤ';

  @override
  String get tabSettings => 'CÀI ĐẶT';

  @override
  String get waitingForGps => 'Đang chờ tín hiệu GPS...';

  @override
  String get connected => 'Đã kết nối';

  @override
  String get disconnected => 'Đã ngắt kết nối';

  @override
  String get reconnecting => 'Đang kết nối lại';

  @override
  String get scanning => 'Đang quét';

  @override
  String get expedition => 'THÁM HIỂM';

  @override
  String get ultraExpedition => 'SIÊU THÁM HIỂM';

  @override
  String get active => 'HOẠT ĐỘNG';

  @override
  String get offlineMaps => 'BẢN ĐỒ NGOẠI TUYẾN';

  @override
  String get downloadCurrentView => 'TẢI XUỐNG KHUNG NHÌN HIỆN TẠI';

  @override
  String get download => 'TẢI XUỐNG';

  @override
  String get downloadedRegions => 'VÙNG ĐÃ TẢI';

  @override
  String get noOfflineRegions => 'Chưa có vùng ngoại tuyến nào được tải.';

  @override
  String get createSession => 'TẠO PHIÊN';

  @override
  String get joinSession => 'THAM GIA PHIÊN';

  @override
  String get leaveSession => 'RỜI PHIÊN';

  @override
  String get close => 'ĐÓNG';

  @override
  String get cancel => 'HỦY';

  @override
  String get confirm => 'XÁC NHẬN';

  @override
  String get delete => 'XÓA';

  @override
  String get save => 'LƯU';

  @override
  String get settings => 'CÀI ĐẶT';

  @override
  String get theme => 'GIAO DIỆN';

  @override
  String get mode => 'CHẾ ĐỘ';

  @override
  String get about => 'GIỚI THIỆU';

  @override
  String get tools => 'CÔNG CỤ';

  @override
  String get deadReckoning => 'Hàng hải suy đoán';

  @override
  String get resection => 'Giao hội ngược hai điểm';

  @override
  String get paceCount => 'Đếm bước';

  @override
  String get backAzimuth => 'Phương vị ngược';

  @override
  String get coordinateConverter => 'Chuyển đổi tọa độ';

  @override
  String get rangeEstimation => 'Ước tính khoảng cách';

  @override
  String get slopeCalculator => 'Tính độ dốc';

  @override
  String get etaSpeed => 'ETA / Tốc độ';

  @override
  String get declination => 'Từ thiên';

  @override
  String get celestialNav => 'Hàng hải thiên văn';

  @override
  String get mgrsReference => 'Tham chiếu MGRS';

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

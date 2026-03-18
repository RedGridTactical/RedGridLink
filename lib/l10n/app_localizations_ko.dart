// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => '지도';

  @override
  String get tabGrid => '그리드';

  @override
  String get tabLink => '링크';

  @override
  String get tabTools => '도구';

  @override
  String get tabSettings => '설정';

  @override
  String get waitingForGps => 'GPS 신호 대기 중...';

  @override
  String get connected => '연결됨';

  @override
  String get disconnected => '연결 해제';

  @override
  String get reconnecting => '재연결 중';

  @override
  String get scanning => '스캔 중';

  @override
  String get expedition => '탐험 모드';

  @override
  String get ultraExpedition => '울트라 탐험';

  @override
  String get active => '활성';

  @override
  String get offlineMaps => '오프라인 지도';

  @override
  String get downloadCurrentView => '현재 뷰 다운로드';

  @override
  String get download => '다운로드';

  @override
  String get downloadedRegions => '다운로드된 지역';

  @override
  String get noOfflineRegions => '다운로드된 오프라인 지역이 없습니다.';

  @override
  String get createSession => '세션 생성';

  @override
  String get joinSession => '세션 참가';

  @override
  String get leaveSession => '세션 퇴장';

  @override
  String get close => '닫기';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get delete => '삭제';

  @override
  String get save => '저장';

  @override
  String get settings => '설정';

  @override
  String get theme => '테마';

  @override
  String get mode => '모드';

  @override
  String get about => '정보';

  @override
  String get tools => '도구';

  @override
  String get deadReckoning => '추측 항법';

  @override
  String get resection => '이점 교회법';

  @override
  String get paceCount => '걸음 수 계산';

  @override
  String get backAzimuth => '역방위각';

  @override
  String get coordinateConverter => '좌표 변환기';

  @override
  String get rangeEstimation => '거리 추정';

  @override
  String get slopeCalculator => '경사 계산기';

  @override
  String get etaSpeed => '도착예정/속도';

  @override
  String get declination => '자기 편각';

  @override
  String get celestialNav => '천측 항법';

  @override
  String get mgrsReference => 'MGRS 참조';
}

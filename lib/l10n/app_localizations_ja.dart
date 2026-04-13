// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'マップ';

  @override
  String get tabGrid => 'グリッド';

  @override
  String get tabLink => 'リンク';

  @override
  String get tabTools => 'ツール';

  @override
  String get tabSettings => '設定';

  @override
  String get waitingForGps => 'GPS信号を待っています...';

  @override
  String get connected => '接続済み';

  @override
  String get disconnected => '切断';

  @override
  String get reconnecting => '再接続中';

  @override
  String get scanning => 'スキャン中';

  @override
  String get expedition => '遠征モード';

  @override
  String get ultraExpedition => 'ウルトラ遠征';

  @override
  String get active => 'アクティブ';

  @override
  String get offlineMaps => 'オフラインマップ';

  @override
  String get downloadCurrentView => '現在のビューをダウンロード';

  @override
  String get download => 'ダウンロード';

  @override
  String get downloadedRegions => 'ダウンロード済みエリア';

  @override
  String get noOfflineRegions => 'オフラインエリアはダウンロードされていません。';

  @override
  String get createSession => 'セッション作成';

  @override
  String get joinSession => 'セッション参加';

  @override
  String get leaveSession => 'セッション退出';

  @override
  String get close => '閉じる';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String get settings => '設定';

  @override
  String get theme => 'テーマ';

  @override
  String get mode => 'モード';

  @override
  String get about => '情報';

  @override
  String get tools => 'ツール';

  @override
  String get deadReckoning => '推測航法';

  @override
  String get resection => '二点交会法';

  @override
  String get paceCount => '歩数カウント';

  @override
  String get backAzimuth => '逆方位角';

  @override
  String get coordinateConverter => '座標変換';

  @override
  String get rangeEstimation => '距離推定';

  @override
  String get slopeCalculator => '傾斜計算機';

  @override
  String get etaSpeed => '到着予定/速度';

  @override
  String get declination => '磁気偏角';

  @override
  String get celestialNav => '天測航法';

  @override
  String get mgrsReference => 'MGRS参照';

  @override
  String get teamRoster => 'チーム名簿';

  @override
  String get roleLead => 'リーダー';

  @override
  String get roleScout => '偵察';

  @override
  String get roleMedic => '衛生兵';

  @override
  String get roleComms => '通信';

  @override
  String get roleCustom => 'カスタム';

  @override
  String get changeRole => '役割変更';

  @override
  String get promoteToLead => 'リーダーに昇格';

  @override
  String get saveToMyWaypoints => 'マイポイントに保存';

  @override
  String get shareWithTeam => 'チームと共有';

  @override
  String get setBoundary => '境界設定';

  @override
  String get boundaryAlert => '境界アラート';

  @override
  String get youLeftBoundary => 'チーム境界を離れました';

  @override
  String peerLeftBoundary(String callsign) {
    return '$callsignが境界を離れました';
  }

  @override
  String get voiceCallouts => '音声コールアウト';

  @override
  String get voiceCalloutsSubtitle => 'NATO音声位置通知';

  @override
  String get exportSession => 'セッション出力';

  @override
  String get importSession => 'セッション取込';

  @override
  String get sessionHistory => 'セッション履歴';

  @override
  String get deleteAnnotation => '注釈を削除しますか？';

  @override
  String get waypointName => 'ポイント名';

  @override
  String get undo => '元に戻す';

  @override
  String get done => '完了';
}

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
}

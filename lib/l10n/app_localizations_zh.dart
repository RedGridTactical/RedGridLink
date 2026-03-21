// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => '地图';

  @override
  String get tabGrid => '网格';

  @override
  String get tabLink => '连接';

  @override
  String get tabTools => '工具';

  @override
  String get tabSettings => '设置';

  @override
  String get waitingForGps => '等待GPS信号...';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '已断开';

  @override
  String get reconnecting => '重新连接中';

  @override
  String get scanning => '扫描中';

  @override
  String get expedition => '远征模式';

  @override
  String get ultraExpedition => '超级远征';

  @override
  String get active => '活跃';

  @override
  String get offlineMaps => '离线地图';

  @override
  String get downloadCurrentView => '下载当前视图';

  @override
  String get download => '下载';

  @override
  String get downloadedRegions => '已下载区域';

  @override
  String get noOfflineRegions => '没有已下载的离线区域。';

  @override
  String get createSession => '创建会话';

  @override
  String get joinSession => '加入会话';

  @override
  String get leaveSession => '离开会话';

  @override
  String get close => '关闭';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

  @override
  String get settings => '设置';

  @override
  String get theme => '主题';

  @override
  String get mode => '模式';

  @override
  String get about => '关于';

  @override
  String get tools => '工具';

  @override
  String get deadReckoning => '航位推算';

  @override
  String get resection => '双点交会';

  @override
  String get paceCount => '步数计算';

  @override
  String get backAzimuth => '反方位角';

  @override
  String get coordinateConverter => '坐标转换器';

  @override
  String get rangeEstimation => '距离估算';

  @override
  String get slopeCalculator => '坡度计算器';

  @override
  String get etaSpeed => '预计到达/速度';

  @override
  String get declination => '磁偏角';

  @override
  String get celestialNav => '天文导航';

  @override
  String get mgrsReference => 'MGRS参考';

  @override
  String get teamRoster => '团队名册';

  @override
  String get roleLead => '队长';

  @override
  String get roleScout => '侦察';

  @override
  String get roleMedic => '医疗';

  @override
  String get roleComms => '通讯';

  @override
  String get roleCustom => '自定义';

  @override
  String get changeRole => '更改角色';

  @override
  String get promoteToLead => '提升为队长';

  @override
  String get saveToMyWaypoints => '保存到我的航点';

  @override
  String get shareWithTeam => '与团队共享';

  @override
  String get setBoundary => '设置边界';

  @override
  String get boundaryAlert => '边界警报';

  @override
  String get youLeftBoundary => '你已离开团队边界';

  @override
  String peerLeftBoundary(String callsign) {
    return '$callsign已离开边界';
  }

  @override
  String get voiceCallouts => '语音呼叫';

  @override
  String get voiceCalloutsSubtitle => 'NATO语音位置更新';

  @override
  String get exportSession => '导出会话';

  @override
  String get importSession => '导入会话';

  @override
  String get sessionHistory => '会话历史';

  @override
  String get deleteAnnotation => '删除标注？';

  @override
  String get waypointName => '航点名称';

  @override
  String get undo => '撤销';

  @override
  String get done => '完成';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => '地圖';

  @override
  String get tabGrid => '網格';

  @override
  String get tabLink => '連結';

  @override
  String get tabTools => '工具';

  @override
  String get tabSettings => '設定';

  @override
  String get waitingForGps => '等待GPS訊號...';

  @override
  String get connected => '已連線';

  @override
  String get disconnected => '已中斷連線';

  @override
  String get reconnecting => '重新連線中';

  @override
  String get scanning => '掃描中';

  @override
  String get expedition => '遠征';

  @override
  String get ultraExpedition => '超級遠征';

  @override
  String get active => '啟用';

  @override
  String get offlineMaps => '離線地圖';

  @override
  String get downloadCurrentView => '下載目前檢視';

  @override
  String get download => '下載';

  @override
  String get downloadedRegions => '已下載區域';

  @override
  String get noOfflineRegions => '尚未下載任何離線區域。';

  @override
  String get createSession => '建立工作階段';

  @override
  String get joinSession => '加入工作階段';

  @override
  String get leaveSession => '離開工作階段';

  @override
  String get close => '關閉';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String get delete => '刪除';

  @override
  String get save => '儲存';

  @override
  String get settings => '設定';

  @override
  String get theme => '主題';

  @override
  String get mode => '模式';

  @override
  String get about => '關於';

  @override
  String get tools => '工具';

  @override
  String get deadReckoning => '航位推算';

  @override
  String get resection => '兩點後方交會';

  @override
  String get paceCount => '步數計算';

  @override
  String get backAzimuth => '反方位角';

  @override
  String get coordinateConverter => '座標轉換器';

  @override
  String get rangeEstimation => '距離估算';

  @override
  String get slopeCalculator => '坡度計算器';

  @override
  String get etaSpeed => '預計到達/速度';

  @override
  String get declination => '磁偏角';

  @override
  String get celestialNav => '天文導航';

  @override
  String get mgrsReference => 'MGRS參考';

  @override
  String get teamRoster => '團隊名冊';

  @override
  String get roleLead => '隊長';

  @override
  String get roleScout => '偵察';

  @override
  String get roleMedic => '醫療';

  @override
  String get roleComms => '通訊';

  @override
  String get roleCustom => '自訂';

  @override
  String get changeRole => '更改角色';

  @override
  String get promoteToLead => '提升為隊長';

  @override
  String get saveToMyWaypoints => '儲存到我的航點';

  @override
  String get shareWithTeam => '與團隊共享';

  @override
  String get setBoundary => '設定邊界';

  @override
  String get boundaryAlert => '邊界警報';

  @override
  String get youLeftBoundary => '你已離開團隊邊界';

  @override
  String peerLeftBoundary(String callsign) {
    return '$callsign已離開邊界';
  }

  @override
  String get voiceCallouts => '語音呼叫';

  @override
  String get voiceCalloutsSubtitle => 'NATO語音位置更新';

  @override
  String get exportSession => '匯出會話';

  @override
  String get importSession => '匯入會話';

  @override
  String get sessionHistory => '會話歷史';

  @override
  String get deleteAnnotation => '刪除標註？';

  @override
  String get waypointName => '航點名稱';

  @override
  String get undo => '復原';

  @override
  String get done => '完成';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'मानचित्र';

  @override
  String get tabGrid => 'ग्रिड';

  @override
  String get tabLink => 'लिंक';

  @override
  String get tabTools => 'उपकरण';

  @override
  String get tabSettings => 'सेटिंग्स';

  @override
  String get waitingForGps => 'GPS सिग्नल की प्रतीक्षा...';

  @override
  String get connected => 'जुड़ा हुआ';

  @override
  String get disconnected => 'डिस्कनेक्ट';

  @override
  String get reconnecting => 'पुनः कनेक्ट हो रहा है';

  @override
  String get scanning => 'स्कैन हो रहा है';

  @override
  String get expedition => 'अभियान';

  @override
  String get ultraExpedition => 'अल्ट्रा अभियान';

  @override
  String get active => 'सक्रिय';

  @override
  String get offlineMaps => 'ऑफलाइन मानचित्र';

  @override
  String get downloadCurrentView => 'वर्तमान दृश्य डाउनलोड करें';

  @override
  String get download => 'डाउनलोड';

  @override
  String get downloadedRegions => 'डाउनलोड किए गए क्षेत्र';

  @override
  String get noOfflineRegions => 'कोई ऑफलाइन क्षेत्र डाउनलोड नहीं किया गया।';

  @override
  String get createSession => 'सत्र बनाएं';

  @override
  String get joinSession => 'सत्र में शामिल हों';

  @override
  String get leaveSession => 'सत्र छोड़ें';

  @override
  String get close => 'बंद करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get save => 'सहेजें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get theme => 'थीम';

  @override
  String get mode => 'मोड';

  @override
  String get about => 'परिचय';

  @override
  String get tools => 'उपकरण';

  @override
  String get deadReckoning => 'अनुमान नौवहन';

  @override
  String get resection => 'द्वि-बिंदु प्रतिच्छेदन';

  @override
  String get paceCount => 'कदम गणना';

  @override
  String get backAzimuth => 'विपरीत दिगंश';

  @override
  String get coordinateConverter => 'निर्देशांक परिवर्तक';

  @override
  String get rangeEstimation => 'दूरी अनुमान';

  @override
  String get slopeCalculator => 'ढलान कैलकुलेटर';

  @override
  String get etaSpeed => 'ETA / गति';

  @override
  String get declination => 'चुंबकीय विचलन';

  @override
  String get celestialNav => 'खगोलीय नौवहन';

  @override
  String get mgrsReference => 'MGRS संदर्भ';

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

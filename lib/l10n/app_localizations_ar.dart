// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'خريطة';

  @override
  String get tabGrid => 'شبكة';

  @override
  String get tabLink => 'ربط';

  @override
  String get tabTools => 'أدوات';

  @override
  String get tabSettings => 'إعدادات';

  @override
  String get waitingForGps => 'في انتظار إشارة GPS...';

  @override
  String get connected => 'متصل';

  @override
  String get disconnected => 'غير متصل';

  @override
  String get reconnecting => 'إعادة الاتصال';

  @override
  String get scanning => 'جاري البحث';

  @override
  String get expedition => 'استكشاف';

  @override
  String get ultraExpedition => 'استكشاف فائق';

  @override
  String get active => 'نشط';

  @override
  String get offlineMaps => 'خرائط بدون اتصال';

  @override
  String get downloadCurrentView => 'تحميل العرض الحالي';

  @override
  String get download => 'تحميل';

  @override
  String get downloadedRegions => 'المناطق المحملة';

  @override
  String get noOfflineRegions => 'لا توجد مناطق محملة بدون اتصال.';

  @override
  String get createSession => 'إنشاء جلسة';

  @override
  String get joinSession => 'الانضمام لجلسة';

  @override
  String get leaveSession => 'مغادرة الجلسة';

  @override
  String get close => 'إغلاق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get settings => 'الإعدادات';

  @override
  String get theme => 'المظهر';

  @override
  String get mode => 'الوضع';

  @override
  String get about => 'حول';

  @override
  String get tools => 'الأدوات';

  @override
  String get deadReckoning => 'الملاحة التقديرية';

  @override
  String get resection => 'التقاطع العكسي';

  @override
  String get paceCount => 'عداد الخطوات';

  @override
  String get backAzimuth => 'السمت العكسي';

  @override
  String get coordinateConverter => 'محول الإحداثيات';

  @override
  String get rangeEstimation => 'تقدير المسافة';

  @override
  String get slopeCalculator => 'حاسبة الميل';

  @override
  String get etaSpeed => 'الوقت / السرعة';

  @override
  String get declination => 'الانحراف المغناطيسي';

  @override
  String get celestialNav => 'ملاحة فلكية';

  @override
  String get mgrsReference => 'مرجع MGRS';

  @override
  String get teamRoster => 'قائمة الفريق';

  @override
  String get roleLead => 'قائد';

  @override
  String get roleScout => 'كشاف';

  @override
  String get roleMedic => 'مسعف';

  @override
  String get roleComms => 'اتصالات';

  @override
  String get roleCustom => 'مخصص';

  @override
  String get changeRole => 'تغيير الدور';

  @override
  String get promoteToLead => 'ترقية لقائد';

  @override
  String get saveToMyWaypoints => 'حفظ في نقاطي';

  @override
  String get shareWithTeam => 'مشاركة مع الفريق';

  @override
  String get setBoundary => 'تعيين حدود';

  @override
  String get boundaryAlert => 'تنبيه حدود';

  @override
  String get youLeftBoundary => 'لقد غادرت حدود الفريق';

  @override
  String peerLeftBoundary(String callsign) {
    return '$callsign غادر الحدود';
  }

  @override
  String get voiceCallouts => 'نداءات صوتية';

  @override
  String get voiceCalloutsSubtitle => 'تحديثات الموقع بأبجدية الناتو';

  @override
  String get exportSession => 'تصدير الجلسة';

  @override
  String get importSession => 'استيراد الجلسة';

  @override
  String get sessionHistory => 'سجل الجلسات';

  @override
  String get deleteAnnotation => 'حذف التعليق؟';

  @override
  String get waypointName => 'اسم النقطة';

  @override
  String get undo => 'تراجع';

  @override
  String get done => 'تم';
}

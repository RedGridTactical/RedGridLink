import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_ca.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('ca'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('he'),
    Locale('hi'),
    Locale('hr'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('nl'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sk'),
    Locale('sv'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// Main app title
  ///
  /// In en, this message translates to:
  /// **'RED GRID LINK'**
  String get appTitle;

  /// Map tab label
  ///
  /// In en, this message translates to:
  /// **'MAP'**
  String get tabMap;

  /// Grid tab label
  ///
  /// In en, this message translates to:
  /// **'GRID'**
  String get tabGrid;

  /// Field Link tab label
  ///
  /// In en, this message translates to:
  /// **'LINK'**
  String get tabLink;

  /// Tools tab label
  ///
  /// In en, this message translates to:
  /// **'TOOLS'**
  String get tabTools;

  /// Settings tab label
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get tabSettings;

  /// Shown when GPS position is not yet available
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS fix...'**
  String get waitingForGps;

  /// Connection status label
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Disconnection status label
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// Reconnecting status label
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get reconnecting;

  /// Scanning for peers label
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get scanning;

  /// Expedition battery mode label
  ///
  /// In en, this message translates to:
  /// **'EXPEDITION'**
  String get expedition;

  /// Ultra expedition battery mode label
  ///
  /// In en, this message translates to:
  /// **'ULTRA EXP'**
  String get ultraExpedition;

  /// Active battery mode label
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// Offline maps section title
  ///
  /// In en, this message translates to:
  /// **'OFFLINE MAPS'**
  String get offlineMaps;

  /// Download current map view button
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD CURRENT VIEW'**
  String get downloadCurrentView;

  /// Download action button
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD'**
  String get download;

  /// Downloaded regions section title
  ///
  /// In en, this message translates to:
  /// **'DOWNLOADED REGIONS'**
  String get downloadedRegions;

  /// Empty state for downloaded regions
  ///
  /// In en, this message translates to:
  /// **'No offline regions downloaded.'**
  String get noOfflineRegions;

  /// Create session button
  ///
  /// In en, this message translates to:
  /// **'CREATE SESSION'**
  String get createSession;

  /// Join session button
  ///
  /// In en, this message translates to:
  /// **'JOIN SESSION'**
  String get joinSession;

  /// Leave session button
  ///
  /// In en, this message translates to:
  /// **'LEAVE SESSION'**
  String get leaveSession;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get close;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get confirm;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get save;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// Theme section label
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get theme;

  /// Operational mode section label
  ///
  /// In en, this message translates to:
  /// **'MODE'**
  String get mode;

  /// About section label
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about;

  /// Tools screen title
  ///
  /// In en, this message translates to:
  /// **'TOOLS'**
  String get tools;

  /// Dead reckoning tool name
  ///
  /// In en, this message translates to:
  /// **'Dead Reckoning'**
  String get deadReckoning;

  /// Resection tool name
  ///
  /// In en, this message translates to:
  /// **'Two-Point Resection'**
  String get resection;

  /// Pace count tool name
  ///
  /// In en, this message translates to:
  /// **'Pace Count'**
  String get paceCount;

  /// Back azimuth tool name
  ///
  /// In en, this message translates to:
  /// **'Back Azimuth'**
  String get backAzimuth;

  /// Coordinate converter tool name
  ///
  /// In en, this message translates to:
  /// **'Coordinate Converter'**
  String get coordinateConverter;

  /// Range estimation tool name
  ///
  /// In en, this message translates to:
  /// **'Range Estimation'**
  String get rangeEstimation;

  /// Slope calculator tool name
  ///
  /// In en, this message translates to:
  /// **'Slope Calculator'**
  String get slopeCalculator;

  /// ETA speed calculator tool name
  ///
  /// In en, this message translates to:
  /// **'ETA / Speed'**
  String get etaSpeed;

  /// Magnetic declination tool name
  ///
  /// In en, this message translates to:
  /// **'Declination'**
  String get declination;

  /// Celestial navigation tool name
  ///
  /// In en, this message translates to:
  /// **'Celestial Nav'**
  String get celestialNav;

  /// MGRS precision reference tool name
  ///
  /// In en, this message translates to:
  /// **'MGRS Reference'**
  String get mgrsReference;

  /// Team roster sheet title
  ///
  /// In en, this message translates to:
  /// **'TEAM ROSTER'**
  String get teamRoster;

  /// Lead team role
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get roleLead;

  /// Scout team role
  ///
  /// In en, this message translates to:
  /// **'Scout'**
  String get roleScout;

  /// Medic team role
  ///
  /// In en, this message translates to:
  /// **'Medic'**
  String get roleMedic;

  /// Comms team role
  ///
  /// In en, this message translates to:
  /// **'Comms'**
  String get roleComms;

  /// Custom team role
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get roleCustom;

  /// Change role button
  ///
  /// In en, this message translates to:
  /// **'CHANGE ROLE'**
  String get changeRole;

  /// Promote peer to lead button
  ///
  /// In en, this message translates to:
  /// **'PROMOTE TO LEAD'**
  String get promoteToLead;

  /// Save waypoint locally button
  ///
  /// In en, this message translates to:
  /// **'SAVE TO MY WAYPOINTS'**
  String get saveToMyWaypoints;

  /// Share waypoint with team button
  ///
  /// In en, this message translates to:
  /// **'SHARE WITH TEAM'**
  String get shareWithTeam;

  /// Set team boundary button
  ///
  /// In en, this message translates to:
  /// **'SET BOUNDARY'**
  String get setBoundary;

  /// Boundary alert title
  ///
  /// In en, this message translates to:
  /// **'BOUNDARY ALERT'**
  String get boundaryAlert;

  /// Alert when local user exits boundary
  ///
  /// In en, this message translates to:
  /// **'You left the team boundary'**
  String get youLeftBoundary;

  /// Alert when peer exits boundary
  ///
  /// In en, this message translates to:
  /// **'{callsign} left the boundary'**
  String peerLeftBoundary(String callsign);

  /// Voice callout toggle label
  ///
  /// In en, this message translates to:
  /// **'Voice Callouts'**
  String get voiceCallouts;

  /// Voice callout toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'NATO phonetic position updates'**
  String get voiceCalloutsSubtitle;

  /// Export session button
  ///
  /// In en, this message translates to:
  /// **'EXPORT SESSION'**
  String get exportSession;

  /// Import session button
  ///
  /// In en, this message translates to:
  /// **'IMPORT SESSION'**
  String get importSession;

  /// Session history screen title
  ///
  /// In en, this message translates to:
  /// **'SESSION HISTORY'**
  String get sessionHistory;

  /// Delete annotation confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete annotation?'**
  String get deleteAnnotation;

  /// Waypoint name input label
  ///
  /// In en, this message translates to:
  /// **'Waypoint Name'**
  String get waypointName;

  /// Undo button
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get undo;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get done;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'ca',
        'cs',
        'da',
        'de',
        'el',
        'en',
        'es',
        'fi',
        'fr',
        'he',
        'hi',
        'hr',
        'hu',
        'id',
        'it',
        'ja',
        'ko',
        'ms',
        'nl',
        'no',
        'pl',
        'pt',
        'ro',
        'ru',
        'sk',
        'sv',
        'th',
        'tr',
        'uk',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'ca':
      return AppLocalizationsCa();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'hi':
      return AppLocalizationsHi();
    case 'hr':
      return AppLocalizationsHr();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sk':
      return AppLocalizationsSk();
    case 'sv':
      return AppLocalizationsSv();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

/// App-wide constants for Red Grid Link
class AppConstants {
  AppConstants._();

  static const String appName = 'Red Grid Link';
  static const String appVersion = '1.0.0';

  // Device limits
  static const int maxDevices = 8;
  static const int optimalDevices = 6;
  static const int freeDeviceLimit = 2;

  // Range disclaimer
  static const String rangeDisclaimer =
    'Designed for teams staying within ~150–300 m total diameter. '
    'Works best in line-of-sight or light woods.';

  // UX targets
  static const int maxTapsToAction = 3;
  static const double minTouchTarget = 44.0; // pixels, glove-friendly

  // Default settings
  static const double defaultDeclination = 0.0;
  static const int defaultPaceCount = 62;
  static const String defaultTheme = 'red';
  static const String defaultMode = 'sar';
}

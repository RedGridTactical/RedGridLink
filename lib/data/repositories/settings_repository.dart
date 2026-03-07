import 'package:shared_preferences/shared_preferences.dart';

/// Repository for app settings stored in SharedPreferences.
///
/// Provides typed getters and setters for all user-configurable
/// settings with sensible defaults.
class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  // --- Keys ---

  static const _kThemeId = 'settings_theme_id';
  static const _kOperationalMode = 'settings_operational_mode';
  static const _kDeclination = 'settings_declination';
  static const _kPaceCount = 'settings_pace_count';
  static const _kUpdateInterval = 'settings_update_interval';
  static const _kSyncMode = 'settings_sync_mode';
  static const _kDisplayName = 'settings_display_name';
  static const _kHasCompletedOnboarding = 'settings_has_completed_onboarding';
  static const _kEntitlement = 'settings_entitlement';

  // --- Theme ---

  /// Color theme identifier (e.g., 'red', 'green', 'blue').
  String get themeId => _prefs.getString(_kThemeId) ?? 'red';
  Future<bool> setThemeId(String value) => _prefs.setString(_kThemeId, value);

  // --- Operational Mode ---

  /// Active operational mode: sar, backcountry, hunting, or training.
  String get operationalMode =>
      _prefs.getString(_kOperationalMode) ?? 'sar';
  Future<bool> setOperationalMode(String value) =>
      _prefs.setString(_kOperationalMode, value);

  // --- Declination ---

  /// Magnetic declination offset in degrees.
  double get declination => _prefs.getDouble(_kDeclination) ?? 0.0;
  Future<bool> setDeclination(double value) =>
      _prefs.setDouble(_kDeclination, value);

  // --- Pace Count ---

  /// User's pace count (steps per 100m).
  int get paceCount => _prefs.getInt(_kPaceCount) ?? 62;
  Future<bool> setPaceCount(int value) =>
      _prefs.setInt(_kPaceCount, value);

  // --- Update Interval ---

  /// Position update broadcast interval in milliseconds.
  int get updateInterval => _prefs.getInt(_kUpdateInterval) ?? 15000;
  Future<bool> setUpdateInterval(int value) =>
      _prefs.setInt(_kUpdateInterval, value);

  // --- Sync Mode ---

  /// Default sync mode: expedition or active.
  String get syncMode => _prefs.getString(_kSyncMode) ?? 'active';
  Future<bool> setSyncMode(String value) =>
      _prefs.setString(_kSyncMode, value);

  // --- Display Name ---

  /// User's display name shown to peers.
  String get displayName => _prefs.getString(_kDisplayName) ?? 'Operator';
  Future<bool> setDisplayName(String value) =>
      _prefs.setString(_kDisplayName, value);

  // --- Onboarding ---

  /// Whether the user has completed the initial onboarding flow.
  bool get hasCompletedOnboarding =>
      _prefs.getBool(_kHasCompletedOnboarding) ?? false;
  Future<bool> setHasCompletedOnboarding(bool value) =>
      _prefs.setBool(_kHasCompletedOnboarding, value);

  // --- Entitlement ---

  /// User entitlement tier: free, pro, proLink, or team.
  String get entitlement => _prefs.getString(_kEntitlement) ?? 'free';
  Future<bool> setEntitlement(String value) =>
      _prefs.setString(_kEntitlement, value);

  // --- IAP Metadata ---

  static const _kIapActiveProductId = 'iap_active_product_id';
  static const _kIapPurchaseTimestamp = 'iap_purchase_timestamp';

  /// Active IAP product ID (e.g., 'pro_monthly', 'lifetime').
  String? get iapActiveProductId => _prefs.getString(_kIapActiveProductId);
  Future<bool> setIapActiveProductId(String value) =>
      _prefs.setString(_kIapActiveProductId, value);

  /// Timestamp (milliseconds since epoch) of the last purchase.
  int? get iapPurchaseTimestamp => _prefs.getInt(_kIapPurchaseTimestamp);
  Future<bool> setIapPurchaseTimestamp(int value) =>
      _prefs.setInt(_kIapPurchaseTimestamp, value);
}

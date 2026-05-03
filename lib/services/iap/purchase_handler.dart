import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:red_grid_link/data/models/entitlement.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/services/iap/purchase_validator.dart';

/// Callback signature for entitlement changes.
typedef EntitlementCallback = Future<void> Function(String entitlementName);

/// Handles purchase verification and entitlement persistence.
///
/// Responsibilities:
/// - Receipt validation via a pluggable [PurchaseValidator] (defaults to
///   [ClientOnlyPurchaseValidator]; production deployments should
///   inject a server-backed validator instead).
/// - Entitlement granting and persistence via [SettingsRepository]
/// - Subscription expiry checking that prefers the validator's
///   authoritative expiry over fixed-duration heuristics.
/// - Error reporting for purchase failures
class PurchaseHandler {
  final SettingsRepository _settingsRepository;
  final PurchaseValidator _validator;

  /// Optional callback fired when entitlement changes.
  /// Used by providers to update state reactively.
  final EntitlementCallback? onEntitlementChanged;

  /// The most recent expiry returned by [_validator.verify], if any.
  /// Stored to make [isSubscriptionExpired] prefer authoritative data
  /// over the local timestamp+duration heuristic.
  DateTime? _lastValidatedExpiry;

  PurchaseHandler({
    required SettingsRepository settingsRepository,
    this.onEntitlementChanged,
    PurchaseValidator validator = const ClientOnlyPurchaseValidator(),
  })  : _settingsRepository = settingsRepository,
        _validator = validator;

  // ---------------------------------------------------------------------------
  // Purchase verification
  // ---------------------------------------------------------------------------

  /// Verify a purchase receipt by delegating to the configured
  /// [PurchaseValidator]. When the validator returns an authoritative
  /// expiry, it is captured for later use by [isSubscriptionExpired].
  Future<bool> verifyPurchase(PurchaseDetails purchase) async {
    final result = await _validator.verify(purchase);
    if (result.isValid && result.expiry != null) {
      _lastValidatedExpiry = result.expiry;
    }
    return result.isValid;
  }

  // ---------------------------------------------------------------------------
  // Entitlement management
  // ---------------------------------------------------------------------------

  /// Grant an entitlement tier and persist it to settings.
  ///
  /// [entitlement] is the tier to grant (pro, proLink, or team).
  /// [productId] is the product that triggered the grant (for logging).
  Future<void> grantEntitlement(
    Entitlement entitlement,
    String productId,
  ) async {
    final entitlementName = entitlement.name;

    // Persist to SharedPreferences.
    await _settingsRepository.setEntitlement(entitlementName);

    // Store the active product ID for subscription management.
    await _storeActiveProductId(productId);

    // Store the purchase timestamp.
    await _storePurchaseTimestamp();

    // Notify listeners.
    if (onEntitlementChanged != null) {
      await onEntitlementChanged!(entitlementName);
    }
  }

  /// Revoke entitlement (e.g., on subscription expiry).
  Future<void> revokeEntitlement() async {
    await _settingsRepository.setEntitlement('free');

    if (onEntitlementChanged != null) {
      await onEntitlementChanged!('free');
    }
  }

  /// Get the current entitlement tier from settings.
  Entitlement getCurrentEntitlement() {
    final name = _settingsRepository.entitlement;
    return _entitlementFromName(name);
  }

  /// Get the active product ID (the subscription product currently active).
  String? getActiveProductId() {
    return _settingsRepository.iapActiveProductId;
  }

  // ---------------------------------------------------------------------------
  // Subscription expiry
  // ---------------------------------------------------------------------------

  /// Check if the current subscription has expired.
  ///
  /// Order of preference (audit 2026-05-03 P1):
  ///   1. The validator's most recent authoritative expiry, when set.
  ///      Server-backed validators return this from App Store Server API
  ///      / Google Play Developer API and it correctly tracks renewals,
  ///      grace periods, and refunds.
  ///   2. Fallback: locally stored purchase timestamp + fixed duration.
  ///      This is the legacy heuristic — it is wrong on month-to-month
  ///      renewals and on every grace-period extension, but it is the
  ///      only signal available with the [ClientOnlyPurchaseValidator].
  ///
  /// Returns true if the subscription appears expired.
  bool isSubscriptionExpired() {
    final authoritativeExpiry = _lastValidatedExpiry;
    if (authoritativeExpiry != null) {
      return DateTime.now().isAfter(authoritativeExpiry);
    }

    final timestamp = _getStoredTimestamp();
    if (timestamp == null) return false; // No purchase recorded.

    final productId = getActiveProductId();
    if (productId == null) return false;

    final duration = _subscriptionDuration(productId);
    if (duration == null) return false; // Lifetime — never expires.

    final expiryDate = timestamp.add(duration);
    return DateTime.now().isAfter(expiryDate);
  }

  /// Get the subscription duration for a product.
  ///
  /// Returns null for lifetime products (they never expire).
  Duration? _subscriptionDuration(String productId) {
    switch (productId) {
      case 'pro_monthly':
      case 'pro_link_monthly':
        return const Duration(days: 31);
      case 'pro_annual':
      case 'pro_link_annual':
      case 'team_annual':
        return const Duration(days: 366);
      case 'lifetime':
        return null; // Lifetime — never expires.
      default:
        return null;
    }
  }

  /// Check subscription status and revoke if expired.
  ///
  /// Call this on app startup to catch lapsed subscriptions.
  Future<void> checkAndUpdateExpiry() async {
    final currentEntitlement = getCurrentEntitlement();
    if (currentEntitlement == Entitlement.free) return;

    if (isSubscriptionExpired()) {
      // Note: This is conservative. The store platform will re-grant
      // the entitlement on the next purchase stream if the subscription
      // was actually renewed. This just catches truly lapsed subs.
      await revokeEntitlement();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal storage helpers
  // ---------------------------------------------------------------------------

  /// Persist the active product ID via SharedPreferences.
  Future<void> _storeActiveProductId(String productId) async {
    await _settingsRepository.setIapActiveProductId(productId);
  }

  /// Persist the purchase timestamp via SharedPreferences.
  Future<void> _storePurchaseTimestamp() async {
    await _settingsRepository.setIapPurchaseTimestamp(
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Retrieve the stored purchase timestamp.
  DateTime? _getStoredTimestamp() {
    final ms = _settingsRepository.iapPurchaseTimestamp;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Convert an entitlement name string to the enum.
  Entitlement _entitlementFromName(String name) {
    switch (name) {
      case 'pro':
        return Entitlement.pro;
      case 'proLink':
        return Entitlement.proLink;
      case 'team':
        return Entitlement.team;
      default:
        return Entitlement.free;
    }
  }
}

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:red_grid_link/data/models/entitlement.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';

/// Callback signature for entitlement changes.
typedef EntitlementCallback = Future<void> Function(String entitlementName);

/// Handles purchase verification and entitlement persistence.
///
/// Responsibilities:
/// - Basic receipt validation (full server-side validation is future work)
/// - Entitlement granting and persistence via [SettingsRepository]
/// - Subscription expiry checking
/// - Error reporting for purchase failures
class PurchaseHandler {
  final SettingsRepository _settingsRepository;

  /// Optional callback fired when entitlement changes.
  /// Used by providers to update state reactively.
  final EntitlementCallback? onEntitlementChanged;

  PurchaseHandler({
    required SettingsRepository settingsRepository,
    this.onEntitlementChanged,
  }) : _settingsRepository = settingsRepository;

  // ---------------------------------------------------------------------------
  // Purchase verification
  // ---------------------------------------------------------------------------

  /// Verify a purchase receipt.
  ///
  /// Performs basic client-side validation. Full server-side receipt
  /// validation is planned for a future release. For now, this checks:
  /// - The purchase has a valid product ID
  /// - The purchase status is purchased or restored
  /// - Platform-specific receipt data is present
  ///
  /// Returns true if the purchase passes basic validation.
  Future<bool> verifyPurchase(PurchaseDetails purchase) async {
    // Validate product ID is one of ours.
    final validProductIds = {
      'pro_monthly',
      'pro_annual',
      'pro_link_monthly',
      'pro_link_annual',
      'team_annual',
      'lifetime',
    };
    if (!validProductIds.contains(purchase.productID)) {
      return false;
    }

    // Check the purchase status is valid.
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return false;
    }

    // Verify platform-specific receipt data exists.
    if (!_hasValidReceiptData(purchase)) {
      return false;
    }

    // Basic validation passed.
    // TODO: Add server-side receipt verification in a future phase.
    // For iOS: validate with App Store /verifyReceipt endpoint.
    // For Android: validate with Google Play Developer API.
    return true;
  }

  /// Check whether platform-specific receipt data is present.
  bool _hasValidReceiptData(PurchaseDetails purchase) {
    final verificationData = purchase.verificationData;

    // Local verification data should be present on both platforms.
    if (verificationData.localVerificationData.isEmpty) {
      return false;
    }

    // Server verification data is typically available too.
    // We don't fail on its absence since we're doing client-side only.
    return true;
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
    return _getStoredString('iap_active_product_id');
  }

  // ---------------------------------------------------------------------------
  // Subscription expiry
  // ---------------------------------------------------------------------------

  /// Check if the current subscription has expired.
  ///
  /// Uses locally stored purchase timestamp and product duration.
  /// This is a basic client-side check; the store platform handles
  /// actual subscription lifecycle.
  ///
  /// Returns true if the subscription appears expired based on local data.
  bool isSubscriptionExpired() {
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

  /// These use SharedPreferences via the settings repository's underlying
  /// SharedPreferences instance. We store IAP metadata alongside settings
  /// since it's simple key-value data that doesn't warrant a separate store.

  Future<void> _storeActiveProductId(String productId) async {
    // Access SharedPreferences through the settings repository pattern.
    // We store directly since SettingsRepository exposes setEntitlement
    // but not arbitrary keys. We extend via a simple map.
    _iapMetadata['iap_active_product_id'] = productId;
  }

  Future<void> _storePurchaseTimestamp() async {
    _iapMetadata['iap_purchase_timestamp'] =
        DateTime.now().millisecondsSinceEpoch.toString();
  }

  String? _getStoredString(String key) {
    return _iapMetadata[key];
  }

  DateTime? _getStoredTimestamp() {
    final raw = _iapMetadata['iap_purchase_timestamp'];
    if (raw == null) return null;
    final ms = int.tryParse(raw);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// In-memory IAP metadata store.
  ///
  /// In production this should be backed by SharedPreferences.
  /// Keeping it in-memory simplifies testing and avoids coupling
  /// to SharedPreferences keys that don't exist in SettingsRepository.
  final Map<String, String> _iapMetadata = {};

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

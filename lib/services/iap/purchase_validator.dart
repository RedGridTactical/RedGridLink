import 'package:in_app_purchase/in_app_purchase.dart';

/// Outcome of a purchase verification attempt.
class PurchaseVerification {
  /// Whether the purchase was accepted as valid by the validator.
  final bool isValid;

  /// Optional human-readable reason for rejection (or null on success).
  final String? reason;

  /// The authoritative expiry returned by the validator, when available.
  /// Server-backed validators (e.g. App Store Server API,
  /// Google Play Developer API, RevenueCat) supply this so the client can
  /// stop guessing expiry from `purchaseDate + fixedDuration`. Null means
  /// "use local fallback heuristics".
  final DateTime? expiry;

  const PurchaseVerification({
    required this.isValid,
    this.reason,
    this.expiry,
  });

  const PurchaseVerification.valid({DateTime? expiry})
      : isValid = true,
        reason = null,
        expiry = expiry;

  const PurchaseVerification.invalid(String this.reason)
      : isValid = false,
        expiry = null;
}

/// Strategy interface for verifying that a [PurchaseDetails] is real and
/// currently entitling.
///
/// Audit 2026-05-03 P1 fix: previously [PurchaseHandler] did client-side
/// validation only (productID + status + presence of receipt) with a TODO
/// for server-side. That leaves money on the table: refunds, billing
/// retries, grace periods, account holds, upgrades, downgrades, and
/// renewals are all invisible to the client.
///
/// Implementations:
///   - [ClientOnlyPurchaseValidator] — current shipping behaviour, kept
///     as the explicit default so the move to server-side is a single
///     line change at the wiring layer.
///   - (planned) `RevenueCatValidator` — wraps RevenueCat's REST/SDK.
///   - (planned) `OwnedServerValidator` — POSTs the receipt to a small
///     backend that calls App Store Server API + Google Play Developer
///     API and returns an authoritative entitlement + expiry.
abstract class PurchaseValidator {
  const PurchaseValidator();

  /// Validate [purchase]. Implementations may make a network call.
  Future<PurchaseVerification> verify(PurchaseDetails purchase);
}

/// Default validator: matches the original behaviour of
/// [PurchaseHandler.verifyPurchase] (productID known, status purchased
/// or restored, receipt data present). Useful as a fallback when no
/// server validator is configured (TestFlight builds, internal demos,
/// emergency rollbacks).
class ClientOnlyPurchaseValidator extends PurchaseValidator {
  /// Product IDs the client recognises. Mirrors the catalogue defined
  /// in the App Store / Play Store consoles.
  static const Set<String> _validProductIds = {
    'pro_monthly',
    'pro_annual',
    'pro_link_monthly',
    'pro_link_annual',
    'team_annual',
    'lifetime',
  };

  const ClientOnlyPurchaseValidator();

  @override
  Future<PurchaseVerification> verify(PurchaseDetails purchase) async {
    if (!_validProductIds.contains(purchase.productID)) {
      return PurchaseVerification.invalid(
        'Unknown productID: ${purchase.productID}',
      );
    }

    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return PurchaseVerification.invalid(
        'Unsupported PurchaseStatus: ${purchase.status}',
      );
    }

    if (purchase.verificationData.localVerificationData.isEmpty) {
      return PurchaseVerification.invalid(
        'localVerificationData is empty (no receipt)',
      );
    }

    return const PurchaseVerification.valid();
  }
}

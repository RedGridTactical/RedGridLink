import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:red_grid_link/data/models/entitlement.dart';
import 'package:red_grid_link/services/iap/purchase_handler.dart';
import 'package:red_grid_link/services/stats/funnel_stats.dart';

/// Product identifiers for Red Grid Link subscriptions.
class IAPProducts {
  IAPProducts._();

  static const String proMonthly = 'pro_monthly';
  static const String proAnnual = 'pro_annual';
  static const String proLinkMonthly = 'pro_link_monthly';
  static const String proLinkAnnual = 'pro_link_annual';
  static const String teamAnnual = 'team_annual';
  static const String lifetime = 'lifetime';

  /// All product IDs (subscriptions + lifetime).
  static const Set<String> all = {
    proMonthly,
    proAnnual,
    proLinkMonthly,
    proLinkAnnual,
    teamAnnual,
    lifetime,
  };

  /// Maps a product ID to the corresponding [Entitlement] tier.
  static Entitlement entitlementForProduct(String productId) {
    switch (productId) {
      case proMonthly:
      case proAnnual:
        return Entitlement.pro;
      case proLinkMonthly:
      case proLinkAnnual:
      case lifetime:
        return Entitlement.proLink;
      case teamAnnual:
        return Entitlement.team;
      default:
        return Entitlement.free;
    }
  }

  /// Introductory free-trial lengths configured in App Store Connect.
  ///
  /// StoreKit 2 (the default iOS path) does not expose introductory-offer
  /// details in product data, so iOS paywall copy is driven by this
  /// declaration. The App Store payment sheet always shows the real terms
  /// for the signed-in account. Android trials are detected live from
  /// Play product data and ignore this map.
  static const Map<String, int> declaredIosTrialDays = {
    proAnnual: 7,
  };

  /// Human-readable tier label for a product.
  static String tierLabel(String productId) {
    switch (productId) {
      case proMonthly:
        return 'PRO (Monthly)';
      case proAnnual:
        return 'PRO (Annual)';
      case proLinkMonthly:
        return 'PRO+LINK (Monthly)';
      case proLinkAnnual:
        return 'PRO+LINK (Annual)';
      case teamAnnual:
        return 'TEAM (Annual)';
      case lifetime:
        return 'LIFETIME';
      default:
        return 'FREE';
    }
  }
}

/// Current state of a purchase flow.
enum PurchaseFlowState {
  idle,
  purchasing,
  restoring,
  success,
  error,
}

/// Introductory free-trial information for a subscription product.
class TrialInfo {
  const TrialInfo({required this.days, required this.fromStoreData});

  /// Trial length in days.
  final int days;

  /// True when detected from live store data (Android offers / StoreKit 1).
  /// False when supplied by [IAPProducts.declaredIosTrialDays] because
  /// StoreKit 2 product data carries no introductory-offer details.
  final bool fromStoreData;
}

/// In-App Purchase service for Red Grid Link.
///
/// Wraps the `in_app_purchase` package and provides:
/// - Store connection initialization
/// - Product detail loading
/// - Purchase and restore flows
/// - Purchase stream handling via [PurchaseHandler]
/// - Entitlement mapping
///
/// Ported from the hardened IAP pattern in RedGridMGRS useIAP.js.
class IAPService {
  final InAppPurchase _iap;
  final PurchaseHandler _purchaseHandler;

  /// Loaded product details from the store.
  List<ProductDetails> _products = [];

  /// Stream subscription for purchase updates.
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// Broadcast controller for purchase flow state changes.
  final StreamController<PurchaseFlowState> _stateController =
      StreamController<PurchaseFlowState>.broadcast();

  /// Broadcast controller for error messages.
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  /// Whether the store is available.
  bool _storeAvailable = false;

  /// Current purchase flow state.
  PurchaseFlowState _currentState = PurchaseFlowState.idle;

  IAPService({
    InAppPurchase? iap,
    required PurchaseHandler purchaseHandler,
  })  : _iap = iap ?? InAppPurchase.instance,
        _purchaseHandler = purchaseHandler;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  /// Whether the store connection is available.
  bool get storeAvailable => _storeAvailable;

  /// Loaded product details.
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// Current purchase flow state.
  PurchaseFlowState get currentState => _currentState;

  /// Stream of purchase flow state changes.
  Stream<PurchaseFlowState> get stateStream => _stateController.stream;

  /// Stream of human-readable error messages.
  Stream<String> get errorStream => _errorController.stream;

  /// The underlying purchase handler.
  PurchaseHandler get purchaseHandler => _purchaseHandler;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize the IAP service.
  ///
  /// Checks store availability, loads products, and begins listening
  /// for purchase updates.
  Future<void> initialize() async {
    // Initialization may be triggered from multiple purchase surfaces
    // (Settings, feature paywalls, restore flow). Keep the purchase stream
    // listener singular so each store update is processed exactly once.
    if (_purchaseSubscription != null) {
      if (_storeAvailable) {
        await loadProducts();
      }
      return;
    }

    _storeAvailable = await _iap.isAvailable();

    if (!_storeAvailable) {
      _emitError('Store is not available on this device.');
      return;
    }

    // Start listening for purchase updates before loading products.
    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onDone: _onPurchaseStreamDone,
      onError: _onPurchaseStreamError,
    );

    await loadProducts();
  }

  /// Load available product details from the store.
  ///
  /// Returns true if products were loaded successfully.
  Future<bool> loadProducts() async {
    if (!_storeAvailable) return false;

    try {
      final response = await _iap.queryProductDetails(IAPProducts.all);

      if (response.notFoundIDs.isNotEmpty) {
        // Some products are not configured in the store yet.
        // This is expected during development.
      }

      if (response.error != null) {
        _emitError('Failed to load products: ${response.error!.message}');
        return false;
      }

      _products = response.productDetails;

      // Sort: pro monthly, pro annual, pro+link monthly, pro+link annual,
      // team annual, lifetime.
      _products.sort((a, b) {
        const order = [
          IAPProducts.proMonthly,
          IAPProducts.proAnnual,
          IAPProducts.proLinkMonthly,
          IAPProducts.proLinkAnnual,
          IAPProducts.teamAnnual,
          IAPProducts.lifetime,
        ];
        return order.indexOf(a.id).compareTo(order.indexOf(b.id));
      });

      return true;
    } catch (e) {
      _emitError('Error loading products: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase flow
  // ---------------------------------------------------------------------------

  /// Initiate a purchase for the given product.
  ///
  /// Returns false if the purchase could not be started.
  Future<bool> buyProduct(ProductDetails product) async {
    if (!_storeAvailable) {
      _emitError('Store is not available.');
      return false;
    }

    final loadedProduct = getProduct(product.id);
    if (loadedProduct == null) {
      _emitError('Product not found: ${product.id}');
      return false;
    }

    if (_currentState == PurchaseFlowState.purchasing) {
      _emitError('A purchase is already in progress.');
      return false;
    }

    _setState(PurchaseFlowState.purchasing);

    try {
      final purchaseParam = PurchaseParam(productDetails: loadedProduct);
      // All Red Grid Link products are non-consumable (subscriptions + lifetime).
      final started = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!started) {
        _setState(PurchaseFlowState.error);
        _emitError('Could not start the purchase flow.');
        return false;
      }

      return true;
    } catch (e) {
      _setState(PurchaseFlowState.error);
      _emitError('Purchase error: $e');
      return false;
    }
  }

  /// Buy a product by its ID.
  ///
  /// Looks up the product in the loaded list. Returns false if the
  /// product ID is not found.
  Future<bool> buyProductById(String productId) async {
    var product = getProduct(productId);
    if (product == null) {
      await initialize();
      product = getProduct(productId);
    }
    if (product == null) {
      _emitError('Product not found: $productId');
      return false;
    }
    return buyProduct(product);
  }

  /// Restore previously purchased subscriptions.
  ///
  /// On iOS this triggers the App Store restore flow.
  /// On Android, purchases are automatically restored via queryPurchaseDetails.
  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _emitError('Store is not available.');
      return;
    }

    _setState(PurchaseFlowState.restoring);

    try {
      await _iap.restorePurchases();
      // The purchase stream will deliver any restored purchases.
      // We set idle after a short delay to allow the stream to process.
      // The purchase handler will set success if a valid purchase is found.
      Future.delayed(const Duration(seconds: 3), () {
        if (_currentState == PurchaseFlowState.restoring) {
          _setState(PurchaseFlowState.idle);
        }
      });
    } catch (e) {
      _setState(PurchaseFlowState.error);
      _emitError('Restore failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Product queries
  // ---------------------------------------------------------------------------

  /// All loaded instances for a product ID.
  ///
  /// Android returns one [ProductDetails] per Play subscription offer, so
  /// a product configured with a free-trial offer arrives as multiple
  /// instances sharing the same ID.
  List<ProductDetails> _instancesOf(String productId) =>
      _products.where((p) => p.id == productId).toList();

  /// Get a product by its ID.
  ///
  /// Prefers the instance carrying an introductory free trial so Android
  /// purchases go through that offer's token; eligible users get the
  /// trial, ineligible users never receive the offer from Play.
  ProductDetails? getProduct(String productId) {
    final instances = _instancesOf(productId);
    if (instances.isEmpty) return null;
    for (final p in instances) {
      if (_storeTrialOf(p) != null) return p;
    }
    return instances.first;
  }

  /// Introductory free-trial info for a product, or null when none.
  TrialInfo? trialInfo(String productId) {
    for (final p in _instancesOf(productId)) {
      final t = _storeTrialOf(p);
      if (t != null) return t;
    }
    // StoreKit 2 product data carries no introductory-offer details;
    // fall back to the declared App Store Connect configuration.
    final declared = IAPProducts.declaredIosTrialDays[productId];
    if (declared != null &&
        _instancesOf(productId).any((p) => p is AppStoreProduct2Details)) {
      return TrialInfo(days: declared, fromStoreData: false);
    }
    return null;
  }

  /// Trial detected from live store product data, or null.
  TrialInfo? _storeTrialOf(ProductDetails p) {
    if (p is AppStoreProductDetails) {
      final intro = p.skProduct.introductoryPrice;
      if (intro == null ||
          intro.paymentMode != SKProductDiscountPaymentMode.freeTrail) {
        return null;
      }
      final period = intro.subscriptionPeriod;
      final unitDays = switch (period.unit) {
        SKSubscriptionPeriodUnit.day => 1,
        SKSubscriptionPeriodUnit.week => 7,
        SKSubscriptionPeriodUnit.month => 30,
        SKSubscriptionPeriodUnit.year => 365,
      };
      return TrialInfo(
        days: unitDays * period.numberOfUnits * intro.numberOfPeriods,
        fromStoreData: true,
      );
    }
    if (p is GooglePlayProductDetails) {
      final idx = p.subscriptionIndex;
      final offers = p.productDetails.subscriptionOfferDetails;
      if (idx == null || offers == null || idx >= offers.length) return null;
      for (final phase in offers[idx].pricingPhases) {
        if (phase.priceAmountMicros == 0) {
          return TrialInfo(
            days: daysFromIsoPeriod(phase.billingPeriod),
            fromStoreData: true,
          );
        }
      }
    }
    return null;
  }

  /// The recurring base price of an instance, never a $0 trial phase.
  String? _basePriceOf(ProductDetails p) {
    if (p is GooglePlayProductDetails) {
      final idx = p.subscriptionIndex;
      final offers = p.productDetails.subscriptionOfferDetails;
      if (idx != null && offers != null && idx < offers.length) {
        // The last non-zero pricing phase is the recurring base price; a
        // trial offer's leading phase is 0 and must not be displayed.
        final phases = offers[idx].pricingPhases;
        for (final phase in phases.reversed) {
          if (phase.priceAmountMicros > 0) return phase.formattedPrice;
        }
        return null;
      }
    }
    return p.price;
  }

  /// Days in an ISO-8601 billing period like `P1W`, `P3D`, `P1M`, `P1Y`.
  @visibleForTesting
  static int daysFromIsoPeriod(String iso) {
    final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(iso.toUpperCase());
    if (match == null) return 0;
    final n = int.parse(match.group(1)!);
    return switch (match.group(2)!) {
      'D' => n,
      'W' => n * 7,
      'M' => n * 30,
      'Y' => n * 365,
      _ => 0,
    };
  }

  /// Get a formatted price string for a product.
  ///
  /// Returns the store-formatted base price (e.g., "\$29.99") or a fallback.
  String getPrice(String productId) {
    for (final p in _instancesOf(productId)) {
      final base = _basePriceOf(p);
      if (base != null && base.isNotEmpty) return base;
    }

    // Fallback prices when products haven't loaded.
    switch (productId) {
      case IAPProducts.proMonthly:
        return '\$3.99/mo';
      case IAPProducts.proAnnual:
        return '\$29.99/yr';
      case IAPProducts.proLinkMonthly:
        return '\$5.99/mo';
      case IAPProducts.proLinkAnnual:
        return '\$44.99/yr';
      case IAPProducts.teamAnnual:
        return '\$199.99/yr';
      case IAPProducts.lifetime:
        return '\$149.99';
      default:
        return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase stream handlers
  // ---------------------------------------------------------------------------

  /// Process incoming purchase updates from the store.
  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  /// Handle a single purchase update.
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        // Purchase is pending — keep the purchasing state.
        _setState(PurchaseFlowState.purchasing);
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Verify and complete the purchase.
        final verified = await _purchaseHandler.verifyPurchase(purchase);

        if (verified) {
          // Map product to entitlement and persist.
          final entitlement =
              IAPProducts.entitlementForProduct(purchase.productID);
          await _purchaseHandler.grantEntitlement(
            entitlement,
            purchase.productID,
          );
          _setState(PurchaseFlowState.success);
          if (purchase.status == PurchaseStatus.purchased) {
            // Local-only conversion counter (no network, no identifiers).
            unawaited(
              FunnelStats.instance
                  .increment('purchase_success.${purchase.productID}'),
            );
          }
        } else {
          _setState(PurchaseFlowState.error);
          _emitError('Purchase verification failed.');
        }

        // Complete the purchase on the platform side.
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.error:
        _setState(PurchaseFlowState.error);
        _emitError(
          purchase.error?.message ?? 'An unknown purchase error occurred.',
        );

        // Complete the purchase to clear it from the queue.
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.canceled:
        _setState(PurchaseFlowState.idle);
        // No error — user intentionally canceled.

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
    }
  }

  void _onPurchaseStreamDone() {
    // Stream closed — typically on app shutdown.
  }

  void _onPurchaseStreamError(Object error) {
    _setState(PurchaseFlowState.error);
    _emitError('Purchase stream error: $error');
  }

  // ---------------------------------------------------------------------------
  // State management
  // ---------------------------------------------------------------------------

  void _setState(PurchaseFlowState state) {
    _currentState = state;
    _stateController.add(state);
  }

  void _emitError(String message) {
    _errorController.add(message);
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /// Release resources held by this service.
  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _stateController.close();
    _errorController.close();
  }
}

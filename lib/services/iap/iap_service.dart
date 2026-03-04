import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:red_grid_link/data/models/entitlement.dart';
import 'package:red_grid_link/services/iap/purchase_handler.dart';

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

    if (_currentState == PurchaseFlowState.purchasing) {
      _emitError('A purchase is already in progress.');
      return false;
    }

    _setState(PurchaseFlowState.purchasing);

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
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
    final product = getProduct(productId);
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

  /// Get a product by its ID.
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Get a formatted price string for a product.
  ///
  /// Returns the store-formatted price (e.g., "\$3.99") or a fallback.
  String getPrice(String productId) {
    final product = getProduct(productId);
    if (product != null) return product.price;

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
        return '\$99.99';
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

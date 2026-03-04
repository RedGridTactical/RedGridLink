import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:red_grid_link/data/models/entitlement.dart';
import 'package:red_grid_link/services/iap/iap_service.dart';
import 'package:red_grid_link/services/iap/purchase_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';

// ---------------------------------------------------------------------------
// Mock InAppPurchase implementation
// ---------------------------------------------------------------------------

/// A fake [InAppPurchase] for unit testing.
///
/// Allows tests to control store availability, product responses,
/// and the purchase stream.
class FakeInAppPurchase implements InAppPurchase {
  bool isAvailableResult = true;
  ProductDetailsResponse? productDetailsResponse;
  bool buyNonConsumableResult = true;
  bool restoreCalled = false;
  final List<PurchaseDetails> completedPurchases = [];

  final StreamController<List<PurchaseDetails>> _purchaseStreamController =
      StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseStreamController.stream;

  @override
  Future<bool> isAvailable() async => isAvailableResult;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    if (productDetailsResponse != null) return productDetailsResponse!;

    // Default: return products matching the identifiers.
    final products = identifiers.map((id) => _makeProductDetails(id)).toList();
    return ProductDetailsResponse(
      productDetails: products,
      notFoundIDs: [],
    );
  }

  @override
  Future<bool> buyNonConsumable({
    required PurchaseParam purchaseParam,
  }) async {
    return buyNonConsumableResult;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoreCalled = true;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    return false;
  }

  @override
  Future<String> countryCode() async => 'US';

  @override
  T getPlatformAddition<T extends InAppPurchasePlatformAddition?>() {
    throw UnimplementedError();
  }

  /// Emit purchase updates to simulate store events.
  void emitPurchases(List<PurchaseDetails> purchases) {
    _purchaseStreamController.add(purchases);
  }

  void dispose() {
    _purchaseStreamController.close();
  }
}

/// Create a fake [ProductDetails] for testing.
ProductDetails _makeProductDetails(String id) {
  final prices = {
    'pro_monthly': '\$3.99',
    'pro_annual': '\$29.99',
    'pro_link_monthly': '\$5.99',
    'pro_link_annual': '\$44.99',
    'team_annual': '\$199.99',
    'lifetime': '\$99.99',
  };

  return ProductDetails(
    id: id,
    title: 'Test Product $id',
    description: 'Description for $id',
    price: prices[id] ?? '\$0.00',
    rawPrice: 0.0,
    currencyCode: 'USD',
  );
}

/// Create a fake [PurchaseDetails] for testing.
PurchaseDetails _makePurchaseDetails({
  required String productId,
  required PurchaseStatus status,
  bool pendingCompletePurchase = true,
  String localVerificationData = 'test_receipt_data',
}) {
  return PurchaseDetails(
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: localVerificationData,
      serverVerificationData: 'server_data',
      source: 'test',
    ),
    transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
    status: status,
    purchaseID: 'test_purchase_${DateTime.now().millisecondsSinceEpoch}',
  )..pendingCompletePurchase = pendingCompletePurchase;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeInAppPurchase fakeIap;
  late PurchaseHandler purchaseHandler;
  late SettingsRepository settingsRepository;
  late IAPService service;

  // Track entitlement changes.
  String lastEntitlement = 'free';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settingsRepository = SettingsRepository(prefs);

    fakeIap = FakeInAppPurchase();

    purchaseHandler = PurchaseHandler(
      settingsRepository: settingsRepository,
      onEntitlementChanged: (name) async {
        lastEntitlement = name;
      },
    );

    service = IAPService(
      iap: fakeIap,
      purchaseHandler: purchaseHandler,
    );

    lastEntitlement = 'free';
  });

  tearDown(() {
    service.dispose();
    fakeIap.dispose();
  });

  // -------------------------------------------------------------------------
  // IAPProducts
  // -------------------------------------------------------------------------
  group('IAPProducts', () {
    test('defines six product IDs', () {
      expect(IAPProducts.all, hasLength(6));
      expect(IAPProducts.all, contains(IAPProducts.proMonthly));
      expect(IAPProducts.all, contains(IAPProducts.proAnnual));
      expect(IAPProducts.all, contains(IAPProducts.proLinkMonthly));
      expect(IAPProducts.all, contains(IAPProducts.proLinkAnnual));
      expect(IAPProducts.all, contains(IAPProducts.teamAnnual));
      expect(IAPProducts.all, contains(IAPProducts.lifetime));
    });

    test('proMonthly maps to pro entitlement', () {
      expect(
        IAPProducts.entitlementForProduct(IAPProducts.proMonthly),
        Entitlement.pro,
      );
    });

    test('proAnnual maps to pro entitlement', () {
      expect(
        IAPProducts.entitlementForProduct(IAPProducts.proAnnual),
        Entitlement.pro,
      );
    });

    test('proLinkMonthly maps to proLink entitlement', () {
      expect(
        IAPProducts.entitlementForProduct(IAPProducts.proLinkMonthly),
        Entitlement.proLink,
      );
    });

    test('proLinkAnnual maps to proLink entitlement', () {
      expect(
        IAPProducts.entitlementForProduct(IAPProducts.proLinkAnnual),
        Entitlement.proLink,
      );
    });

    test('lifetime maps to proLink entitlement', () {
      expect(
        IAPProducts.entitlementForProduct(IAPProducts.lifetime),
        Entitlement.proLink,
      );
    });

    test('teamAnnual maps to team entitlement', () {
      expect(
        IAPProducts.entitlementForProduct(IAPProducts.teamAnnual),
        Entitlement.team,
      );
    });

    test('unknown product maps to free entitlement', () {
      expect(
        IAPProducts.entitlementForProduct('unknown_product'),
        Entitlement.free,
      );
    });

    test('tierLabel returns correct labels', () {
      expect(IAPProducts.tierLabel(IAPProducts.proMonthly), 'PRO (Monthly)');
      expect(IAPProducts.tierLabel(IAPProducts.proAnnual), 'PRO (Annual)');
      expect(
        IAPProducts.tierLabel(IAPProducts.proLinkMonthly),
        'PRO+LINK (Monthly)',
      );
      expect(
        IAPProducts.tierLabel(IAPProducts.proLinkAnnual),
        'PRO+LINK (Annual)',
      );
      expect(IAPProducts.tierLabel(IAPProducts.teamAnnual), 'TEAM (Annual)');
      expect(IAPProducts.tierLabel(IAPProducts.lifetime), 'LIFETIME');
      expect(IAPProducts.tierLabel('other'), 'FREE');
    });
  });

  // -------------------------------------------------------------------------
  // Initialization
  // -------------------------------------------------------------------------
  group('initialization', () {
    test('initializes successfully when store is available', () async {
      await service.initialize();
      expect(service.storeAvailable, isTrue);
      expect(service.products, isNotEmpty);
    });

    test('marks store unavailable when isAvailable returns false', () async {
      fakeIap.isAvailableResult = false;

      // Subscribe to error stream before initialize so we catch the error.
      final errors = <String>[];
      final sub = service.errorStream.listen(errors.add);

      await service.initialize();

      // Allow the stream event to propagate.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.storeAvailable, isFalse);
      expect(service.products, isEmpty);
      expect(errors, isNotEmpty);

      await sub.cancel();
    });

    test('loads all six products', () async {
      await service.initialize();
      expect(service.products, hasLength(6));
    });

    test('sorts products in correct order', () async {
      await service.initialize();
      final ids = service.products.map((p) => p.id).toList();
      expect(ids[0], IAPProducts.proMonthly);
      expect(ids[1], IAPProducts.proAnnual);
      expect(ids[2], IAPProducts.proLinkMonthly);
      expect(ids[3], IAPProducts.proLinkAnnual);
      expect(ids[4], IAPProducts.teamAnnual);
      expect(ids[5], IAPProducts.lifetime);
    });

    test('handles product query error', () async {
      fakeIap.productDetailsResponse = ProductDetailsResponse(
        productDetails: [],
        notFoundIDs: [],
        error: IAPError(
          source: 'test',
          code: 'error',
          message: 'Test error',
        ),
      );

      // Subscribe before initialize to catch stream events.
      final errors = <String>[];
      final sub = service.errorStream.listen(errors.add);

      await service.initialize();

      // Allow stream propagation.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.products, isEmpty);
      expect(errors.any((e) => e.contains('Failed to load products')), isTrue);

      await sub.cancel();
    });

    test('reports not-found product IDs without failing', () async {
      fakeIap.productDetailsResponse = ProductDetailsResponse(
        productDetails: [_makeProductDetails('pro_monthly')],
        notFoundIDs: ['pro_annual', 'team_annual'],
      );

      await service.initialize();
      // Should still succeed with the products that were found.
      expect(service.products, hasLength(1));
    });
  });

  // -------------------------------------------------------------------------
  // Product queries
  // -------------------------------------------------------------------------
  group('product queries', () {
    test('getProduct returns product by ID', () async {
      await service.initialize();
      final product = service.getProduct(IAPProducts.proMonthly);
      expect(product, isNotNull);
      expect(product!.id, IAPProducts.proMonthly);
    });

    test('getProduct returns null for unknown ID', () async {
      await service.initialize();
      expect(service.getProduct('nonexistent'), isNull);
    });

    test('getPrice returns store price when loaded', () async {
      await service.initialize();
      expect(service.getPrice(IAPProducts.proMonthly), '\$3.99');
      expect(service.getPrice(IAPProducts.proAnnual), '\$29.99');
      expect(service.getPrice(IAPProducts.proLinkMonthly), '\$5.99');
      expect(service.getPrice(IAPProducts.proLinkAnnual), '\$44.99');
      expect(service.getPrice(IAPProducts.teamAnnual), '\$199.99');
      expect(service.getPrice(IAPProducts.lifetime), '\$99.99');
    });

    test('getPrice returns fallback price when products not loaded', () {
      // Products not loaded (no initialize).
      expect(service.getPrice(IAPProducts.proMonthly), '\$3.99/mo');
      expect(service.getPrice(IAPProducts.proAnnual), '\$29.99/yr');
      expect(service.getPrice(IAPProducts.proLinkMonthly), '\$5.99/mo');
      expect(service.getPrice(IAPProducts.proLinkAnnual), '\$44.99/yr');
      expect(service.getPrice(IAPProducts.teamAnnual), '\$199.99/yr');
      expect(service.getPrice(IAPProducts.lifetime), '\$99.99');
    });

    test('getPrice returns empty for unknown product', () {
      expect(service.getPrice('unknown'), '');
    });
  });

  // -------------------------------------------------------------------------
  // Purchase flow
  // -------------------------------------------------------------------------
  group('buyProduct', () {
    test('starts purchase and transitions to purchasing state', () async {
      await service.initialize();

      final states = <PurchaseFlowState>[];
      service.stateStream.listen(states.add);

      final product = service.getProduct(IAPProducts.proMonthly)!;
      final result = await service.buyProduct(product);

      expect(result, isTrue);
      expect(states, contains(PurchaseFlowState.purchasing));
    });

    test('fails when store is not available', () async {
      fakeIap.isAvailableResult = false;
      await service.initialize();

      final errors = <String>[];
      service.errorStream.listen(errors.add);

      final result =
          await service.buyProductById(IAPProducts.proMonthly);
      expect(result, isFalse);
    });

    test('fails when buyNonConsumable returns false', () async {
      await service.initialize();
      fakeIap.buyNonConsumableResult = false;

      final states = <PurchaseFlowState>[];
      service.stateStream.listen(states.add);

      final product = service.getProduct(IAPProducts.proMonthly)!;
      final result = await service.buyProduct(product);

      // Allow stream events to propagate.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(result, isFalse);
      expect(states, contains(PurchaseFlowState.error));
    });

    test('buyProductById fails for unknown product', () async {
      await service.initialize();

      final errors = <String>[];
      service.errorStream.listen(errors.add);

      final result = await service.buyProductById('nonexistent');
      expect(result, isFalse);
      expect(errors.any((e) => e.contains('Product not found')), isTrue);
    });

    test('rejects concurrent purchases', () async {
      await service.initialize();

      // Start first purchase.
      final product = service.getProduct(IAPProducts.proMonthly)!;
      await service.buyProduct(product);

      // Try second purchase while first is in progress.
      final errors = <String>[];
      service.errorStream.listen(errors.add);

      final result = await service.buyProduct(product);
      expect(result, isFalse);
      expect(
        errors.any((e) => e.contains('already in progress')),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Purchase stream handling
  // -------------------------------------------------------------------------
  group('purchase stream handling', () {
    test('grants pro entitlement on successful pro_monthly purchase', () async {
      await service.initialize();

      final purchase = _makePurchaseDetails(
        productId: 'pro_monthly',
        status: PurchaseStatus.purchased,
      );

      // Wait for the purchase to be processed.
      final stateCompleter = Completer<PurchaseFlowState>();
      service.stateStream.listen((state) {
        if (state == PurchaseFlowState.success &&
            !stateCompleter.isCompleted) {
          stateCompleter.complete(state);
        }
      });

      fakeIap.emitPurchases([purchase]);

      final finalState = await stateCompleter.future
          .timeout(const Duration(seconds: 2));

      expect(finalState, PurchaseFlowState.success);
      expect(lastEntitlement, 'pro');
      expect(settingsRepository.entitlement, 'pro');
    });

    test('grants proLink entitlement on pro_link_monthly purchase', () async {
      await service.initialize();

      final purchase = _makePurchaseDetails(
        productId: 'pro_link_monthly',
        status: PurchaseStatus.purchased,
      );

      final stateCompleter = Completer<PurchaseFlowState>();
      service.stateStream.listen((state) {
        if (state == PurchaseFlowState.success &&
            !stateCompleter.isCompleted) {
          stateCompleter.complete(state);
        }
      });

      fakeIap.emitPurchases([purchase]);

      final finalState = await stateCompleter.future
          .timeout(const Duration(seconds: 2));

      expect(finalState, PurchaseFlowState.success);
      expect(lastEntitlement, 'proLink');
      expect(settingsRepository.entitlement, 'proLink');
    });

    test('grants proLink entitlement on lifetime purchase', () async {
      await service.initialize();

      final purchase = _makePurchaseDetails(
        productId: 'lifetime',
        status: PurchaseStatus.purchased,
      );

      final stateCompleter = Completer<PurchaseFlowState>();
      service.stateStream.listen((state) {
        if (state == PurchaseFlowState.success &&
            !stateCompleter.isCompleted) {
          stateCompleter.complete(state);
        }
      });

      fakeIap.emitPurchases([purchase]);

      final finalState = await stateCompleter.future
          .timeout(const Duration(seconds: 2));

      expect(finalState, PurchaseFlowState.success);
      expect(lastEntitlement, 'proLink');
      expect(settingsRepository.entitlement, 'proLink');
    });

    test('grants team entitlement on team_annual purchase', () async {
      await service.initialize();

      final purchase = _makePurchaseDetails(
        productId: 'team_annual',
        status: PurchaseStatus.purchased,
      );

      final stateCompleter = Completer<PurchaseFlowState>();
      service.stateStream.listen((state) {
        if (state == PurchaseFlowState.success &&
            !stateCompleter.isCompleted) {
          stateCompleter.complete(state);
        }
      });

      fakeIap.emitPurchases([purchase]);

      final finalState = await stateCompleter.future
          .timeout(const Duration(seconds: 2));

      expect(finalState, PurchaseFlowState.success);
      expect(lastEntitlement, 'team');
      expect(settingsRepository.entitlement, 'team');
    });

    test('handles restored purchase', () async {
      await service.initialize();

      final purchase = _makePurchaseDetails(
        productId: 'pro_annual',
        status: PurchaseStatus.restored,
      );

      final stateCompleter = Completer<PurchaseFlowState>();
      service.stateStream.listen((state) {
        if (state == PurchaseFlowState.success &&
            !stateCompleter.isCompleted) {
          stateCompleter.complete(state);
        }
      });

      fakeIap.emitPurchases([purchase]);

      final finalState = await stateCompleter.future
          .timeout(const Duration(seconds: 2));

      expect(finalState, PurchaseFlowState.success);
      expect(lastEntitlement, 'pro');
    });

    test('completes pending purchases after processing', () async {
      await service.initialize();

      final purchase = _makePurchaseDetails(
        productId: 'pro_monthly',
        status: PurchaseStatus.purchased,
        pendingCompletePurchase: true,
      );

      final stateCompleter = Completer<void>();
      service.stateStream.listen((state) {
        if (state == PurchaseFlowState.success &&
            !stateCompleter.isCompleted) {
          stateCompleter.complete();
        }
      });

      fakeIap.emitPurchases([purchase]);
      await stateCompleter.future.timeout(const Duration(seconds: 2));

      expect(fakeIap.completedPurchases, hasLength(1));
      expect(fakeIap.completedPurchases.first.productID, 'pro_monthly');
    });

    test('handles purchase error status', () async {
      await service.initialize();

      final purchase = PurchaseDetails(
        productID: 'pro_monthly',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'data',
          serverVerificationData: 'data',
          source: 'test',
        ),
        transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
        status: PurchaseStatus.error,
        purchaseID: 'error_purchase',
      )..pendingCompletePurchase = true;

      final states = <PurchaseFlowState>[];
      service.stateStream.listen(states.add);

      final errors = <String>[];
      service.errorStream.listen(errors.add);

      fakeIap.emitPurchases([purchase]);

      // Give the stream time to process.
      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, contains(PurchaseFlowState.error));
    });

    test('handles purchase canceled status', () async {
      await service.initialize();

      final purchase = _makePurchaseDetails(
        productId: 'pro_monthly',
        status: PurchaseStatus.canceled,
      );

      final states = <PurchaseFlowState>[];
      service.stateStream.listen(states.add);

      fakeIap.emitPurchases([purchase]);

      await Future.delayed(const Duration(milliseconds: 100));

      // Should return to idle, not error.
      expect(states, contains(PurchaseFlowState.idle));
    });

    test('handles pending purchase status', () async {
      await service.initialize();

      final purchase = _makePurchaseDetails(
        productId: 'pro_monthly',
        status: PurchaseStatus.pending,
      );

      final states = <PurchaseFlowState>[];
      service.stateStream.listen(states.add);

      fakeIap.emitPurchases([purchase]);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, contains(PurchaseFlowState.purchasing));
    });

    test('rejects purchase with invalid product ID', () async {
      await service.initialize();

      final purchase = _makePurchaseDetails(
        productId: 'invalid_product',
        status: PurchaseStatus.purchased,
      );

      final states = <PurchaseFlowState>[];
      service.stateStream.listen(states.add);

      final errors = <String>[];
      service.errorStream.listen(errors.add);

      fakeIap.emitPurchases([purchase]);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, contains(PurchaseFlowState.error));
      expect(errors.any((e) => e.contains('verification failed')), isTrue);
    });

    test('rejects purchase with empty receipt data', () async {
      await service.initialize();

      final purchase = _makePurchaseDetails(
        productId: 'pro_monthly',
        status: PurchaseStatus.purchased,
        localVerificationData: '',
      );

      final states = <PurchaseFlowState>[];
      service.stateStream.listen(states.add);

      fakeIap.emitPurchases([purchase]);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, contains(PurchaseFlowState.error));
    });
  });

  // -------------------------------------------------------------------------
  // Restore purchases
  // -------------------------------------------------------------------------
  group('restorePurchases', () {
    test('calls restore on the IAP platform', () async {
      await service.initialize();
      await service.restorePurchases();
      expect(fakeIap.restoreCalled, isTrue);
    });

    test('transitions to restoring state', () async {
      await service.initialize();

      final states = <PurchaseFlowState>[];
      service.stateStream.listen(states.add);

      await service.restorePurchases();
      expect(states, contains(PurchaseFlowState.restoring));
    });

    test('fails when store is not available', () async {
      fakeIap.isAvailableResult = false;
      await service.initialize();

      final errors = <String>[];
      service.errorStream.listen(errors.add);

      await service.restorePurchases();
      expect(errors.any((e) => e.contains('not available')), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // PurchaseHandler
  // -------------------------------------------------------------------------
  group('PurchaseHandler', () {
    test('getCurrentEntitlement returns free by default', () {
      expect(purchaseHandler.getCurrentEntitlement(), Entitlement.free);
    });

    test('grantEntitlement persists pro tier', () async {
      await purchaseHandler.grantEntitlement(
        Entitlement.pro,
        'pro_monthly',
      );
      expect(purchaseHandler.getCurrentEntitlement(), Entitlement.pro);
      expect(settingsRepository.entitlement, 'pro');
      expect(lastEntitlement, 'pro');
    });

    test('grantEntitlement persists proLink tier', () async {
      await purchaseHandler.grantEntitlement(
        Entitlement.proLink,
        'pro_link_monthly',
      );
      expect(purchaseHandler.getCurrentEntitlement(), Entitlement.proLink);
      expect(settingsRepository.entitlement, 'proLink');
      expect(lastEntitlement, 'proLink');
    });

    test('grantEntitlement persists team tier', () async {
      await purchaseHandler.grantEntitlement(
        Entitlement.team,
        'team_annual',
      );
      expect(purchaseHandler.getCurrentEntitlement(), Entitlement.team);
      expect(settingsRepository.entitlement, 'team');
      expect(lastEntitlement, 'team');
    });

    test('revokeEntitlement resets to free', () async {
      await purchaseHandler.grantEntitlement(
        Entitlement.pro,
        'pro_monthly',
      );
      expect(purchaseHandler.getCurrentEntitlement(), Entitlement.pro);

      await purchaseHandler.revokeEntitlement();
      expect(purchaseHandler.getCurrentEntitlement(), Entitlement.free);
      expect(settingsRepository.entitlement, 'free');
      expect(lastEntitlement, 'free');
    });

    test('stores active product ID', () async {
      await purchaseHandler.grantEntitlement(
        Entitlement.pro,
        'pro_annual',
      );
      expect(purchaseHandler.getActiveProductId(), 'pro_annual');
    });

    test('isSubscriptionExpired returns false when no purchase', () {
      expect(purchaseHandler.isSubscriptionExpired(), isFalse);
    });

    test('isSubscriptionExpired returns false for current entitlement', () {
      // No purchase timestamp set.
      expect(purchaseHandler.isSubscriptionExpired(), isFalse);
    });

    test('isSubscriptionExpired returns false for lifetime product', () async {
      await purchaseHandler.grantEntitlement(
        Entitlement.proLink,
        'lifetime',
      );
      // Lifetime should never expire.
      expect(purchaseHandler.isSubscriptionExpired(), isFalse);
    });

    test('checkAndUpdateExpiry does nothing for free users', () async {
      await purchaseHandler.checkAndUpdateExpiry();
      expect(purchaseHandler.getCurrentEntitlement(), Entitlement.free);
    });

    test('verifyPurchase rejects invalid product ID', () async {
      final purchase = _makePurchaseDetails(
        productId: 'fake_product',
        status: PurchaseStatus.purchased,
      );
      expect(await purchaseHandler.verifyPurchase(purchase), isFalse);
    });

    test('verifyPurchase rejects pending status', () async {
      final purchase = _makePurchaseDetails(
        productId: 'pro_monthly',
        status: PurchaseStatus.pending,
      );
      expect(await purchaseHandler.verifyPurchase(purchase), isFalse);
    });

    test('verifyPurchase rejects canceled status', () async {
      final purchase = _makePurchaseDetails(
        productId: 'pro_monthly',
        status: PurchaseStatus.canceled,
      );
      expect(await purchaseHandler.verifyPurchase(purchase), isFalse);
    });

    test('verifyPurchase rejects error status', () async {
      final purchase = _makePurchaseDetails(
        productId: 'pro_monthly',
        status: PurchaseStatus.error,
      );
      expect(await purchaseHandler.verifyPurchase(purchase), isFalse);
    });

    test('verifyPurchase accepts purchased status', () async {
      final purchase = _makePurchaseDetails(
        productId: 'pro_monthly',
        status: PurchaseStatus.purchased,
      );
      expect(await purchaseHandler.verifyPurchase(purchase), isTrue);
    });

    test('verifyPurchase accepts restored status', () async {
      final purchase = _makePurchaseDetails(
        productId: 'pro_annual',
        status: PurchaseStatus.restored,
      );
      expect(await purchaseHandler.verifyPurchase(purchase), isTrue);
    });

    test('verifyPurchase accepts pro_link_monthly', () async {
      final purchase = _makePurchaseDetails(
        productId: 'pro_link_monthly',
        status: PurchaseStatus.purchased,
      );
      expect(await purchaseHandler.verifyPurchase(purchase), isTrue);
    });

    test('verifyPurchase accepts pro_link_annual', () async {
      final purchase = _makePurchaseDetails(
        productId: 'pro_link_annual',
        status: PurchaseStatus.purchased,
      );
      expect(await purchaseHandler.verifyPurchase(purchase), isTrue);
    });

    test('verifyPurchase accepts lifetime', () async {
      final purchase = _makePurchaseDetails(
        productId: 'lifetime',
        status: PurchaseStatus.purchased,
      );
      expect(await purchaseHandler.verifyPurchase(purchase), isTrue);
    });

    test('verifyPurchase rejects empty receipt', () async {
      final purchase = _makePurchaseDetails(
        productId: 'pro_monthly',
        status: PurchaseStatus.purchased,
        localVerificationData: '',
      );
      expect(await purchaseHandler.verifyPurchase(purchase), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // State management
  // -------------------------------------------------------------------------
  group('state management', () {
    test('initial state is idle', () {
      expect(service.currentState, PurchaseFlowState.idle);
    });

    test('state stream emits changes', () async {
      await service.initialize();

      final states = <PurchaseFlowState>[];
      service.stateStream.listen(states.add);

      final product = service.getProduct(IAPProducts.proMonthly)!;
      await service.buyProduct(product);

      expect(states, isNotEmpty);
      expect(states.first, PurchaseFlowState.purchasing);
    });

    test('error stream emits messages', () async {
      fakeIap.isAvailableResult = false;

      // Subscribe before initialize to catch the error.
      final errors = <String>[];
      final sub = service.errorStream.listen(errors.add);

      await service.initialize();

      // Allow stream events to propagate.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(errors, isNotEmpty);
      expect(errors.first, contains('not available'));

      await sub.cancel();
    });
  });

  // -------------------------------------------------------------------------
  // Dispose
  // -------------------------------------------------------------------------
  group('dispose', () {
    test('can be disposed cleanly', () {
      // Should not throw.
      service.dispose();
    });

    test('dispose is idempotent', () {
      service.dispose();
      // Calling dispose again should not throw.
      // The underlying streams are closed.
    });
  });

  // -------------------------------------------------------------------------
  // loadProducts
  // -------------------------------------------------------------------------
  group('loadProducts', () {
    test('returns false when store not available', () async {
      fakeIap.isAvailableResult = false;
      await service.initialize();
      final result = await service.loadProducts();
      expect(result, isFalse);
    });

    test('returns true on success', () async {
      await service.initialize();
      final result = await service.loadProducts();
      expect(result, isTrue);
    });
  });
}

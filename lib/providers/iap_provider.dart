import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:red_grid_link/providers/settings_provider.dart';
import 'package:red_grid_link/services/iap/iap_service.dart';
import 'package:red_grid_link/services/iap/purchase_handler.dart';

// ---------------------------------------------------------------------------
// Purchase handler
// ---------------------------------------------------------------------------

/// Provider for the [PurchaseHandler] singleton.
///
/// Wired to update [entitlementProvider] when a purchase completes.
final purchaseHandlerProvider = Provider<PurchaseHandler>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  final entitlementNotifier = ref.read(entitlementProvider.notifier);

  return PurchaseHandler(
    settingsRepository: repo,
    onEntitlementChanged: (name) async {
      await entitlementNotifier.set(name);
    },
  );
});

// ---------------------------------------------------------------------------
// IAP service
// ---------------------------------------------------------------------------

/// Provider for the [IAPService] singleton.
///
/// Automatically initializes the service and begins listening for
/// purchase updates. Disposes cleanly on scope teardown.
final iapServiceProvider = Provider<IAPService>((ref) {
  final handler = ref.watch(purchaseHandlerProvider);
  final service = IAPService(purchaseHandler: handler);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// ---------------------------------------------------------------------------
// Products
// ---------------------------------------------------------------------------

/// Async provider that loads available products from the store.
///
/// Usage:
/// ```dart
/// final productsAsync = ref.watch(productsProvider);
/// productsAsync.when(
///   data: (products) => ...,
///   loading: () => ...,
///   error: (e, s) => ...,
/// );
/// ```
final productsProvider =
    FutureProvider<List<ProductDetails>>((ref) async {
  final service = ref.watch(iapServiceProvider);
  await service.initialize();
  return service.products;
});

// ---------------------------------------------------------------------------
// Purchase state
// ---------------------------------------------------------------------------

/// Tracks the current purchase flow state.
///
/// Listens to the [IAPService] state stream and exposes it reactively.
class PurchaseStateNotifier extends StateNotifier<PurchaseFlowState> {
  StreamSubscription<PurchaseFlowState>? _subscription;

  PurchaseStateNotifier(IAPService service)
      : super(service.currentState) {
    _subscription = service.stateStream.listen((newState) {
      state = newState;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for the current [PurchaseFlowState].
final purchaseStateProvider =
    StateNotifierProvider<PurchaseStateNotifier, PurchaseFlowState>((ref) {
  final service = ref.watch(iapServiceProvider);
  return PurchaseStateNotifier(service);
});

// ---------------------------------------------------------------------------
// Purchase errors
// ---------------------------------------------------------------------------

/// Tracks the most recent purchase error message.
class PurchaseErrorNotifier extends StateNotifier<String?> {
  StreamSubscription<String>? _subscription;

  PurchaseErrorNotifier(IAPService service) : super(null) {
    _subscription = service.errorStream.listen((message) {
      state = message;
    });
  }

  /// Clear the current error.
  void clear() {
    state = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for the most recent purchase error message.
final purchaseErrorProvider =
    StateNotifierProvider<PurchaseErrorNotifier, String?>((ref) {
  final service = ref.watch(iapServiceProvider);
  return PurchaseErrorNotifier(service);
});

// ---------------------------------------------------------------------------
// Action providers
// ---------------------------------------------------------------------------

/// Triggers a restore purchases flow.
///
/// Usage:
/// ```dart
/// final result = await ref.read(restorePurchasesProvider.future);
/// ```
final restorePurchasesProvider = FutureProvider<void>((ref) async {
  final service = ref.read(iapServiceProvider);
  await service.restorePurchases();
});

/// Triggers a purchase for a given product ID.
///
/// Usage:
/// ```dart
/// final result = await ref.read(buyProductProvider(productId).future);
/// ```
final buyProductProvider =
    FutureProvider.family<bool, String>((ref, productId) async {
  final service = ref.read(iapServiceProvider);
  return service.buyProductById(productId);
});

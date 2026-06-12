import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/services/iap/iap_service.dart';
import 'package:red_grid_link/services/iap/purchase_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal store stub — keeps IAPService away from InAppPurchase.instance
/// (which would spin up the real platform billing connection in tests).
class _StubIAP implements InAppPurchase {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  // IAPService() without an injected client touches InAppPurchase.instance,
  // which registers the platform implementation and needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IAPService.daysFromIsoPeriod', () {
    test('parses standard Play billing periods', () {
      expect(IAPService.daysFromIsoPeriod('P1W'), 7);
      expect(IAPService.daysFromIsoPeriod('P3D'), 3);
      expect(IAPService.daysFromIsoPeriod('P1M'), 30);
      expect(IAPService.daysFromIsoPeriod('P1Y'), 365);
      expect(IAPService.daysFromIsoPeriod('P2W'), 14);
    });

    test('is case-insensitive and rejects garbage', () {
      expect(IAPService.daysFromIsoPeriod('p1w'), 7);
      expect(IAPService.daysFromIsoPeriod(''), 0);
      expect(IAPService.daysFromIsoPeriod('1W'), 0);
      expect(IAPService.daysFromIsoPeriod('P1X'), 0);
    });
  });

  group('declared iOS trials', () {
    test('pro_annual declares a 7-day trial (matches the ASC intro offer)',
        () {
      expect(IAPProducts.declaredIosTrialDays[IAPProducts.proAnnual], 7);
    });

    test('no other product declares a trial', () {
      expect(IAPProducts.declaredIosTrialDays.length, 1);
    });
  });

  group('IAPService without store data', () {
    late IAPService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = IAPService(
        iap: _StubIAP(),
        purchaseHandler: PurchaseHandler(
          settingsRepository: SettingsRepository(prefs),
          onEntitlementChanged: (_) async {},
        ),
      );
    });

    tearDown(() => service.dispose());

    test('getPrice falls back to canonical prices', () {
      expect(service.getPrice(IAPProducts.proAnnual), '\$29.99/yr');
      expect(service.getPrice(IAPProducts.proMonthly), '\$3.99/mo');
      expect(service.getPrice(IAPProducts.lifetime), '\$149.99');
    });

    test('trialInfo is null when no products are loaded', () {
      // The declared iOS trial only applies when a StoreKit 2 product
      // instance is actually present — never on bare fallbacks.
      expect(service.trialInfo(IAPProducts.proAnnual), isNull);
    });
  });
}

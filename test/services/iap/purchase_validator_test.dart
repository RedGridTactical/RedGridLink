import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:red_grid_link/services/iap/purchase_validator.dart';

/// Unit tests for [PurchaseValidator] and [ClientOnlyPurchaseValidator].
///
/// Audit 2026-05-03 P1 coverage: validates the new validator abstraction
/// shipped to make the move from client-only to server-backed receipt
/// validation a single drop-in change.

PurchaseDetails _purchase({
  required String productID,
  required PurchaseStatus status,
  String localData = 'receipt-bytes',
  String serverData = 'apple-or-google-receipt',
  String source = 'app_store',
}) {
  return PurchaseDetails(
    productID: productID,
    purchaseID: 'pid-$productID',
    status: status,
    transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
    verificationData: PurchaseVerificationData(
      localVerificationData: localData,
      serverVerificationData: serverData,
      source: source,
    ),
  );
}

void main() {
  group('PurchaseVerification', () {
    test('valid factory has isValid=true and no reason', () {
      const v = PurchaseVerification.valid();
      expect(v.isValid, isTrue);
      expect(v.reason, isNull);
      expect(v.expiry, isNull);
    });

    test('valid factory accepts an authoritative expiry', () {
      final exp = DateTime.utc(2030, 1, 1);
      final v = PurchaseVerification.valid(expiry: exp);
      expect(v.isValid, isTrue);
      expect(v.expiry, exp);
    });

    test('invalid factory carries the rejection reason', () {
      const v = PurchaseVerification.invalid('refunded by user');
      expect(v.isValid, isFalse);
      expect(v.reason, 'refunded by user');
      expect(v.expiry, isNull);
    });
  });

  group('ClientOnlyPurchaseValidator', () {
    const validator = ClientOnlyPurchaseValidator();

    test('accepts every documented product id with PurchaseStatus.purchased',
        () async {
      const productIds = [
        'pro_monthly',
        'pro_annual',
        'pro_link_monthly',
        'pro_link_annual',
        'team_annual',
        'lifetime',
      ];
      for (final id in productIds) {
        final v = await validator.verify(
          _purchase(productID: id, status: PurchaseStatus.purchased),
        );
        expect(v.isValid, isTrue, reason: 'productID=$id should validate');
        expect(v.expiry, isNull,
            reason: 'client-only validator never returns an expiry');
      }
    });

    test('accepts PurchaseStatus.restored as a successful validation',
        () async {
      final v = await validator.verify(
        _purchase(productID: 'pro_monthly', status: PurchaseStatus.restored),
      );
      expect(v.isValid, isTrue);
    });

    test('rejects unknown productID with descriptive reason', () async {
      final v = await validator.verify(
        _purchase(
          productID: 'pro_bogus_quarterly',
          status: PurchaseStatus.purchased,
        ),
      );
      expect(v.isValid, isFalse);
      expect(v.reason, contains('Unknown productID'));
    });

    test('rejects pending status', () async {
      final v = await validator.verify(
        _purchase(productID: 'pro_monthly', status: PurchaseStatus.pending),
      );
      expect(v.isValid, isFalse);
      expect(v.reason, contains('Unsupported PurchaseStatus'));
    });

    test('rejects canceled status', () async {
      final v = await validator.verify(
        _purchase(productID: 'pro_monthly', status: PurchaseStatus.canceled),
      );
      expect(v.isValid, isFalse);
    });

    test('rejects error status', () async {
      final v = await validator.verify(
        _purchase(productID: 'pro_monthly', status: PurchaseStatus.error),
      );
      expect(v.isValid, isFalse);
    });

    test('rejects empty localVerificationData (no receipt)', () async {
      final v = await validator.verify(
        _purchase(
          productID: 'pro_monthly',
          status: PurchaseStatus.purchased,
          localData: '',
        ),
      );
      expect(v.isValid, isFalse);
      expect(v.reason, contains('localVerificationData'));
    });
  });

  group('PurchaseValidator interface (custom implementation)', () {
    /// Demonstrates that a server-backed validator can drop into the
    /// same interface and supply an authoritative expiry. Mirrors the
    /// shape RevenueCatValidator / OwnedServerValidator would take.
    test('custom validator can return an authoritative expiry', () async {
      final validator = _StubServerValidator(
        expiry: DateTime.utc(2027, 6, 15),
      );
      final v = await validator.verify(
        _purchase(productID: 'pro_annual', status: PurchaseStatus.purchased),
      );
      expect(v.isValid, isTrue);
      expect(v.expiry, DateTime.utc(2027, 6, 15));
    });

    test('custom validator can fail closed on refund', () async {
      const validator = _StubServerValidator.refunded();
      final v = await validator.verify(
        _purchase(productID: 'pro_annual', status: PurchaseStatus.purchased),
      );
      expect(v.isValid, isFalse);
      expect(v.reason, contains('refund'));
    });
  });
}

/// In-test stub mirroring the shape a real server-backed validator would
/// take when wired up to App Store Server API / Google Play Developer API.
class _StubServerValidator extends PurchaseValidator {
  final DateTime? expiry;
  final bool refunded;

  const _StubServerValidator({this.expiry}) : refunded = false;
  const _StubServerValidator.refunded()
      : expiry = null,
        refunded = true;

  @override
  Future<PurchaseVerification> verify(PurchaseDetails purchase) async {
    if (refunded) {
      return PurchaseVerification.invalid(
        'server reports a refund on transaction ${purchase.purchaseID}',
      );
    }
    return PurchaseVerification.valid(expiry: expiry);
  }
}

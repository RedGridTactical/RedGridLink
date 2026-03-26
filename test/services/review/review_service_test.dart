import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:red_grid_link/services/review/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake [InAppReview] for testing.
class FakeInAppReview implements InAppReview {
  bool availableResult = true;
  int requestReviewCallCount = 0;
  int openStoreListingCallCount = 0;

  @override
  Future<bool> isAvailable() async => availableResult;

  @override
  Future<void> requestReview() async {
    requestReviewCallCount++;
  }

  @override
  Future<void> openStoreListing({String? appStoreId, String? microsoftStoreId}) async {
    openStoreListingCallCount++;
  }
}

void main() {
  late FakeInAppReview fakeReview;
  late ReviewService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeReview = FakeInAppReview();
    service = ReviewService(inAppReview: fakeReview);
  });

  group('ReviewService', () {
    test('first completed session triggers review prompt', () async {
      final result = await service.maybePromptReview();

      expect(result, isTrue);
      expect(fakeReview.requestReviewCallCount, 1);

      // Verify SharedPreferences was updated.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasPromptedReview'), isTrue);
      expect(prefs.getInt('completedSessionCount'), 1);
    });

    test('second session does not trigger review prompt', () async {
      // First session — triggers prompt.
      await service.maybePromptReview();
      fakeReview.requestReviewCallCount = 0;

      // Second session — should not trigger.
      final result = await service.maybePromptReview();

      expect(result, isFalse);
      expect(fakeReview.requestReviewCallCount, 0);
    });

    test('already prompted flag prevents re-prompting', () async {
      SharedPreferences.setMockInitialValues({
        'hasPromptedReview': true,
        'completedSessionCount': 1,
      });
      final freshService = ReviewService(inAppReview: fakeReview);

      final result = await freshService.maybePromptReview();

      expect(result, isFalse);
      expect(fakeReview.requestReviewCallCount, 0);
    });

    test('handles isAvailable returning false gracefully', () async {
      fakeReview.availableResult = false;

      final result = await service.maybePromptReview();

      expect(result, isFalse);
      expect(fakeReview.requestReviewCallCount, 0);

      // Session count should still be incremented.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('completedSessionCount'), 1);
      // But hasPrompted should NOT be set (so it can try again if
      // availability changes — though count != 1 will block it).
      expect(prefs.getBool('hasPromptedReview'), isNull);
    });

    test('does not prompt when count is greater than 1 even if not prompted before', () async {
      SharedPreferences.setMockInitialValues({
        'completedSessionCount': 5,
      });
      final freshService = ReviewService(inAppReview: fakeReview);

      final result = await freshService.maybePromptReview();

      expect(result, isFalse);
      expect(fakeReview.requestReviewCallCount, 0);
    });
  });
}

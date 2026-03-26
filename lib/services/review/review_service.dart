import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences storage.
const String _hasPromptedReviewKey = 'hasPromptedReview';
const String _completedSessionCountKey = 'completedSessionCount';

/// Service that manages in-app review prompts.
///
/// Prompts the user to rate the app after their first completed Field Link
/// session, using the native StoreKit (iOS) / Play In-App Review (Android)
/// dialog. Never prompts more than once per install.
class ReviewService {
  final InAppReview _inAppReview;

  /// Creates a [ReviewService].
  ///
  /// An [InAppReview] instance can be injected for testing; otherwise
  /// the singleton [InAppReview.instance] is used.
  ReviewService({InAppReview? inAppReview})
      : _inAppReview = inAppReview ?? InAppReview.instance;

  /// Record a completed session and prompt for review if appropriate.
  ///
  /// Increments the completed session count and, if this is the first
  /// session and the user has not been prompted before, requests the
  /// native in-app review dialog.
  ///
  /// Returns `true` if the review dialog was requested, `false` otherwise.
  Future<bool> maybePromptReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Never prompt more than once per install.
    final hasPrompted = prefs.getBool(_hasPromptedReviewKey) ?? false;
    if (hasPrompted) return false;

    // Increment session count.
    final count = (prefs.getInt(_completedSessionCountKey) ?? 0) + 1;
    await prefs.setInt(_completedSessionCountKey, count);

    // Only prompt after the first completed session.
    if (count != 1) return false;

    // Check platform availability before requesting.
    final isAvailable = await _inAppReview.isAvailable();
    if (!isAvailable) return false;

    // Request the native review dialog.
    await _inAppReview.requestReview();

    // Mark as prompted so we never ask again.
    await prefs.setBool(_hasPromptedReviewKey, true);

    return true;
  }
}

/// Provider for the [ReviewService].
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

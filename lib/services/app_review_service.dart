import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/plugin.dart';

/// Service to manage in-app review requests
/// Shows review prompt once every 30 days
class AppReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Check if we should request review (once per month)
  static Future<bool> shouldRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Get last review request date
    final lastRequestTimestamp = prefs.getInt(prefLastReviewRequestDate);

    if (lastRequestTimestamp == null) {
      // First time - don't show immediately, wait for user to use app
      final count = prefs.getInt(prefReviewRequestCount) ?? 0;
      if (count < 3) {
        // Wait until user has opened app 3 times
        await prefs.setInt(prefReviewRequestCount, count + 1);
        return false;
      }
      return true;
    }

    // Check if 30 days (1 month) have passed
    final lastRequestDate = DateTime.fromMillisecondsSinceEpoch(lastRequestTimestamp);
    final now = DateTime.now();
    final daysSinceLastRequest = now.difference(lastRequestDate).inDays;

    debugPrint('📊 Review Check: Last request was $daysSinceLastRequest days ago');

    return daysSinceLastRequest >= 30; // 30 days = 1 month
  }

  /// Request in-app review
  static Future<bool> requestReview() async {
    try {
      debugPrint('⭐ Requesting in-app review...');

      // Check if review is available on this platform
      final isAvailable = await _inAppReview.isAvailable();
      debugPrint('📱 Review available: $isAvailable');

      if (isAvailable) {
        // Save the current timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(prefLastReviewRequestDate, DateTime.now().millisecondsSinceEpoch);

        // Request review
        await _inAppReview.requestReview();
        debugPrint('✅ In-app review requested successfully');
        return true;
      } else {
        debugPrint('⚠️ In-app review not available');
        debugPrint('   Reasons:');
        debugPrint('   - Running in debug/emulator mode');
        debugPrint('   - Not installed from Play Store');
        debugPrint('   - Device quota exceeded');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error requesting review: $e');
      return false;
    }
  }

  /// Open store listing (for manual review button)
  static Future<void> openStoreListing() async {
    try {
      debugPrint('🏪 Opening store listing...');

      if (await _inAppReview.isAvailable()) {
        await _inAppReview.openStoreListing(
          appStoreId: '', // Add your iOS App Store ID here
        );
        debugPrint('✅ Store listing opened');
      } else {
        debugPrint('⚠️ Store listing not available');
      }
    } catch (e) {
      debugPrint('❌ Error opening store listing: $e');
    }
  }

  /// Check and request review if conditions are met
  static Future<void> checkAndRequestReview() async {
    if (await shouldRequestReview()) {
      await requestReview();
    } else {
      debugPrint('⏭️ Skipping review request (not yet time)');
    }
  }

  /// Reset review request (for testing)
  static Future<void> resetReviewRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefLastReviewRequestDate);
    await prefs.remove(prefReviewRequestCount);
    debugPrint('🔄 Review request data reset');
  }

  /// Get days since last review request (for debugging)
  static Future<String> getReviewStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRequestTimestamp = prefs.getInt(prefLastReviewRequestDate);
    final count = prefs.getInt(prefReviewRequestCount) ?? 0;

    if (lastRequestTimestamp == null) {
      return 'Never requested (App opened: $count/3 times)';
    }

    final lastRequestDate = DateTime.fromMillisecondsSinceEpoch(lastRequestTimestamp);
    final now = DateTime.now();
    final daysSinceLastRequest = now.difference(lastRequestDate).inDays;

    return 'Last requested: $daysSinceLastRequest days ago (${30 - daysSinceLastRequest} days until next)';
  }
}

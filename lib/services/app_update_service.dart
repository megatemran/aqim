import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service to manage in-app updates (Android only)
class AppUpdateService {
  /// Check for available updates
  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      if (!Platform.isAndroid) {
        debugPrint('⚠️ In-app update only available on Android');
        return null;
      }

      debugPrint('🔍 Checking for app updates...');
      final updateInfo = await InAppUpdate.checkForUpdate();

      debugPrint('📊 Update available: ${updateInfo.updateAvailability}');
      debugPrint('   Immediate allowed: ${updateInfo.immediateUpdateAllowed}');
      debugPrint('   Flexible allowed: ${updateInfo.flexibleUpdateAllowed}');

      return updateInfo;
    } catch (e) {
      debugPrint('❌ Error checking for update: $e');
      return null;
    }
  }

  /// Start flexible update (user can continue using app while downloading)
  static Future<void> startFlexibleUpdate() async {
    try {
      if (!Platform.isAndroid) {
        debugPrint('⚠️ In-app update only available on Android');
        return;
      }

      debugPrint('📥 Starting flexible update...');
      await InAppUpdate.startFlexibleUpdate();
      debugPrint('✅ Flexible update started');
    } catch (e) {
      debugPrint('❌ Error starting flexible update: $e');
    }
  }

  /// Complete flexible update (install downloaded update)
  static Future<void> completeFlexibleUpdate() async {
    try {
      if (!Platform.isAndroid) {
        debugPrint('⚠️ In-app update only available on Android');
        return;
      }

      debugPrint('✅ Completing flexible update...');
      await InAppUpdate.completeFlexibleUpdate();
      debugPrint('✅ Flexible update completed');
    } catch (e) {
      debugPrint('❌ Error completing flexible update: $e');
    }
  }

  /// Start immediate update (blocks app until update is complete)
  static Future<void> startImmediateUpdate() async {
    try {
      if (!Platform.isAndroid) {
        debugPrint('⚠️ In-app update only available on Android');
        return;
      }

      debugPrint('⚡ Starting immediate update...');
      await InAppUpdate.performImmediateUpdate();
      debugPrint('✅ Immediate update completed');
    } catch (e) {
      debugPrint('❌ Error performing immediate update: $e');
    }
  }

  /// Check and prompt for flexible update
  static Future<void> checkAndPromptUpdate(BuildContext context) async {
    final updateInfo = await checkForUpdate();

    if (updateInfo == null) return;

    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      if (updateInfo.flexibleUpdateAllowed) {
        // Show dialog to user
        if (context.mounted) {
          _showUpdateDialog(context, isFlexible: true);
        }
      } else if (updateInfo.immediateUpdateAllowed) {
        // Force immediate update
        await startImmediateUpdate();
      }
    }
  }

  /// Show update dialog
  static void _showUpdateDialog(BuildContext context, {required bool isFlexible}) {
    showDialog(
      context: context,
      barrierDismissible: isFlexible, // Can dismiss if flexible
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: Colors.blue),
            SizedBox(width: 12),
            Text('Update Available'),
          ],
        ),
        content: Text(
          isFlexible
              ? 'A new version of Aqim is available. Update now to get the latest features and improvements.'
              : 'A critical update is required to continue using Aqim.',
        ),
        actions: [
          if (isFlexible)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (isFlexible) {
                startFlexibleUpdate();
              } else {
                startImmediateUpdate();
              }
            },
            child: Text('Update Now'),
          ),
        ],
      ),
    );
  }
}

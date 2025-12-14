import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to handle prayer alarm communication with Android native code
class PrayerAlarmService {
  static const MethodChannel _channel = MethodChannel(
    'net.brings2you.aqim/prayer_alarm',
  );

  static bool _isInitialized = false;
  static Function(String prayerName, String prayerTime)? _onAlarmCallback;

  /// Initialize the prayer alarm service
  /// Call this in main() or app initialization
  static Future<void> initialize({
    required Function(String prayerName, String prayerTime) onAlarmReceived,
  }) async {
    if (_isInitialized) {
      debugPrint('⚠️ PrayerAlarmService already initialized');
      return;
    }

    _onAlarmCallback = onAlarmReceived;

    // Listen for alarms from Android
    _channel.setMethodCallHandler(_handleMethodCall);

    _isInitialized = true;
    debugPrint('✅ PrayerAlarmService initialized');
  }

  /// Handle method calls from Android
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('📲 Received method call from Android: ${call.method}');

    if (call.method == 'onPrayerAlarm') {
      final args = call.arguments as Map<dynamic, dynamic>;
      final prayerName = args['prayerName'] as String;
      final prayerTime = args['prayerTime'] as String;
      final timestamp = args['timestamp'] as int;

      debugPrint('🔔 Prayer alarm received:');
      debugPrint('   Prayer: $prayerName');
      debugPrint('   Time: $prayerTime');
      debugPrint('   Timestamp: $timestamp');

      // Trigger callback
      if (_onAlarmCallback != null) {
        _onAlarmCallback!(prayerName, prayerTime);
      } else {
        debugPrint('⚠️ No callback registered for prayer alarm');
      }
    }
  }

  /// Schedule all prayer alarms in Android
  static Future<bool> scheduleAllPrayerAlarms() async {
    try {
      debugPrint('📅 Scheduling all prayer alarms...');
      final result = await _channel.invokeMethod('scheduleAllPrayerAlarms');
      debugPrint('✅ All prayer alarms scheduled: $result');
      return result as bool;
    } catch (e) {
      debugPrint('❌ Error scheduling prayer alarms: $e');
      return false;
    }
  }

  /// Cancel all prayer alarms in Android
  static Future<bool> cancelAllPrayerAlarms() async {
    try {
      debugPrint('🚫 Cancelling all prayer alarms...');
      final result = await _channel.invokeMethod('cancelAllPrayerAlarms');
      debugPrint('✅ All prayer alarms cancelled: $result');
      return result as bool;
    } catch (e) {
      debugPrint('❌ Error cancelling prayer alarms: $e');
      return false;
    }
  }

  /// Check if battery optimization is disabled for this app
  static Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final result = await _channel.invokeMethod(
        'isBatteryOptimizationDisabled',
      );
      debugPrint('🔋 Battery optimization disabled: $result');
      return result as bool;
    } catch (e) {
      debugPrint('❌ Error checking battery optimization: $e');
      return false;
    }
  }

  /// Request to disable battery optimization for this app
  /// Shows a system dialog asking user permission
  static Future<bool> requestDisableBatteryOptimization() async {
    try {
      debugPrint('🔋 Requesting battery optimization exemption...');
      final result = await _channel.invokeMethod(
        'requestDisableBatteryOptimization',
      );
      debugPrint('✅ Battery optimization request sent: $result');
      return result as bool;
    } catch (e) {
      debugPrint('❌ Error requesting battery optimization: $e');
      return false;
    }
  }

  /// Open battery optimization settings page
  static Future<bool> openBatteryOptimizationSettings() async {
    try {
      debugPrint('🔋 Opening battery optimization settings...');
      final result = await _channel.invokeMethod(
        'openBatteryOptimizationSettings',
      );
      debugPrint('✅ Battery optimization settings opened: $result');
      return result as bool;
    } catch (e) {
      debugPrint('❌ Error opening battery settings: $e');
      return false;
    }
  }
}

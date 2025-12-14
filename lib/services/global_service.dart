import 'dart:convert';

import 'package:aqim/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/plugin.dart';

// ============================================================================
// GLOBAL SETTINGS MANAGER
// ============================================================================

class GlobalService {
  // Singleton instance
  static final GlobalService _instance = GlobalService._internal();

  factory GlobalService() {
    return _instance;
  }

  GlobalService._internal();

  // ========================================================================
  // CACHED SETTINGS DATA
  // ========================================================================

  bool _isInitialized = false;

  // Notifications
  late bool notificationsEnabled;
  late bool soundEnabled;
  late bool vibrationEnabled;

  // Prayer-specific settings
  late bool subuhEnabled;
  late bool zohorEnabled;
  late bool asarEnabled;
  late bool maghribEnabled;
  late bool isyakEnabled;

  // Prayer sounds
  late String subuhSound;
  late String zohorSound;
  late String asarSound;
  late String maghribSound;
  late String isyakSound;

  // Prayer vibration settings
  late bool subuhVibrate;
  late bool zohorVibrate;
  late bool asarVibrate;
  late bool maghribVibrate;
  late bool isyakVibrate;

  // Prayer LED settings
  late bool subuhLed;
  late bool zohorLed;
  late bool asarLed;
  late bool maghribLed;
  late bool isyakLed;

  // Prayer fullscreen settings (true = fullscreen, false = notification only)
  late bool subuhFullscreen;
  late bool zohorFullscreen;
  late bool asarFullscreen;
  late bool maghribFullscreen;
  late bool isyakFullscreen;

  // Prayer reminder settings (before azan)
  late bool subuhReminder5Min;
  late bool subuhReminder10Min;
  late bool subuhReminder15Min;
  late bool zohorReminder5Min;
  late bool zohorReminder10Min;
  late bool zohorReminder15Min;
  late bool asarReminder5Min;
  late bool asarReminder10Min;
  late bool asarReminder15Min;
  late bool maghribReminder5Min;
  late bool maghribReminder10Min;
  late bool maghribReminder15Min;
  late bool isyakReminder5Min;
  late bool isyakReminder10Min;
  late bool isyakReminder15Min;

  // Time format
  late bool is24HourFormat;

  /// Check if settings are initialized
  bool get isInitialized => _isInitialized;

  // ========================================================================
  // INITIALIZATION
  // ========================================================================

  /// Load all settings from SharedPreferences into memory
  Future<void> initialize() async {
    if (_isInitialized) return; // ✅ Prevent duplicate initialization

    final prefs = await SharedPreferences.getInstance();

    // Notifications
    notificationsEnabled = prefs.getBool(prefNotificationsEnabled) ?? true;
    soundEnabled = prefs.getBool(prefSoundEnabled) ?? true;
    vibrationEnabled = prefs.getBool(prefVibrationEnabled) ?? true;

    // Prayer-specific settings
    subuhEnabled = prefs.getBool(prefSubuhEnabled) ?? true;
    zohorEnabled = prefs.getBool(prefZohorEnabled) ?? true;
    asarEnabled = prefs.getBool(prefAsarEnabled) ?? true;
    maghribEnabled = prefs.getBool(prefMaghribEnabled) ?? true;
    isyakEnabled = prefs.getBool(prefIsyakEnabled) ?? true;

    // Prayer sounds (defaults match onboarding defaults)
    subuhSound = prefs.getString(prefSubuhSound) ?? 'azan_subuh_tv3_2018';
    zohorSound = prefs.getString(prefZohorSound) ?? 'azan_zohor_ashfaq_hussain';
    asarSound = prefs.getString(prefAsarSound) ?? 'azan_asar_tv1_2018';
    maghribSound = prefs.getString(prefMaghribSound) ?? 'azan_maghrib_tv3_2018';
    isyakSound = prefs.getString(prefIsyakSound) ?? 'azan_isyak_munif_hijjaz';

    // Prayer vibration settings
    subuhVibrate = prefs.getBool(prefSubuhVibrate) ?? true;
    zohorVibrate = prefs.getBool(prefZohorVibrate) ?? true;
    asarVibrate = prefs.getBool(prefAsarVibrate) ?? true;
    maghribVibrate = prefs.getBool(prefMaghribVibrate) ?? true;
    isyakVibrate = prefs.getBool(prefIsyakVibrate) ?? true;

    // Prayer LED settings
    subuhLed = prefs.getBool(prefSubuhLed) ?? true;
    zohorLed = prefs.getBool(prefZohorLed) ?? true;
    asarLed = prefs.getBool(prefAsarLed) ?? true;
    maghribLed = prefs.getBool(prefMaghribLed) ?? true;
    isyakLed = prefs.getBool(prefIsyakLed) ?? true;

    // Prayer fullscreen settings
    subuhFullscreen = prefs.getBool(prefSubuhFullscreen) ?? true;
    zohorFullscreen = prefs.getBool(prefZohorFullscreen) ?? true;
    asarFullscreen = prefs.getBool(prefAsarFullscreen) ?? true;
    maghribFullscreen = prefs.getBool(prefMaghribFullscreen) ?? true;
    isyakFullscreen = prefs.getBool(prefIsyakFullscreen) ?? true;

    // Prayer reminder settings
    subuhReminder5Min = prefs.getBool(prefSubuhReminder5Min) ?? false;
    subuhReminder10Min = prefs.getBool(prefSubuhReminder10Min) ?? false;
    subuhReminder15Min = prefs.getBool(prefSubuhReminder15Min) ?? false;
    zohorReminder5Min = prefs.getBool(prefZohorReminder5Min) ?? false;
    zohorReminder10Min = prefs.getBool(prefZohorReminder10Min) ?? false;
    zohorReminder15Min = prefs.getBool(prefZohorReminder15Min) ?? false;
    asarReminder5Min = prefs.getBool(prefAsarReminder5Min) ?? false;
    asarReminder10Min = prefs.getBool(prefAsarReminder10Min) ?? false;
    asarReminder15Min = prefs.getBool(prefAsarReminder15Min) ?? false;
    maghribReminder5Min = prefs.getBool(prefMaghribReminder5Min) ?? false;
    maghribReminder10Min = prefs.getBool(prefMaghribReminder10Min) ?? false;
    maghribReminder15Min = prefs.getBool(prefMaghribReminder15Min) ?? false;
    isyakReminder5Min = prefs.getBool(prefIsyakReminder5Min) ?? false;
    isyakReminder10Min = prefs.getBool(prefIsyakReminder10Min) ?? false;
    isyakReminder15Min = prefs.getBool(prefIsyakReminder15Min) ?? false;

    // Time format
    is24HourFormat = prefs.getBool(prefIs24HourFormat) ?? true;

    _isInitialized = true;

    //NEW SETTINGS
    await prefs.setString('subuhAzanReminderList', jsonEncode([5]));
    await prefs.setString('zohorAzanReminderList', jsonEncode([5]));
    await prefs.setString('asarAzanReminderList', jsonEncode([5]));
    await prefs.setString('maghribAzanReminderList', jsonEncode([5]));
    await prefs.setString('isyakAzanReminderList', jsonEncode([5]));

    await prefs.setInt('subuhSolatReminder', 5);
    await prefs.setInt('zohorSolatReminder', 5);
    await prefs.setInt('asarSolatReminder', 5);
    await prefs.setInt('maghribSolatReminder', 5);
    await prefs.setInt('isyakSolatReminder', 5);

    Map<String, dynamic> prayerSettings = {
      'subuh': {
        'enabled': true,
        'sound': 'azan_subuh_tv3_2018',
        'vibrate': true,
        'led': true,
        'fullscreen': true,
        'reminder5Min': false,
        'reminder10Min': false,
        'reminder15Min': false,
        'beforeAzanReminder': [5, 10, 15],
        'solatReminder': 10,
        'ledColor': 0xFFFF0000,
      },
      'zohor': {
        'enabled': true,
        'sound': 'azan_zohor_ashfaq_hussain',
        'vibrate': true,
        'led': true,
        'fullscreen': true,
        'reminder5Min': false,
        'reminder10Min': false,
        'reminder15Min': false,
        'beforeAzanReminder': [5, 10, 15],
        'solatReminder': 10,
        'ledColor': 0xFFFF0000,
      },
      'asar': {
        'enabled': true,
        'sound': 'azan_asar_tv1_2018',
        'vibrate': true,
        'led': true,
        'fullscreen': true,
        'reminder5Min': false,
        'reminder10Min': false,
        'reminder15Min': false,
        'beforeAzanReminder': [5, 10, 15],
        'solatReminder': 10,
        'ledColor': 0xFFFF0000,
      },
      'maghrib': {
        'enabled': true,
        'sound': 'azan_maghrib_tv3_2018',
        'vibrate': true,
        'led': true,
        'fullscreen': true,
        'reminder5Min': false,
        'reminder10Min': false,
        'reminder15Min': false,
        'beforeAzanReminder': [5, 10, 15],
        'solatReminder': 10,
        'ledColor': 0xFFFF0000,
      },
      'isyak': {
        'enabled': true,
        'sound': 'azan_isyak_munif_hijjaz',
        'vibrate': true,
        'led': true,
        'fullscreen': true,
        'reminder5Min': false,
        'reminder10Min': false,
        'reminder15Min': false,
        'beforeAzanReminder': [5, 10, 15],
        'solatReminder': 10,
        'ledColor': 0xFFFF0000,
      },
    };

    await prefs.setString('prayerSettings', jsonEncode(prayerSettings));
  }

  // ========================================================================
  // GETTERS - Quick access to settings
  // ========================================================================

  /// Get all prayer settings in one map
  Map<String, dynamic> getAllPrayerSettings() {
    return {
      'subuh': {'enabled': subuhEnabled, 'sound': subuhSound},
      'zohor': {'enabled': zohorEnabled, 'sound': zohorSound},
      'asar': {'enabled': asarEnabled, 'sound': asarSound},
      'maghrib': {'enabled': maghribEnabled, 'sound': maghribSound},
      'isyak': {'enabled': isyakEnabled, 'sound': isyakSound},
    };
  }

  /// Get specific prayer settings
  Map<String, dynamic> getPrayerSettings(String prayerKey) {
    final key = prayerKey.toLowerCase();
    if (key == 'subuh') {
      return {'enabled': subuhEnabled, 'sound': subuhSound};
    } else if (key == 'zohor') {
      return {'enabled': zohorEnabled, 'sound': zohorSound};
    } else if (key == 'asar') {
      return {'enabled': asarEnabled, 'sound': asarSound};
    } else if (key == 'maghrib') {
      return {'enabled': maghribEnabled, 'sound': maghribSound};
    } else if (key == 'isyak') {
      return {'enabled': isyakEnabled, 'sound': isyakSound};
    }
    return {'enabled': true, 'sound': 'azan_isyak_munif_hijjaz'};
  }

  /// Check if specific prayer is enabled
  bool isPrayerEnabled(String prayerKey) {
    final key = prayerKey.toLowerCase();
    if (key == 'subuh') {
      return subuhEnabled;
    } else if (key == 'zohor') {
      return zohorEnabled;
    } else if (key == 'asar') {
      return asarEnabled;
    } else if (key == 'maghrib') {
      return maghribEnabled;
    } else if (key == 'isyak') {
      return isyakEnabled;
    }
    return true;
  }

  /// Get prayer sound file
  String getPrayerSound(String prayerKey) {
    final key = prayerKey.toLowerCase();
    if (key == 'subuh') {
      return subuhSound;
    } else if (key == 'zohor') {
      return zohorSound;
    } else if (key == 'asar') {
      return asarSound;
    } else if (key == 'maghrib') {
      return maghribSound;
    } else if (key == 'isyak') {
      return isyakSound;
    }
    return 'azan_isyak_munif_hijjaz';
  }

  // ========================================================================
  // SETTERS - Update settings and persist
  // ========================================================================

  /// Update a setting and persist to SharedPreferences
  Future<void> updateSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }

    // Update the in-memory cache
    _updateMemoryCache(key, value);
  }

  /// Update multiple settings at once
  Future<void> updateMultipleSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();

    for (var entry in settings.entries) {
      if (entry.value is bool) {
        await prefs.setBool(entry.key, entry.value);
      } else if (entry.value is String) {
        await prefs.setString(entry.key, entry.value);
      }
      _updateMemoryCache(entry.key, entry.value);
    }
  }

  /// Update in-memory cache based on key
  void _updateMemoryCache(String key, dynamic value) {
    // Notifications
    if (key == prefNotificationsEnabled) {
      notificationsEnabled = value;
    } else if (key == prefSoundEnabled) {
      soundEnabled = value;
    } else if (key == prefVibrationEnabled) {
      vibrationEnabled = value;
    }
    // Prayer settings
    else if (key == prefSubuhEnabled) {
      subuhEnabled = value;
    } else if (key == prefZohorEnabled) {
      zohorEnabled = value;
    } else if (key == prefAsarEnabled) {
      asarEnabled = value;
    } else if (key == prefMaghribEnabled) {
      maghribEnabled = value;
    } else if (key == prefIsyakEnabled) {
      isyakEnabled = value;
    }
    // Prayer sounds
    else if (key == prefSubuhSound) {
      subuhSound = value;
    } else if (key == prefZohorSound) {
      zohorSound = value;
    } else if (key == prefAsarSound) {
      asarSound = value;
    } else if (key == prefMaghribSound) {
      maghribSound = value;
    } else if (key == prefIsyakSound) {
      isyakSound = value;
    }
    // Prayer vibration
    else if (key == prefSubuhVibrate) {
      subuhVibrate = value;
    } else if (key == prefZohorVibrate) {
      zohorVibrate = value;
    } else if (key == prefAsarVibrate) {
      asarVibrate = value;
    } else if (key == prefMaghribVibrate) {
      maghribVibrate = value;
    } else if (key == prefIsyakVibrate) {
      isyakVibrate = value;
    }
    // Prayer LED
    else if (key == prefSubuhLed) {
      subuhLed = value;
    } else if (key == prefZohorLed) {
      zohorLed = value;
    } else if (key == prefAsarLed) {
      asarLed = value;
    } else if (key == prefMaghribLed) {
      maghribLed = value;
    } else if (key == prefIsyakLed) {
      isyakLed = value;
    }
    // Prayer fullscreen
    else if (key == prefSubuhFullscreen) {
      subuhFullscreen = value;
    } else if (key == prefZohorFullscreen) {
      zohorFullscreen = value;
    } else if (key == prefAsarFullscreen) {
      asarFullscreen = value;
    } else if (key == prefMaghribFullscreen) {
      maghribFullscreen = value;
    } else if (key == prefIsyakFullscreen) {
      isyakFullscreen = value;
    }
    // Prayer reminders
    else if (key == prefSubuhReminder5Min) {
      subuhReminder5Min = value;
    } else if (key == prefSubuhReminder10Min) {
      subuhReminder10Min = value;
    } else if (key == prefSubuhReminder15Min) {
      subuhReminder15Min = value;
    } else if (key == prefZohorReminder5Min) {
      zohorReminder5Min = value;
    } else if (key == prefZohorReminder10Min) {
      zohorReminder10Min = value;
    } else if (key == prefZohorReminder15Min) {
      zohorReminder15Min = value;
    } else if (key == prefAsarReminder5Min) {
      asarReminder5Min = value;
    } else if (key == prefAsarReminder10Min) {
      asarReminder10Min = value;
    } else if (key == prefAsarReminder15Min) {
      asarReminder15Min = value;
    } else if (key == prefMaghribReminder5Min) {
      maghribReminder5Min = value;
    } else if (key == prefMaghribReminder10Min) {
      maghribReminder10Min = value;
    } else if (key == prefMaghribReminder15Min) {
      maghribReminder15Min = value;
    } else if (key == prefIsyakReminder5Min) {
      isyakReminder5Min = value;
    } else if (key == prefIsyakReminder10Min) {
      isyakReminder10Min = value;
    } else if (key == prefIsyakReminder15Min) {
      isyakReminder15Min = value;
    }
    // Time format
    else if (key == prefIs24HourFormat) {
      is24HourFormat = value;
    }
  }

  // ========================================================================
  // CONVENIENCE METHODS
  // ========================================================================

  /// Check if notifications are fully enabled (master + sound)
  bool areNotificationsWithSoundEnabled() {
    return notificationsEnabled && soundEnabled;
  }

  /// Check if specific prayer should have sound
  bool shouldPlaySound(String prayerKey) {
    return notificationsEnabled && soundEnabled && isPrayerEnabled(prayerKey);
  }

  /// Get notification params for background task
  Map<String, dynamic> getPrayerNotificationParams(
    String prayerKey,
    String prayerName,
    String time,
  ) {
    return {
      'name': prayerName,
      'time': time,
      'file': getPrayerSound(prayerKey),
      'soundEnabled': shouldPlaySound(prayerKey),
    };
  }

  // ============================================================================
  // CACHED LOCATION
  // ============================================================================

  Map<String, dynamic>? _cachedLocationData;
  Future<Map<String, dynamic>> getLocationData() async {
    try {
      // ✅ Return cached if available
      if (_cachedLocationData != null) {
        debugPrint('⚡ Using location from memory cache');
        return _cachedLocationData!;
      }

      // debugPrint('📍 Fetching location data...');

      // ✅ Get location using LocationService singleton
      final locationService = LocationService();
      _cachedLocationData = await locationService.loadLocationFast();

      //  debugPrint('✅ Location data loaded successfully');
      return _cachedLocationData!;
    } catch (e) {
      //  debugPrint('❌ Error getting location: $e');

      // ✅ Create a safe fallback location for Malaysia
      final fallbackLocation = _createFallbackLocation();
      _cachedLocationData = fallbackLocation;

      //  debugPrint('⚠️ Using fallback location: ${fallbackLocation['lokasi']}');
      return fallbackLocation;
    }
  }

  /// Create a fallback location (Kuala Lumpur)
  Map<String, dynamic> _createFallbackLocation() {
    return {
      'name': 'Kuala Lumpur',
      'street': '',
      'isoCountryCode': 'MY',
      'country': 'Malaysia',
      'postalCode': '50000',
      'administrativeArea': 'Wilayah Persekutuan',
      'subAdministrativeArea': '',
      'locality': 'Kuala Lumpur',
      'subLocality': '',
      'thoroughfare': '',
      'subThoroughfare': '',
      'lat': 3.1390,
      'lon': 101.6869,
      'lokasi': 'Kuala Lumpur',
      'timezone': 'Asia/Kuala_Lumpur',
    };
  }

  // ============================================================================
  // ADDITIONAL HELPER METHODS
  // ============================================================================

  /// Clear cached location (forces refresh on next call)
  Future<void> clearCachedLocation() async {
    try {
      final locationService = LocationService();
      await locationService.clearLocationCache();
      _cachedLocationData = null;
      //  debugPrint('🗑️ Location cache cleared');
    } catch (e) {
      //debugPrint('❌ Error clearing location cache: $e');
    }
  }

  /// Refresh location data (ignores cache)
  Future<void> refreshLocationData() async {
    try {
      // debugPrint('🔄 Refreshing location data...');
      _cachedLocationData = null;
      await getLocationData();
      //  debugPrint('✅ Location refreshed');
    } catch (e) {
      // debugPrint('❌ Error refreshing location: $e');
    }
  }
}

// ============================================================================
// GLOBAL INSTANCE - Access from anywhere
// ============================================================================

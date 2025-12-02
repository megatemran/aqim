// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';
import 'prayer_times_service.dart';

@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  if (uri?.host == 'refresh') {
    debugPrint("Widget requested refresh...");
    try {
      await HomeWidget.updateWidget();
    } on PlatformException catch (e) {
      debugPrint('⚠️ HomeWidget update failed: $e');
    }
  }
}

class HomeWidgetService {
  String appGroupId = "net.brings2you.aqim";

  Future<void> homeWidgetInit() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.registerInteractivityCallback(backgroundCallback);
    } catch (e) {
      print('Error HomeWidgetInit: $e');
    }
  }

  Future<void> addWidgetToHomeScreen({
    required BuildContext context,
    required String androidName,
    required String qualifiedAndroidName,
  }) async {
    try {
      final cs = Theme.of(context).colorScheme;
      bool? isSupported = await HomeWidget.isRequestPinWidgetSupported();

      if (isSupported == true) {
        // Tutup app sebelum pin widget
        await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');

        print('✅ Widget pin supported. Proceeding to add widget...');
        await HomeWidget.requestPinWidget(
          androidName: androidName,
          qualifiedAndroidName: qualifiedAndroidName,
        );
      } else {
        print('❌ Pin widget not supported on this device');
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Tidak Disokong',
                style: TextStyle(color: cs.onSurface, fontSize: 24.sp),
              ),
              content: Text(
                'Peranti anda tidak menyokong fungsi untuk pin widget ke skrin utama. '
                'Sila semak versi Android anda atau gunakan launcher lain yang menyokong fungsi ini.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error AddWidgetToHomeScreen: $e');
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ralat'),
            content: Text('Ralat semasa menambah widget: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> updateWidget() async {
    try {
      // Try to get fresh location, but use cached if timeout
      Map<String, dynamic>? locationData;

      try {
        final locationService = LocationService();

        // Try to get current location with timeout
        final position = await locationService.getCurrentLocation().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⏱️ Location timeout - will use cached data');
            throw TimeoutException('Location timeout');
          },
        );

        locationData = await locationService.getDetailedLocation(
          position.latitude,
          position.longitude,
        );

        debugPrint('✅ Got fresh location data');
      } on TimeoutException catch (e) {
        debugPrint('⏱️ Location fetch timeout: $e');
        // Try to get cached location data
        locationData = await _getCachedLocationData();

        if (locationData == null) {
          debugPrint('❌ No cached location data available');
          return;
        }
        debugPrint('✅ Using cached location data');
      } catch (e) {
        debugPrint('❌ Error getting location: $e');
        // Try to get cached location data
        locationData = await _getCachedLocationData();

        if (locationData == null) {
          debugPrint('❌ No cached location data available');
          return;
        }
        debugPrint('✅ Using cached location data');
      }

      // Get prayer data
      final prayerService = PrayerTimesService();
      final prayerData = await prayerService.getPrayerTimesData(locationData);

      // Cache location data for future use
      await _cacheLocationData(locationData);

      // Convert list into a lookup map
      final prayersMap = {
        for (final p in prayerData.prayers) p.name.toLowerCase(): p.time,
      };

      // Save data to widget storage
      await HomeWidget.saveWidgetData<String>('location', prayerData.location);
      await HomeWidget.saveWidgetData<String>(
        'subuh',
        formatTime(prayersMap['subuh'] ?? '-'),
      );
      await HomeWidget.saveWidgetData<String>(
        'zohor',
        formatTime(prayersMap['zohor'] ?? '-'),
      );
      await HomeWidget.saveWidgetData<String>(
        'asar',
        formatTime(prayersMap['asar'] ?? '-'),
      );
      await HomeWidget.saveWidgetData<String>(
        'maghrib',
        formatTime(prayersMap['maghrib'] ?? '-'),
      );
      await HomeWidget.saveWidgetData<String>(
        'isyak',
        formatTime(prayersMap['isyak'] ?? '-'),
      );

      // Save last update time
      final now = DateTime.now();
      await HomeWidget.saveWidgetData<String>(
        'last_update',
        formatMalayDate(now),
      );

      debugPrint('✅ Data saved to SharedPreferences');

      // Update the widget
      await HomeWidget.updateWidget(
        name: "androidWidgetName",
        iOSName: 'WaktuSolatWidgetReceiver',
        androidName: 'WaktuSolatWidgetReceiver',
        qualifiedAndroidName: "net.brings2you.aqim.WaktuSolatWidgetReceiver",
      );

      debugPrint('✅ Widget update completed successfully');
    } catch (e, s) {
      debugPrint('❌ Error updating widget: $e');
      debugPrint('Stack trace: $s');
    }
  }

  /// Cache location data for offline use
  Future<void> _cacheLocationData(Map<String, dynamic> locationData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Handle both 'lat'/'lon' and 'latitude'/'longitude' keys
      final lat = (locationData['lat'] ?? locationData['latitude']) as double?;
      final lon = (locationData['lon'] ?? locationData['longitude']) as double?;

      if (lat != null && lon != null) {
        await prefs.setDouble('cached_latitude', lat);
        await prefs.setDouble('cached_longitude', lon);
        await prefs.setString('cached_locality', locationData['locality'] ?? '');
        await prefs.setString(
          'cached_administrativeArea',
          locationData['administrativeArea'] ?? '',
        );
        await prefs.setString('cached_country', locationData['country'] ?? '');
        await prefs.setInt(
          'cached_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );
        debugPrint('✅ Location data cached');
      } else {
        debugPrint('⚠️ Invalid location data - lat or lon is null');
      }
    } catch (e) {
      debugPrint('❌ Error caching location data: $e');
    }
  }

  /// Get cached location data
  Future<Map<String, dynamic>?> _getCachedLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final latitude = prefs.getDouble('cached_latitude');
      final longitude = prefs.getDouble('cached_longitude');

      if (latitude == null || longitude == null) {
        return null;
      }

      final timestamp = prefs.getInt('cached_timestamp') ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;

      // If cache is older than 7 days, consider it stale
      if (cacheAge > 7 * 24 * 60 * 60 * 1000) {
        debugPrint(
          '⚠️ Cached location data is too old (${cacheAge ~/ (24 * 60 * 60 * 1000)} days)',
        );
        return null;
      }

      return {
        'latitude': latitude,
        'longitude': longitude,
        'locality': prefs.getString('cached_locality') ?? '',
        'administrativeArea':
            prefs.getString('cached_administrativeArea') ?? '',
        'country': prefs.getString('cached_country') ?? '',
      };
    } catch (e) {
      debugPrint('❌ Error getting cached location data: $e');
      return null;
    }
  }

  String formatTime(String time) {
    try {
      final parsed = DateFormat("HH:mm").parse(time);
      return DateFormat("h.mm a").format(parsed).toLowerCase();
    } catch (_) {
      return time;
    }
  }

  String formatMalayDate(DateTime now) {
    const malayMonths = [
      "Jan",
      "Feb",
      "Mac",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Ogo",
      "Sep",
      "Okt",
      "Nov",
      "Dis",
    ];
    final day = now.day;
    final month = malayMonths[now.month - 1];
    final year = now.year;
    final time = DateFormat('h.mm a').format(now).toLowerCase();
    return "$day $month $year, $time";
  }
}

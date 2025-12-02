import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_time_model.dart';
import '../models/zone_model.dart';

class PrayerTimesService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      validateStatus: (status) => status != null && status < 500,
      followRedirects: true,
      maxRedirects: 3,
    ),
  );

  /// Main function to get prayer times data from malaysia and other country
  Future<PrayerTimeData> getPrayerTimesData(
    Map<String, dynamic> locationData, {
    bool forceFresh = false,
  }) async {
    try {
      final cachedData = await _loadPrayerTimeFromCache();
      final todayDate =
          _getTodayDate(); // Get today's date in DD-MM-YYYY format

      //  print('📅 Today\'s Date: $todayDate');
      if (cachedData != null) {
        //   print('📅 Cached Date: ${cachedData.date}');
      }

      // Check if cache exists, location matches, AND date is same
      // Skip cache if forceFresh is true
      if (!forceFresh &&
          cachedData != null &&
          cachedData.location == locationData['lokasi'] &&
          cachedData.date == todayDate) {
        //   print('✅✅✅ Using cached data: ${cachedData.location}');
        return cachedData;
      }

      // Cache is stale or different location - fetch new data
      if (cachedData != null && cachedData.date != todayDate) {
        // print(
        //   '⚠️ Cache is outdated (${cachedData.date} vs $todayDate), fetching new data...',
        // );
      } else if (cachedData != null &&
          cachedData.location != locationData['lokasi']) {
        // print(
        //   '⚠️ Location changed (${cachedData.location} vs ${locationData['lokasi']}), fetching new data...',
        // );
      } else {
        // print('📥 No cache available, fetching new data...');
      }

      // Fetch new data
      String countryCode = locationData['isoCountryCode'] ?? 'MY';

      PrayerTimeData prayerTimeData;

      if (countryCode == 'MY') {
        try {
          // Try JAKIM API first for Malaysia
          String zoneCode = _findZoneByLocationMY(locationData);
          prayerTimeData = await _getJakimData(zoneCode, locationData);
        } catch (jakimError) {
          debugPrint('⚠️ JAKIM API failed, falling back to AlAdhan: $jakimError');
          // Fallback to AlAdhan API if JAKIM fails
          prayerTimeData = await _getWorldPrayerTimesData(locationData);
        }
      } else {
        prayerTimeData = await _getWorldPrayerTimesData(locationData);
      }

      // Save to cache
      await _savePrayerTimeToCache(prayerTimeData);

      return prayerTimeData;
    } catch (e) {
      debugPrint('❌ Error getPrayerTimesData: $e');

      // Tier 2: Try to fall back to cached data even if date/location doesn't match
      final cachedData = await _loadPrayerTimeFromCache();
      if (cachedData != null) {
        debugPrint('⚠️ Falling back to cached data from ${cachedData.date}');
        return cachedData;
      }

      // Tier 3: Last resort - return default prayer times
      debugPrint('⚠️ All APIs failed and no cache, using default prayer times');
      return _getDefaultPrayerTimes(locationData);
    }
  }

  /// Get today's date in DD-MM-YYYY format
  String _getTodayDate() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    return '$day-$month-$year';
  }

  /// Save prayer time data to cache
  Future<void> _savePrayerTimeToCache(PrayerTimeData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data.toJson());
      await prefs.setString('cached_prayer_time', jsonString);
      // print('💾 Prayer times saved to cache');
      // print('📦 Cached data: $jsonString');
    } catch (e) {
      debugPrint('❌ Error saving to cache: $e');
    }
  }

  /// Load prayer time data from cache
  Future<PrayerTimeData?> _loadPrayerTimeFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_prayer_time');

      if (cached != null) {
        // print('📥 Loading from cache...');
        // print('📦 Cached string: $cached');

        final decoded = jsonDecode(cached);
        final prayerTimeData = PrayerTimeData.fromJson(decoded);

        // print('✅ Successfully loaded from cache');
        // print('🕌 Prayers: ${prayerTimeData.prayers}');

        return prayerTimeData;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error loading from cache: $e');
      return null;
    }
  }

  Future<PrayerTimeData> _getWorldPrayerTimesData(
    Map<String, dynamic> locationData,
  ) async {
    try {
      // 🌍 AlAdhan API example:
      // https://api.aladhan.com/v1/timings/{timestamp}?latitude=5.0081&longitude=100.5394&method=4
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      Response? response;
      int retries = 0;
      const maxRetries = 3;

      while (retries < maxRetries) {
        try {
          response = await _dio.get(
            'https://api.aladhan.com/v1/timings/$timestamp',
            queryParameters: {
              'latitude': locationData['lat'],
              'longitude': locationData['lon'],
              'method': 4, // Muslim World League (default)
            },
          );

          // If successful, break out of retry loop
          break;
        } catch (e) {
          retries++;
          if (retries >= maxRetries) {
            rethrow; // Give up after max retries
          }

          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: retries * 2));
          debugPrint('🔄 Retrying AlAdhan API... Attempt $retries/$maxRetries');
        }
      }

      if (response != null &&
          response.statusCode == 200 &&
          response.data['data'] != null) {
        final data = response.data['data'];
        final timings = data['timings'] as Map<String, dynamic>;

        // 🕌 Match JAKIM format & naming (Imsak → Isyak)
        final prayers = [
          PrayerTime(
            name: 'Imsak',
            time: timings['Imsak'] ?? '--:--',
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Subuh',
            time: timings['Fajr'] ?? '--:--',
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Syuruk',
            time: timings['Sunrise'] ?? '--:--',
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Zohor',
            time: timings['Dhuhr'] ?? '--:--',
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Asar',
            time: timings['Asr'] ?? '--:--',
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Maghrib',
            time: timings['Maghrib'] ?? '--:--',
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Isyak',
            time: timings['Isha'] ?? '--:--',
            isPassed: false,
            isNext: false,
          ),
        ];

        // 🕒 Format date to match JAKIM (e.g., 24-10-2025)
        final gregorianDate = data['date']['gregorian']['date'] ?? '';
        final hijriDate = data['date']['hijri']['date'] ?? '';

        // 🧭 Build PrayerTimeData with same key order and field structure as JAKIM
        return PrayerTimeData(
          hijri: hijriDate,
          date: gregorianDate,
          prayers: _updatePrayerStatus(prayers),
          zone: data['meta']['timezone'] ?? '',
          location:
              locationData['lokasi'] ??
              (data['meta']['method']['name'] ?? 'Unknown'),
          userLocationData: locationData,
          sumber: 'AlAdhan',
          sumberWebsite: 'https://www.aladhan.com',
        );
      } else {
        throw Exception('Invalid response from AlAdhan API');
      }
    } catch (e) {
      debugPrint('Error getWorldPrayerTimesData: $e');
      throw Exception('Error getWorldPrayerTimesData: $e');
    }
  }

  Future<PrayerTimeData> _getJakimData(
    String zone,
    Map<String, dynamic> locationData,
  ) async {
    try {
      //https://www.e-solat.gov.my/index.php?r=esolatApi/TakwimSolat&period=today&zone=MLK01
      Response? response;
      int retries = 0;
      const maxRetries = 3;

      while (retries < maxRetries) {
        try {
          response = await _dio.get(
            'https://www.e-solat.gov.my/index.php',
            queryParameters: {
              'r': 'esolatApi/TakwimSolat',
              'period': 'today',
              'zone': zone,
            },
          );

          // If successful, break out of retry loop
          break;
        } catch (e) {
          retries++;
          if (retries >= maxRetries) {
            rethrow; // Give up after max retries
          }

          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: retries * 2));
          debugPrint('🔄 Retrying JAKIM API... Attempt $retries/$maxRetries');
        }
      }

      if (response != null &&
          response.data['prayerTime'] != null &&
          response.data['prayerTime'].isNotEmpty) {
        final data = response.data['prayerTime'][0];

        final prayers = [
          PrayerTime(
            name: 'Imsak',
            time: _normalizeTime(data['imsak']),
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Subuh',
            time: _normalizeTime(data['fajr']),
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Syuruk',
            time: _normalizeTime(data['syuruk']),
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Zohor',
            time: _normalizeTime(data['dhuhr']),
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Asar',
            time: _normalizeTime(data['asr']),
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Maghrib',
            time: _normalizeTime(data['maghrib']),
            isPassed: false,
            isNext: false,
          ),
          PrayerTime(
            name: 'Isyak',
            time: _normalizeTime(data['isha']),
            isPassed: false,
            isNext: false,
          ),
        ];
        return PrayerTimeData(
          hijri: _normalizeHijriDate(data['hijri']),
          date: _normalizeDate(data['date']),
          prayers: _updatePrayerStatus(prayers),
          zone: zone,
          location: locationData['lokasi'] ?? 'Unknown',
          userLocationData: locationData,
          sumber: 'JAKIM',
          sumberWebsite: 'https://www.e-solat.gov.my',
        );
      }
      debugPrint('PrayerTimeDataJakim.. $PrayerTimeData');
      throw Exception('No prayer time data available');
    } catch (e) {
      debugPrint('Error getJakimData: $e');
      throw Exception('No prayer time data available');
    }
  }

  List<PrayerTime> _updatePrayerStatus(List<PrayerTime> prayers) {
    // final now = DateTime.now();
    final currentTime = TimeOfDay.now();

    int nextIndex = -1;

    for (int i = 0; i < prayers.length; i++) {
      final parts = prayers[i].time.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final prayerTime = TimeOfDay(hour: hour, minute: minute);

        final currentMinutes = currentTime.hour * 60 + currentTime.minute;
        final prayerMinutes = prayerTime.hour * 60 + prayerTime.minute;

        if (prayerMinutes > currentMinutes && nextIndex == -1) {
          nextIndex = i;
          break;
        }
      }
    }

    return List.generate(prayers.length, (i) {
      final parts = prayers[i].time.split(':');
      bool isPassed = false;

      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final prayerTime = TimeOfDay(hour: hour, minute: minute);

        final currentMinutes = currentTime.hour * 60 + currentTime.minute;
        final prayerMinutes = prayerTime.hour * 60 + prayerTime.minute;

        isPassed = prayerMinutes < currentMinutes;
      }

      return PrayerTime(
        name: prayers[i].name,
        time: prayers[i].time,
        isPassed: isPassed,
        isNext: i == nextIndex,
      );
    });
  }

  /// Find zone code by location in Malaysia
  String _findZoneByLocationMY(Map<String, dynamic> locationData) {
    try {
      final lokasi = locationData['lokasi'] as String?;
      final lat = locationData['lat'] as double?;
      final lon = locationData['lon'] as double?;

      if (lokasi == null || lat == null || lon == null) {
        throw Exception('Missing location data');
      }

      // Step 1: Try exact name match
      final exactMatch = _findZoneByName(locationData);
      if (exactMatch != null) {
        // print(
        //   '✅ Found exact match: $exactMatch (${malaysiaZones[exactMatch]!['name']})',
        // );
        return exactMatch;
      }

      // Step 2: Try partial name match
      final partialMatch = _findZoneByPartialName(lokasi);
      if (partialMatch != null) {
        //print('✅ Found partial match: $partialMatch');
        return partialMatch;
      }

      // Step 3: Fallback to nearest zone by distance
      final nearestZone = _findNearestZone(lat, lon);
      final nearestZoneId = nearestZone['zoneId'] as String;
      // print(
      //   '✅ Using nearest zone: $nearestZoneId (${nearestZone['distance']} km away)',
      // );
      return nearestZoneId;
    } catch (e) {
      // print('Error _findZoneByLocationMY: $e');
      return 'ERROR';
    }
  }

  /// Find zone by exact location name match
  ///
  String? _findZoneByName(Map<String, dynamic> locationData) {
    final String locationName = locationData['lokasi']?.toString() ?? '';
    String daerah = locationData['administrativeArea']?.toString() ?? '';
    final cleanLocation = locationName.trim().toLowerCase();

    //1. check daerah melaka dan perlis sahaja
    if (daerah == 'Melaka') {
      return 'MLK01'; //Melaka Sahaja
    } else if (daerah == 'Perlis') {
      return 'PLS01'; //Perlis Sahaja
    } else if (daerah == 'Johor Darul Ta\'zim') {
      daerah = 'Johor';
    }

    //2. check daerah sama dengan state x?

    for (final entry in malaysiaZones.entries) {
      final Map<String, dynamic> zone = entry.value;
      final String state = zone['state']?.toString() ?? '';
      final String zoneName = zone['name']?.toString() ?? '';

      // ✅ Check if state matches
      if (state.toLowerCase() == daerah.toLowerCase()) {
        final locations = zoneName
            .toLowerCase()
            .split(',')
            .map((e) => e.trim())
            .toList();

        // ✅ Check if any location matches
        for (final loc in locations) {
          // print('$loc --------- $locations');
          if (loc == cleanLocation) {
            return entry.key;
          }
        }
      }
    }

    // print('⚠️ No zone found for $cleanLocation in $daerah');
    return null;
  }

  /// Find zone by partial/contains name match
  String? _findZoneByPartialName(String locationName) {
    final cleanLocation = locationName.trim().toLowerCase();

    for (final entry in malaysiaZones.entries) {
      final zoneName = entry.value['name'] as String;
      final locations = zoneName.toLowerCase().split(',').map((e) => e.trim());

      for (final loc in locations) {
        if (loc.contains(cleanLocation) || cleanLocation.contains(loc)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  // ========== SMART COORDINATE HELPERS ==========

  /// Get latitude with smart fallback
  /// Try: latitude → latitude_east → latitude_west → latitude_west_1 → latitude_west_2
  double? getLatitude(Map<String, dynamic>? zone) {
    if (zone == null) return null;

    return zone['latitude'] as double? ??
        zone['latitude_east'] as double? ??
        zone['latitude_west'] as double? ??
        zone['latitude_west_1'] as double? ??
        zone['latitude_west_2'] as double?;
  }

  /// Get longitude with smart fallback
  /// Try: longitude → longitude_east → longitude_west → longitude_west_1 → longitude_west_2
  double? getLongitude(Map<String, dynamic>? zone) {
    if (zone == null) return null;

    return zone['longitude'] as double? ??
        zone['longitude_east'] as double? ??
        zone['longitude_west'] as double? ??
        zone['longitude_west_1'] as double? ??
        zone['longitude_west_2'] as double?;
  }

  /// Get coordinates together
  Map<String, double>? getCoordinates(Map<String, dynamic>? zone) {
    if (zone == null) return null;

    final lat = getLatitude(zone);
    final lon = getLongitude(zone);

    if (lat != null && lon != null) {
      return {'latitude': lat, 'longitude': lon};
    }

    return null;
  }

  /// Get primary reference name
  String? getPrimaryReference(Map<String, dynamic>? zone) {
    if (zone == null) return null;

    return zone['reference'] as String? ??
        zone['reference_east'] as String? ??
        zone['reference_west'] as String? ??
        zone['reference_west_1'] as String?;
  }

  /// Get all coordinate pairs
  List<Map<String, dynamic>> getAllCoordinatePairs(Map<String, dynamic>? zone) {
    if (zone == null) return [];

    final pairs = <Map<String, dynamic>>[];

    if (zone['latitude'] != null && zone['longitude'] != null) {
      pairs.add({
        'type': 'primary',
        'reference': zone['reference'] ?? 'Primary',
        'latitude': zone['latitude'] as double,
        'longitude': zone['longitude'] as double,
      });
    }

    if (zone['latitude_east'] != null && zone['longitude_east'] != null) {
      pairs.add({
        'type': 'east',
        'reference': zone['reference_east'] ?? 'Timur',
        'latitude': zone['latitude_east'] as double,
        'longitude': zone['longitude_east'] as double,
      });
    }

    if (zone['latitude_west'] != null && zone['longitude_west'] != null) {
      pairs.add({
        'type': 'west',
        'reference': zone['reference_west'] ?? 'Barat',
        'latitude': zone['latitude_west'] as double,
        'longitude': zone['longitude_west'] as double,
      });
    }

    if (zone['latitude_west_1'] != null && zone['longitude_west_1'] != null) {
      pairs.add({
        'type': 'west_1',
        'reference': zone['reference_west_1'] ?? 'Barat 1',
        'latitude': zone['latitude_west_1'] as double,
        'longitude': zone['longitude_west_1'] as double,
      });
    }

    if (zone['latitude_west_2'] != null && zone['longitude_west_2'] != null) {
      pairs.add({
        'type': 'west_2',
        'reference': zone['reference_west_2'] ?? 'Barat 2',
        'latitude': zone['latitude_west_2'] as double,
        'longitude': zone['longitude_west_2'] as double,
      });
    }

    return pairs;
  }

  /// Get average coordinates of all pairs
  Map<String, double>? getAverageCoordinates(Map<String, dynamic>? zone) {
    if (zone == null) return null;

    final pairs = getAllCoordinatePairs(zone);
    if (pairs.isEmpty) return null;

    double totalLat = 0;
    double totalLon = 0;

    for (final pair in pairs) {
      totalLat += pair['latitude'] as double;
      totalLon += pair['longitude'] as double;
    }

    return {
      'latitude': totalLat / pairs.length,
      'longitude': totalLon / pairs.length,
    };
  }

  /// Get zone by ID with coordinates
  Map<String, dynamic>? getZoneWithCoordinates(String zoneId) {
    final zone = malaysiaZones[zoneId];
    if (zone == null) return null;

    final coords = getCoordinates(zone);
    if (coords == null) return null;

    return {
      ...zone,
      'latitude': coords['latitude'],
      'longitude': coords['longitude'],
    };
  }

  /// Get all zones by state
  List<Map<String, dynamic>> getZonesByState(String state) {
    return malaysiaZones.values
        .where((zone) => zone['state'] == state)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// Get zones by state with coordinates
  List<Map<String, dynamic>> getZonesByStateWithCoordinates(String state) {
    return getZonesByState(
      state,
    ).where((zone) => getCoordinates(zone) != null).toList();
  }

  /// Calculate distance using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    final double dLat = _toRadian(lat2 - lat1);
    final double dLon = _toRadian(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadian(lat1)) *
            cos(_toRadian(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _toRadian(double degree) {
    return degree * pi / 180;
  }

  /// Find nearest zone by coordinates - Returns Map with zoneId and distance
  /// ✅ This method is now used and returns both zoneId and distance info
  Map<String, dynamic> _findNearestZone(double latitude, double longitude) {
    String nearestZoneId = 'PLS01'; // Default fallback
    double minDistance = double.infinity;

    for (final entry in malaysiaZones.entries) {
      final coords = getCoordinates(entry.value);
      if (coords == null) continue;

      final distance = calculateDistance(
        latitude,
        longitude,
        coords['latitude']!,
        coords['longitude']!,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestZoneId = entry.key;
      }
    }

    final zone = malaysiaZones[nearestZoneId]!;
    final coords = getCoordinates(zone)!;

    return {
      'zoneId': nearestZoneId,
      'name': zone['name'],
      'state': zone['state'],
      'reference': getPrimaryReference(zone),
      'latitude': coords['latitude'],
      'longitude': coords['longitude'],
      'distance': minDistance, // Distance in km
    };
  }

  /// Find zones within radius (in km)
  /// Returns sorted list by distance (nearest first)
  List<Map<String, dynamic>> findZonesWithinRadius(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final entry in malaysiaZones.entries) {
      final coords = getCoordinates(entry.value);
      if (coords == null) continue;

      final distance = calculateDistance(
        latitude,
        longitude,
        coords['latitude']!,
        coords['longitude']!,
      );

      if (distance <= radiusKm) {
        result.add({'zoneId': entry.key, ...entry.value, 'distance': distance});
      }
    }

    // Sort by distance (nearest first)
    result.sort(
      (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );

    return result;
  }

  String _normalizeHijriDate(String hijri) {
    // Example input: 1447-05-02
    if (hijri.isEmpty) return '--';
    final parts = hijri.split('-');
    if (parts.length != 3) return hijri;

    // Rearrange from yyyy-mm-dd → dd-mm-yyyy
    final year = parts[0];
    final month = parts[1];
    final day = parts[2];
    return '$day-$month-$year';
  }

  /// Normalize time to `HH:mm:ss`
  // String _normalizeTime(String? time) {
  //   if (time == null || time.isEmpty) return '--:--';
  //   final parts = time.split(':');
  //   if (parts.length >= 2) {
  //     return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  //   }
  //   return time;
  // }

  String _normalizeTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';

    final trimmed = time.trim();

    // Check for "no data" indicators from JAKIM API
    if (trimmed == "00:00" || trimmed == "-" || trimmed == "--:--") {
      return '--:--';
    }

    final parts = trimmed.split(':');
    if (parts.length >= 2) {
      final hour = parts[0].padLeft(2, '0');
      final minute = parts[1].padLeft(2, '0');

      // Extra validation: ensure valid time range
      final hourInt = int.tryParse(hour);
      final minuteInt = int.tryParse(minute);

      if ((hourInt == null || hourInt < 0 || hourInt > 23) ||
          (minuteInt == null || minuteInt < 0 || minuteInt > 59)) {
        return '--:--';
      }

      return '$hour:$minute';
    }
    return time;
  }

  /// Normalize time to `HH:mm:ss`
  String _normalizeDate(String date) {
    if (date.isEmpty) return '00-00-0000';

    // Expected format: 24-Oct-2025
    final parts = date.split('-');
    if (parts.length != 3) return date;

    final day = parts[0];
    final monthStr = parts[1].toLowerCase();
    final year = parts[2];

    // Convert month name (short) to number
    const months = {
      'jan': '01',
      'feb': '02',
      'mar': '03',
      'apr': '04',
      'may': '05',
      'jun': '06',
      'jul': '07',
      'aug': '08',
      'sep': '09',
      'oct': '10',
      'nov': '11',
      'dec': '12',
    };

    final monthNum = months[monthStr] ?? '00';
    return '$day-$monthNum-$year';
  }

  /// Fallback prayer times (Kuala Lumpur approximate times)
  /// Used when both API and cache fail
  PrayerTimeData _getDefaultPrayerTimes(Map<String, dynamic> locationData) {
    final todayDate = _getTodayDate();

    // Approximate prayer times for Kuala Lumpur (suitable for Malaysia region)
    final prayers = [
      PrayerTime(name: 'Imsak', time: '05:45', isPassed: false, isNext: false),
      PrayerTime(name: 'Subuh', time: '05:55', isPassed: false, isNext: false),
      PrayerTime(name: 'Syuruk', time: '07:10', isPassed: false, isNext: false),
      PrayerTime(name: 'Zohor', time: '13:15', isPassed: false, isNext: false),
      PrayerTime(name: 'Asar', time: '16:30', isPassed: false, isNext: false),
      PrayerTime(name: 'Maghrib', time: '19:15', isPassed: false, isNext: false),
      PrayerTime(name: 'Isyak', time: '20:30', isPassed: false, isNext: false),
    ];

    return PrayerTimeData(
      hijri: '--',
      date: todayDate,
      prayers: _updatePrayerStatus(prayers),
      zone: 'DEFAULT',
      location: locationData['lokasi'] ?? 'Kuala Lumpur',
      userLocationData: locationData,
      sumber: 'Default (Offline Mode)',
      sumberWebsite: '',
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/plugin.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() {
    return _instance;
  }
  LocationService._internal();

  Future<Position> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10), // ✅ Add time limit
        ),
      ).timeout(
        const Duration(seconds: 10), // ✅ Add timeout
        onTimeout: () {
          debugPrint('⏱️ Location fetch timeout');
          throw TimeoutException('Location request timed out');
        },
      );
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDetailedLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String lokasi = '';
        // Try to get the most specific location name
        if (place.locality != null && place.locality!.isNotEmpty) {
          lokasi = place.locality!;
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          lokasi = place.subAdministrativeArea!;
        } else if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          lokasi = place.administrativeArea!;
        } else if (place.country != null && place.country!.isNotEmpty) {
          lokasi = place.country!;
        }

        Map<String, dynamic> detailLocation = {
          'name': place.name ?? '',
          'street': place.street ?? '',
          'isoCountryCode': place.isoCountryCode ?? '',
          'country': place.country ?? '',
          'postalCode': place.postalCode ?? '',
          'administrativeArea': place.administrativeArea ?? '',
          'subAdministrativeArea': place.subAdministrativeArea ?? '',
          'locality': place.locality ?? '',
          'subLocality': place.subLocality ?? '',
          'thoroughfare': place.thoroughfare ?? '',
          'subThoroughfare': place.subThoroughfare ?? '',
          'lat': latitude,
          'lon': longitude,
          'lokasi': lokasi, //DEFAULT
        };
        return detailLocation;
      }
      return {};
    } catch (e) {
      print('Error getDetailedLocation: $e');
      return {};
    }
  }

  // Calculate distance between two points (in meters)
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // ============================================
  // 3️⃣ FAST LOCATION - Use cached location first
  // ============================================
  Future<Map<String, dynamic>> loadLocationFast() async {
    // ✅ Check cache FIRST (instant load)
    final Map<String, dynamic>? cached = await _getCachedLocation();

    // ✅ Check if cache is fresh (not stale)
    if (cached != null && !await _isLocationStale()) {
      //  debugPrint('⚡ Using cached location (instant)');
      return cached;
    }

    // debugPrint('🔄 Cache is stale or missing, fetching new location...');

    try {
      //  debugPrint('📍 Requesting location permission...');
      final status = await Geolocator.checkPermission();

      if (status == LocationPermission.denied) {
        //  debugPrint('⚠️ Permission denied, requesting...');
        final result = await Geolocator.requestPermission();
        if (result != LocationPermission.whileInUse &&
            result != LocationPermission.always) {
          throw Exception('Location permission denied by user');
        }
      } else if (status == LocationPermission.deniedForever) {
        throw Exception('Location permission denied forever');
      }

      //  debugPrint('✅ Permission granted, getting location...');

      // ✅ SHORTER timeout - only wait 3 seconds
      final position = await getCurrentLocation();

      //debugPrint('✅ Got position: ${position.latitude}, ${position.longitude}');

      // ✅ Get location details
      final locationData = await getDetailedLocation(
        position.latitude,
        position.longitude,
      );

      // ✅ Cache for next time
      await _cacheLocationData(locationData);
      // debugPrint('✅ Location loaded and cached');
      return locationData;
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Timeout: $e');
      // Use cached if available
      final cached = await _getCachedLocation();
      if (cached != null) {
        //     debugPrint('⚠️ Using cached after timeout');
        return cached;
      }
      throw Exception('Location timeout and no cache available');
    } catch (e) {
      //   debugPrint('❌ Error: $e');

      // ✅ If location fails, use last cached
      final cached = await _getCachedLocation();
      if (cached != null) {
        //    debugPrint('⚠️ Location failed, using cached');
        return cached;
      }

      throw Exception('Location service failed: $e');
    }
  }

  // 1️⃣ CACHE LOCATION DATA
  Future<void> _cacheLocationData(Map<String, dynamic> locationData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Save location data
      await prefs.setString(prefCachedLocation, jsonEncode(locationData));

      // ✅ Save current time as cache time
      await prefs.setString(
        prefCachedLocationTime,
        DateTime.now().toIso8601String(),
      );

      //  debugPrint('💾 Location cached with timestamp');
    } catch (e) {
      debugPrint('❌ Error caching location: $e');
    }
  }

  // ✅ Better (safer):
  Future<Map<String, dynamic>?> _getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(prefCachedLocation);
      if (cached != null) {
        //    debugPrint('📥 Using cached location');
        return jsonDecode(cached) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting cached location: $e');
      return null;
    }
  }

  // ============================================================================
  // ✅ ADD THIS METHOD TO LocationService
  // ============================================================================

  /// Clear location cache from SharedPreferences
  Future<void> clearLocationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefCachedLocation);
      await prefs.remove(prefCachedLocationTime);
      //debugPrint('🗑️ Location cache cleared from SharedPreferences');
    } catch (e) {
      debugPrint('❌ Error clearing location cache: $e');
      rethrow;
    }
  }

  // ============================================
  // 4️⃣ CHECK IF CACHE IS STALE (1 hour)
  // ============================================

  Future<bool> _isLocationStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Get last cache time
      final lastCacheTime = prefs.getString(prefCachedLocationTime);
      if (lastCacheTime == null) {
        debugPrint('⚠️ No cache time found - cache is stale');
        return true; // No cache = stale
      }
      // ✅ Parse the stored time
      final cachedDateTime = DateTime.parse(lastCacheTime);
      final now = DateTime.now();
      // ✅ Calculate difference
      final difference = now.difference(cachedDateTime);
      // ✅ Check if older than 1 hour (3600 seconds)
      final isStale = difference.inSeconds > 3600;
      debugPrint('🕐 Cache age: ${difference.inMinutes} minutes');
      debugPrint(isStale ? '⚠️ Cache STALE' : '✅ Cache FRESH');
      return isStale;
    } catch (e) {
      debugPrint('❌ Error checking cache staleness: $e');
      return true; // Assume stale on error
    }
  }
}

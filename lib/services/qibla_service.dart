// // ============================================
// // FILE: services/qibla_service.dart
// // ✅ IMPROVED: Accurate Qiblah Direction Calculator
// // Better bearing formula + Malay direction names
// // ============================================
// // ignore_for_file: avoid_print

// import 'dart:math';

// import 'package:geolocator/geolocator.dart';

// class QiblaService {
//   // ✅ Mecca coordinates (Kaaba) - Verified accurate
//   static const double meccaLatitude = 21.4225;
//   static const double meccaLongitude = 39.8262;

//   /// ✅ Calculate the bearing (direction) from user location to Mecca
//   /// Returns bearing in degrees (0-360)
//   /// Using improved initial bearing formula with proper angle handling
//   static Future<double> getQiblaDirection() async {
//     try {
//       // Get user's current location
//       final position = await _getCurrentPosition();

//       // Calculate bearing to Mecca using improved formula
//       final bearing = _calculateBearing(
//         position.latitude,
//         position.longitude,
//         meccaLatitude,
//         meccaLongitude,
//       );

//       print('✅ Qibla bearing calculated: $bearing°');
//       return bearing;
//     } catch (e) {
//       print('❌ Error calculating Qibla direction: $e');
//       rethrow;
//     }
//   }

//   /// ✅ Get user's current position with proper error handling
//   static Future<Position> _getCurrentPosition() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       throw Exception('📍 Location services are disabled');
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         throw Exception('📍 Location permissions are denied');
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       throw Exception('📍 Location permissions are permanently denied');
//     }

//     return await Geolocator.getCurrentPosition(
//       locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
//     );
//   }

//   /// ✅ Calculate initial bearing from point A to point B
//   /// Using improved spherical law of cosines formula
//   ///
//   /// Formula: θ = atan2(sin(Δλ) * cos(φ2), cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ))
//   ///
//   /// Parameters:
//   /// lat1, lon1 = User location (degrees)
//   /// lat2, lon2 = Mecca location (degrees)
//   ///
//   /// Returns: Bearing in degrees (0-360)
//   /// 0° = North, 90° = East, 180° = South, 270° = West
//   static double _calculateBearing(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     // ✅ Validate input coordinates
//     if (lat1.isNaN || lon1.isNaN || lat2.isNaN || lon2.isNaN) {
//       print('❌ Invalid coordinates');
//       return 0;
//     }

//     try {
//       // ✅ Convert degrees to radians
//       final lat1Rad = _degreesToRadians(lat1);
//       final lat2Rad = _degreesToRadians(lat2);
//       final dLonRad = _degreesToRadians(lon2 - lon1);

//       // ✅ Improved bearing calculation
//       // Using proper atan2 parameter order for accurate bearing
//       final sinDLon = sin(dLonRad);
//       final cosDLon = cos(dLonRad);

//       final sinLat2 = sin(lat2Rad);
//       final cosLat2 = cos(lat2Rad);

//       final sinLat1 = sin(lat1Rad);
//       final cosLat1 = cos(lat1Rad);

//       // ✅ Calculate x and y components
//       final y = sinDLon * cosLat2;
//       final x = (cosLat1 * sinLat2) - (sinLat1 * cosLat2 * cosDLon);

//       // ✅ Get initial bearing using atan2
//       var bearing = atan2(y, x);

//       // ✅ Convert radians to degrees
//       bearing = _radiansToDegrees(bearing);

//       // ✅ Normalize to 0-360 range (proper normalization)
//       while (bearing < 0) {
//         bearing += 360;
//       }
//       while (bearing >= 360) {
//         bearing -= 360;
//       }

//       // ✅ Final validation
//       bearing = bearing % 360;
//       if (bearing < 0) bearing += 360;

//       print(
//         '📍 Bearing calculation: lat1=$lat1, lon1=$lon1, lat2=$lat2, lon2=$lon2 → $bearing°',
//       );
//       return bearing;
//     } catch (e) {
//       print('❌ Error in bearing calculation: $e');
//       return 0;
//     }
//   }

//   /// ✅ Calculate distance between two coordinates using Haversine formula
//   /// Returns distance in kilometers
//   /// Accurate for Earth distances
//   static double calculateDistance(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     try {
//       const earthRadiusKm = 6371.0; // Earth's radius in kilometers

//       final dLatRad = _degreesToRadians(lat2 - lat1);
//       final dLonRad = _degreesToRadians(lon2 - lon1);

//       final lat1Rad = _degreesToRadians(lat1);
//       final lat2Rad = _degreesToRadians(lat2);

//       // ✅ Haversine formula
//       final a =
//           sin(dLatRad / 2) * sin(dLatRad / 2) +
//           cos(lat1Rad) * cos(lat2Rad) * sin(dLonRad / 2) * sin(dLonRad / 2);

//       final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//       final distance = earthRadiusKm * c;

//       print('📏 Distance calculated: $distance km');
//       return distance;
//     } catch (e) {
//       print('❌ Error in distance calculation: $e');
//       return 0;
//     }
//   }

//   /// ✅ Convert degrees to radians
//   static double _degreesToRadians(double degrees) {
//     return degrees * (pi / 180.0);
//   }

//   /// ✅ Convert radians to degrees
//   static double _radiansToDegrees(double radians) {
//     return radians * (180.0 / pi);
//   }

//   /// ✅ Get compass direction name from bearing
//   /// Supports: English (N, NE, E, ...), Malay, and Arabic
//   ///
//   /// Angle ranges:
//   /// N:  337.5° - 22.5°
//   /// NE: 22.5° - 67.5°
//   /// E:  67.5° - 112.5°
//   /// SE: 112.5° - 157.5°
//   /// S:  157.5° - 202.5°
//   /// SW: 202.5° - 247.5°
//   /// W:  247.5° - 292.5°
//   /// NW: 292.5° - 337.5°
//   static String getDirectionName(
//     double bearing, {
//     bool isArabic = false,
//     bool isMalay = false,
//   }) {
//     try {
//       // ✅ Validate and normalize bearing
//       final normalizedBearing = bearing % 360;
//       final validBearing = normalizedBearing < 0
//           ? normalizedBearing + 360
//           : normalizedBearing;

//       print('📊 Direction: bearing=$bearing → normalized=$validBearing');

//       // ✅ English compass directions (default)
//       if (isArabic) {
//         return _getArabicDirection(validBearing);
//       } else if (isMalay) {
//         return _getMalayDirection(validBearing);
//       } else {
//         return _getEnglishDirection(validBearing);
//       }
//     } catch (e) {
//       print('❌ Error getting direction name: $e');
//       return 'N'; // Default to North
//     }
//   }

//   /// ✅ English compass directions
//   static String _getEnglishDirection(double bearing) {
//     if (bearing < 22.5 || bearing >= 337.5) return 'N';
//     if (bearing < 67.5) return 'NE';
//     if (bearing < 112.5) return 'E';
//     if (bearing < 157.5) return 'SE';
//     if (bearing < 202.5) return 'S';
//     if (bearing < 247.5) return 'SW';
//     if (bearing < 292.5) return 'W';
//     return 'NW';
//   }

//   /// ✅ Malay compass directions (NEW)
//   static String _getMalayDirection(double bearing) {
//     if (bearing < 22.5 || bearing >= 337.5) return 'U'; // Utara (North)
//     if (bearing < 67.5) return 'TL'; // Timur Laut (Northeast)
//     if (bearing < 112.5) return 'T'; // Timur (East)
//     if (bearing < 157.5) return 'TG'; // Tenggara (Southeast)
//     if (bearing < 202.5) return 'S'; // Selatan (South)
//     if (bearing < 247.5) return 'BL'; // Barat Laut (Southwest)
//     if (bearing < 292.5) return 'B'; // Barat (West)
//     return 'BL'; // Barat Laut (Northwest)
//   }

//   /// ✅ Arabic compass directions
//   static String _getArabicDirection(double bearing) {
//     if (bearing < 22.5 || bearing >= 337.5) return 'شمال'; // Shamal (North)
//     if (bearing < 67.5) return 'شمال شرق'; // Shamal Sharq (Northeast)
//     if (bearing < 112.5) return 'شرق'; // Sharq (East)
//     if (bearing < 157.5) return 'جنوب شرق'; // Janub Sharq (Southeast)
//     if (bearing < 202.5) return 'جنوب'; // Janub (South)
//     if (bearing < 247.5) return 'جنوب غرب'; // Janub Gharb (Southwest)
//     if (bearing < 292.5) return 'غرب'; // Gharb (West)
//     return 'شمال غرب'; // Shamal Gharb (Northwest)
//   }

//   /// ✅ Calculate angle offset between compass heading and Qibla direction
//   /// This is used for the needle rotation in the UI
//   ///
//   /// Positive angle = Qibla is clockwise from North (right)
//   /// Negative angle = Qibla is counter-clockwise from North (left)
//   /// Range: -180 to +180 degrees
//   static double calculateQiblaOffset(double heading, double qiblaDirection) {
//     try {
//       // ✅ Ensure both values are in 0-360 range
//       final normalizedHeading = heading % 360;
//       final normalizedQibla = qiblaDirection % 360;

//       // ✅ Calculate offset
//       var offset = normalizedQibla - normalizedHeading;

//       // ✅ Normalize to -180 to +180 range for shortest rotation path
//       while (offset > 180) {
//         offset -= 360;
//       }
//       while (offset < -180) {
//         offset += 360;
//       }

//       print(
//         '🧭 Qibla offset: heading=$heading, qibla=$qiblaDirection → offset=$offset',
//       );
//       return offset;
//     } catch (e) {
//       print('❌ Error calculating Qibla offset: $e');
//       return 0;
//     }
//   }

//   /// ✅ Get precise direction name with full text (Malay)
//   static String getFullMalayDirectionName(double bearing) {
//     if (bearing < 22.5 || bearing >= 337.5) return 'Utara';
//     if (bearing < 67.5) return 'Timur Laut';
//     if (bearing < 112.5) return 'Timur';
//     if (bearing < 157.5) return 'Tenggara';
//     if (bearing < 202.5) return 'Selatan';
//     if (bearing < 247.5) return 'Barat Daya';
//     if (bearing < 292.5) return 'Barat';
//     return 'Barat Laut';
//   }

//   /// ✅ Get precise direction name with full text (English)
//   static String getFullEnglishDirectionName(double bearing) {
//     if (bearing < 22.5 || bearing >= 337.5) return 'North';
//     if (bearing < 67.5) return 'Northeast';
//     if (bearing < 112.5) return 'East';
//     if (bearing < 157.5) return 'Southeast';
//     if (bearing < 202.5) return 'South';
//     if (bearing < 247.5) return 'Southwest';
//     if (bearing < 292.5) return 'West';
//     return 'Northwest';
//   }

//   /// ✅ Get precise direction name with full text (Arabic)
//   static String getFullArabicDirectionName(double bearing) {
//     if (bearing < 22.5 || bearing >= 337.5) return 'الشمال';
//     if (bearing < 67.5) return 'الشمال الشرقي';
//     if (bearing < 112.5) return 'الشرق';
//     if (bearing < 157.5) return 'الجنوب الشرقي';
//     if (bearing < 202.5) return 'الجنوب';
//     if (bearing < 247.5) return 'الجنوب الغربي';
//     if (bearing < 292.5) return 'الغرب';
//     return 'الشمال الغربي';
//   }

//   /// ✅ Verify Qibla bearing is valid
//   /// Qibla from Malaysia should typically be between 260° - 320° (W to NW)
//   static bool isValidQiblaBearing(double bearing, String locationHint) {
//     final normalizedBearing = bearing % 360;

//     // For Malaysia, Qibla should be roughly West to Northwest
//     if (locationHint.toLowerCase().contains('malaysia')) {
//       return normalizedBearing > 200 && normalizedBearing < 350;
//     }

//     // General validation: should be between 0-360
//     return normalizedBearing >= 0 && normalizedBearing < 360;
//   }
// }

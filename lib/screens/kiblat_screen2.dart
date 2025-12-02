// import 'dart:math';
// import 'package:aqim/utils/aqim_icons.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_compass/flutter_compass.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/location_service.dart';

// enum CompassImageDesign {
//   classic,
//   teal,
//   red,
//   black,
//   greenLight,
//   greenDark,
// }

// extension CompassImageDesignExtension on CompassImageDesign {
//   String get name {
//     switch (this) {
//       case CompassImageDesign.classic:
//         return 'Classic';
//       case CompassImageDesign.teal:
//         return 'Teal';
//       case CompassImageDesign.red:
//         return 'Red';
//       case CompassImageDesign.black:
//         return 'Black';
//       case CompassImageDesign.greenLight:
//         return 'Green Light';
//       case CompassImageDesign.greenDark:
//         return 'Green Dark';
//     }
//   }

//   IconData get icon {
//     switch (this) {
//       case CompassImageDesign.classic:
//         return Icons.brightness_7;
//       case CompassImageDesign.teal:
//         return Icons.water_drop;
//       case CompassImageDesign.red:
//         return Icons.circle;
//       case CompassImageDesign.black:
//         return Icons.dark_mode;
//       case CompassImageDesign.greenLight:
//         return Icons.nature;
//       case CompassImageDesign.greenDark:
//         return Icons.mosque;
//     }
//   }

//   Color get backgroundColor {
//     switch (this) {
//       case CompassImageDesign.classic:
//         return const Color(0xFFF5F5F5);
//       case CompassImageDesign.teal:
//         return const Color(0xFF00BCD4);
//       case CompassImageDesign.red:
//         return const Color(0xFFD32F2F);
//       case CompassImageDesign.black:
//         return const Color(0xFF1A1A1A);
//       case CompassImageDesign.greenLight:
//         return const Color(0xFF4CAF50);
//       case CompassImageDesign.greenDark:
//         return const Color(0xFF2E7D32);
//     }
//   }

//   Color get needleColor {
//     switch (this) {
//       case CompassImageDesign.classic:
//         return const Color(0xFFD32F2F);
//       case CompassImageDesign.teal:
//         return Colors.white;
//       case CompassImageDesign.red:
//         return const Color(0xFFD32F2F);
//       case CompassImageDesign.black:
//         return const Color(0xFFFFD700);
//       case CompassImageDesign.greenLight:
//         return Colors.white;
//       case CompassImageDesign.greenDark:
//         return const Color(0xFF2E7D32);
//     }
//   }

//   bool get useLightCompass {
//     switch (this) {
//       case CompassImageDesign.classic:
//       case CompassImageDesign.greenDark:
//         return true;
//       default:
//         return false;
//     }
//   }
// }

// class KiblatScreen2 extends StatefulWidget {
//   const KiblatScreen2({super.key});

//   @override
//   State<KiblatScreen2> createState() => _KiblatScreen2State();
// }

// class _KiblatScreen2State extends State<KiblatScreen2> {
//   static const double kaabaLatitude = 21.422487;
//   static const double kaabaLongitude = 39.826206;

//   double? qiblaBearing;
//   double? deviceHeading = 0;
//   bool isLoading = true;
//   CompassImageDesign selectedDesign = CompassImageDesign.classic;

//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     // Load saved compass design
//     await _loadCompassDesign();

//     // Get Qibla bearing
//     final bearing = await calculateQiblaDirection();

//     // Listen to compass
//     FlutterCompass.events?.listen((event) {
//       if (mounted) {
//         setState(() {
//           deviceHeading = event.heading;
//         });
//       }
//     });

//     setState(() {
//       qiblaBearing = bearing;
//       isLoading = false;
//     });
//   }

//   Future<void> _loadCompassDesign() async {
//     final prefs = await SharedPreferences.getInstance();
//     final designIndex = prefs.getInt('compass_image_design') ?? 0;
//     setState(() {
//       selectedDesign = CompassImageDesign.values[designIndex];
//     });
//   }

//   Future<void> _saveCompassDesign(CompassImageDesign design) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('compass_image_design', design.index);
//     setState(() {
//       selectedDesign = design;
//     });
//   }

//   Future<double> calculateQiblaDirection() async {
//     final locationData = await LocationService().getCurrentLocation();
//     double lat1 = locationData.latitude * pi / 180;
//     double lon1 = locationData.longitude * pi / 180;
//     double lat2 = kaabaLatitude * pi / 180;
//     double lon2 = kaabaLongitude * pi / 180;

//     double dLon = lon2 - lon1;
//     double y = sin(dLon) * cos(lat2);
//     double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
//     double bearing = atan2(y, x);
//     bearing = bearing * 180 / pi;
//     bearing = (bearing + 360) % 360;

//     debugPrint('🧭 Qibla Bearing: ${bearing.toStringAsFixed(2)}°');
//     return bearing;
//   }

//   void _showDesignPicker() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: EdgeInsets.symmetric(vertical: 20.h),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Pilih Reka Bentuk Kompas',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             SizedBox(height: 16.h),
//             ...CompassImageDesign.values.map((design) {
//               return ListTile(
//                 leading: Icon(design.icon),
//                 title: Text(design.name),
//                 trailing: selectedDesign == design
//                     ? Icon(Icons.check, color: Theme.of(context).primaryColor)
//                     : null,
//                 onTap: () {
//                   _saveCompassDesign(design);
//                   Navigator.pop(context);
//                 },
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading || qiblaBearing == null || deviceHeading == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Arah Kiblat (Image)')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     // Calculate rotation angles
//     double compassRotation = -deviceHeading! * pi / 180;
//     double needleRotation = (qiblaBearing! - deviceHeading!) * pi / 180;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Arah Kiblat (Image)'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.palette),
//             onPressed: _showDesignPicker,
//             tooltip: 'Tukar Reka Bentuk',
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               selectedDesign.backgroundColor,
//               selectedDesign.backgroundColor.withValues(alpha: 0.7),
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(height: 20.h),
//                 // Kaaba Icon
//                 Icon(
//                   Aqim.kaaba_01,
//                   size: 50.sp,
//                   color: selectedDesign == CompassImageDesign.black
//                       ? Colors.amber
//                       : Colors.white,
//                 ),
//                 SizedBox(height: 16.h),
//                 // Title
//                 Text(
//                   'Arah Kiblat',
//                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                         color: selectedDesign == CompassImageDesign.classic
//                             ? Colors.black87
//                             : Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//                 SizedBox(height: 12.h),
//                 // Bearing Degree
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
//                   decoration: BoxDecoration(
//                     color: selectedDesign == CompassImageDesign.classic
//                         ? Colors.white
//                         : Colors.white.withValues(alpha: 0.2),
//                     borderRadius: BorderRadius.circular(20.r),
//                     border: Border.all(
//                       color: selectedDesign.needleColor,
//                       width: 2,
//                     ),
//                   ),
//                   child: Text(
//                     '${qiblaBearing!.toStringAsFixed(1)}°',
//                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                           color: selectedDesign == CompassImageDesign.classic
//                               ? selectedDesign.needleColor
//                               : Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                   ),
//                 ),
//                 SizedBox(height: 40.h),

//                 // Compass with Needle Stack
//                 SizedBox(
//                   width: 320.w,
//                   height: 320.w,
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       // Rotating Compass Image
//                       Transform.rotate(
//                         angle: compassRotation,
//                         child: Container(
//                           width: 300.w,
//                           height: 300.w,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withValues(alpha: 0.3),
//                                 blurRadius: 20,
//                                 spreadRadius: 5,
//                               ),
//                             ],
//                           ),
//                           child: ClipOval(
//                             child: ColorFiltered(
//                               colorFilter: selectedDesign.useLightCompass
//                                   ? const ColorFilter.mode(
//                                       Colors.transparent,
//                                       BlendMode.multiply,
//                                     )
//                                   : ColorFilter.mode(
//                                       selectedDesign.backgroundColor.withValues(alpha: 0.3),
//                                       BlendMode.color,
//                                     ),
//                               child: Image.asset(
//                                 'assets/images/compass.png',
//                                 width: 300.w,
//                                 height: 300.w,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),

//                       // Rotating Needle Image (points to Qibla)
//                       Transform.rotate(
//                         angle: needleRotation,
//                         child: ColorFiltered(
//                           colorFilter: ColorFilter.mode(
//                             selectedDesign.needleColor,
//                             BlendMode.modulate,
//                           ),
//                           child: Image.asset(
//                             'assets/images/needle.png',
//                             width: 200.w,
//                             height: 200.w,
//                             fit: BoxFit.contain,
//                           ),
//                         ),
//                       ),

//                       // Center Dot
//                       Container(
//                         width: 16.w,
//                         height: 16.w,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: selectedDesign == CompassImageDesign.classic
//                               ? Colors.white
//                               : Colors.white.withValues(alpha: 0.9),
//                           border: Border.all(
//                             color: selectedDesign.needleColor,
//                             width: 3,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.3),
//                               blurRadius: 4,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 SizedBox(height: 40.h),

//                 // Device Heading Info
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//                   decoration: BoxDecoration(
//                     color: selectedDesign == CompassImageDesign.classic
//                         ? Colors.white
//                         : Colors.white.withValues(alpha: 0.2),
//                     borderRadius: BorderRadius.circular(12.r),
//                   ),
//                   child: Text(
//                     'Heading Peranti: ${deviceHeading!.toStringAsFixed(1)}°',
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.w600,
//                       color: selectedDesign == CompassImageDesign.classic
//                           ? Colors.black87
//                           : Colors.white,
//                     ),
//                   ),
//                 ),

//                 SizedBox(height: 16.h),

//                 // Instruction Text
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 40.w),
//                   child: Text(
//                     'Pusingkan telefon sehingga anak panah menunjuk ke atas',
//                     style: TextStyle(
//                       fontSize: 14.sp,
//                       color: selectedDesign == CompassImageDesign.classic
//                           ? Colors.black54
//                           : Colors.white.withValues(alpha: 0.9),
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),

//                 SizedBox(height: 20.h),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

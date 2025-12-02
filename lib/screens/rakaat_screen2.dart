// import 'dart:async';

// import 'package:aqim/utils/loading_screen.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
// import 'package:permission_handler/permission_handler.dart';

// class RakaatScreen2 extends StatefulWidget {
//   const RakaatScreen2({super.key});

//   @override
//   State<RakaatScreen2> createState() => _RakaatScreen2State();
// }

// class _RakaatScreen2State extends State<RakaatScreen2> {
//   late PoseDetector _poseDetector;
//   late List<CameraDescription> _cameras;
//   CameraController? _camera;
//   bool _isProcessing = false;
//   bool _isSwitching = false;
//   int _cameraIndex = 1;
//   List<Pose> _poses = [];

//   // Rakaat tracking
//   Timer? _timer;
//   int _timerCounter = 0;
//   int _rakaatCount = 0;
//   bool _isStart = false;
//   PrayerPosition _currentPosition = PrayerPosition.unknown;

//   // Toggle skeleton visibility
//   bool _showSkeleton = true;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _initializePoseDetector();
//   }

//   Future<void> _initializeCamera() async {
//     if (!await Permission.camera.request().isGranted) return;

//     _cameras = await availableCameras();
//     _startCamera();
//   }

//   Future<void> _startCamera() async {
//     _camera = CameraController(_cameras[_cameraIndex], ResolutionPreset.medium);
//     await _camera!.initialize();
//     _camera!.startImageStream(_processCameraImage);
//     setState(() {});
//   }

//   Future<void> _switchCamera() async {
//     if (_isSwitching || _cameras.length < 2) return;

//     _isSwitching = true;

//     try {
//       if (_camera != null) {
//         try {
//           await _camera!.stopImageStream();
//         } catch (e) {
//           debugPrint('Error stopping image stream: $e');
//         }

//         await Future.delayed(const Duration(milliseconds: 100));

//         try {
//           await _camera!.dispose();
//         } catch (e) {
//           debugPrint('Error disposing camera: $e');
//         }

//         _camera = null;
//       }

//       _cameraIndex = (_cameraIndex + 1) % _cameras.length;
//       await _startCamera();
//     } catch (e) {
//       debugPrint('Error switching camera: $e');
//     } finally {
//       _isSwitching = false;
//     }
//   }

//   void _initializePoseDetector() {
//     final options = PoseDetectorOptions(
//       model: PoseDetectionModel.base,
//       mode: PoseDetectionMode.stream,
//     );
//     _poseDetector = PoseDetector(options: options);
//     debugPrint('🕺 PoseDetector initialized');
//   }

//   Future<void> _processCameraImage(CameraImage image) async {
//     if (_isProcessing || _isSwitching) return;

//     _isProcessing = true;

//     try {
//       if (!mounted || _camera == null || !_camera!.value.isInitialized) {
//         return;
//       }

//       final bytes = _convertYUV420toNV21(image);
//       final cameraDesc = _cameras[_cameraIndex];
//       final rotation =
//           InputImageRotationValue.fromRawValue(cameraDesc.sensorOrientation) ??
//               InputImageRotation.rotation0deg;

//       final inputImage = InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: Size(image.width.toDouble(), image.height.toDouble()),
//           rotation: rotation,
//           format: InputImageFormat.nv21,
//           bytesPerRow: image.planes[0].bytesPerRow,
//         ),
//       );

//       _poses = await _poseDetector.processImage(inputImage);

//       if (!mounted || _camera == null || _isSwitching) {
//         return;
//       }

//       if (_isStart) {
//         _detectAndCountPrayerPosition();
//       }

//       if (!mounted || _isSwitching) return;

//       setState(() {});
//     } catch (e) {
//       debugPrint('Error processing camera image: $e');
//     } finally {
//       _isProcessing = false;
//     }
//   }

//   @override
//   void dispose() {
//     _isSwitching = true;
//     _timer?.cancel();
//     _camera?.stopImageStream();
//     _camera?.dispose();
//     _poseDetector.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     if (_camera == null || !_camera!.value.isInitialized) {
//       return const Scaffold(body: Center(child: LoadingScreen()));
//     }

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Camera Preview
//           Positioned.fill(child: CameraPreview(_camera!)),

//           // Skeleton Overlay (toggleable)
//           if (_showSkeleton && _poses.isNotEmpty && _camera != null)
//             Positioned.fill(
//               child: CustomPaint(
//                 painter: PosePainter(
//                   pose: _poses.first,
//                   previewSize: _camera!.value.previewSize!,
//                   camera: _camera!,
//                 ),
//               ),
//             ),

//           // Top Bar
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: EdgeInsets.only(
//                 top: MediaQuery.of(context).padding.top + 8.h,
//                 left: 16.w,
//                 right: 16.w,
//                 bottom: 16.h,
//               ),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.black.withValues(alpha: 0.7),
//                     Colors.transparent,
//                   ],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                 ),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Back Button
//                   IconButton(
//                     icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
//                     onPressed: () => Navigator.pop(context),
//                   ),

//                   // Title
//                   Text(
//                     'Kira Rakaat',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20.sp,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   // Switch Camera Button
//                   IconButton(
//                     icon: Icon(Icons.cameraswitch, color: Colors.white, size: 24.sp),
//                     onPressed: _switchCamera,
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Center - Rakaat Counter
//           Center(
//             child: Container(
//               padding: EdgeInsets.all(32.w),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: colorScheme.primary.withValues(alpha: 0.9),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.5),
//                     blurRadius: 20,
//                     spreadRadius: 5,
//                   ),
//                 ],
//                 border: Border.all(
//                   color: Colors.white,
//                   width: 4.w,
//                 ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     'Rakaat',
//                     style: TextStyle(
//                       color: colorScheme.onPrimary,
//                       fontSize: 18.sp,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   SizedBox(height: 8.h),
//                   Text(
//                     _rakaatCount.toString(),
//                     style: TextStyle(
//                       color: colorScheme.onPrimary,
//                       fontSize: 72.sp,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Bottom Control Panel
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: EdgeInsets.all(24.w),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.transparent,
//                     Colors.black.withValues(alpha: 0.8),
//                   ],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                 ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Position Info
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withValues(alpha: 0.2),
//                       borderRadius: BorderRadius.circular(20.r),
//                     ),
//                     child: Text(
//                       'Posisi: ${_currentPosition.name.toUpperCase()}',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),

//                   SizedBox(height: 16.h),

//                   // Timer
//                   if (_isStart)
//                     Text(
//                       'Masa: $_timerCounter saat',
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontSize: 14.sp,
//                       ),
//                     ),

//                   SizedBox(height: 16.h),

//                   // Controls Row
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       // Toggle Skeleton Button
//                       Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             onPressed: () {
//                               setState(() {
//                                 _showSkeleton = !_showSkeleton;
//                               });
//                             },
//                             icon: Icon(
//                               _showSkeleton
//                                   ? Icons.visibility
//                                   : Icons.visibility_off,
//                               color: Colors.white,
//                               size: 28.sp,
//                             ),
//                             style: IconButton.styleFrom(
//                               backgroundColor:
//                                   Colors.white.withValues(alpha: 0.2),
//                               padding: EdgeInsets.all(16.w),
//                             ),
//                           ),
//                           SizedBox(height: 4.h),
//                           Text(
//                             'Skeleton',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12.sp,
//                             ),
//                           ),
//                         ],
//                       ),

//                       // Start/Stop Button
//                       Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           ElevatedButton(
//                             onPressed: _toggleKiraRakaat,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: _isStart
//                                   ? colorScheme.error
//                                   : colorScheme.primary,
//                               foregroundColor: _isStart
//                                   ? colorScheme.onError
//                                   : colorScheme.onPrimary,
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: 32.w,
//                                 vertical: 16.h,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30.r),
//                               ),
//                               elevation: 8,
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   _isStart ? Icons.stop : Icons.play_arrow,
//                                   size: 24.sp,
//                                 ),
//                                 SizedBox(width: 8.w),
//                                 Text(
//                                   _isStart ? 'STOP' : 'START',
//                                   style: TextStyle(
//                                     fontSize: 18.sp,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           SizedBox(height: 4.h),
//                           Text(
//                             _isStart ? 'Menghitung...' : 'Mula Kira',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12.sp,
//                             ),
//                           ),
//                         ],
//                       ),

//                       // Reset Button
//                       Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             onPressed: _resetCounter,
//                             icon: Icon(
//                               Icons.refresh,
//                               color: Colors.white,
//                               size: 28.sp,
//                             ),
//                             style: IconButton.styleFrom(
//                               backgroundColor:
//                                   Colors.white.withValues(alpha: 0.2),
//                               padding: EdgeInsets.all(16.w),
//                             ),
//                           ),
//                           SizedBox(height: 4.h),
//                           Text(
//                             'Reset',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12.sp,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),

//                   SizedBox(height: 8.h),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _resetCounter() {
//     setState(() {
//       _rakaatCount = 0;
//       _timerCounter = 0;
//       _currentPosition = PrayerPosition.unknown;
//     });
//   }

//   void _toggleKiraRakaat() {
//     if (_isStart) {
//       // Stop timer
//       _timer?.cancel();
//       setState(() {
//         _isStart = false;
//         _timerCounter = 0;
//         _currentPosition = PrayerPosition.unknown;
//       });
//     } else {
//       // Start timer
//       setState(() {
//         _isStart = true;
//       });

//       _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//         if (!mounted) return;
//         setState(() {
//           _timerCounter++;
//         });
//       });
//     }
//   }

//   void _detectAndCountPrayerPosition() {
//     final detected = _detectPrayerPosition();

//     if (_currentPosition != detected) {
//       final oldPosition = _currentPosition;
//       final newPosition = detected;

//       // Count Sedekap when transitioning TO sedekap FROM non-sedekap
//       if (newPosition == PrayerPosition.sedekap &&
//           oldPosition != PrayerPosition.sedekap) {
//         // RAKAAT PERTAMA - no time requirement
//         if (_rakaatCount == 0) {
//           _rakaatCount++;
//           debugPrint("✅ Rakaat 1 detected");
//         }
//         // RAKAAT KEDUA - after ~50 seconds
//         else if (_rakaatCount == 1 && _timerCounter > 50) {
//           _rakaatCount++;
//           _timerCounter = 0;
//           debugPrint("✅ Rakaat 2 detected");
//         }
//         // RAKAAT KETIGA - after ~70 seconds
//         else if (_rakaatCount == 2 && _timerCounter > 70) {
//           _rakaatCount++;
//           _timerCounter = 0;
//           debugPrint("✅ Rakaat 3 detected");
//         }
//         // RAKAAT KEEMPAT - after ~40 seconds
//         else if (_rakaatCount == 3 && _timerCounter > 40) {
//           _rakaatCount++;
//           _timerCounter = 0;
//           debugPrint("✅ Rakaat 4 detected");
//         }
//       }

//       setState(() {
//         _currentPosition = newPosition;
//       });

//       debugPrint('Transition: $oldPosition → $newPosition');
//     }
//   }

//   PrayerPosition _detectPrayerPosition() {
//     const double confidenceThreshold = 0.6;
//     final pose = _poses.isNotEmpty ? _poses.first : Pose(landmarks: {});

//     final nose = pose.landmarks[PoseLandmarkType.nose];
//     final bahuKiri = pose.landmarks[PoseLandmarkType.leftShoulder];
//     final bahuKanan = pose.landmarks[PoseLandmarkType.rightShoulder];
//     final sikuKiri = pose.landmarks[PoseLandmarkType.leftElbow];
//     final sikuKanan = pose.landmarks[PoseLandmarkType.rightElbow];
//     final tanganKiri = pose.landmarks[PoseLandmarkType.leftWrist];
//     final tanganKanan = pose.landmarks[PoseLandmarkType.rightWrist];
//     final pinggulKiri = pose.landmarks[PoseLandmarkType.leftHip];
//     final pinggulKanan = pose.landmarks[PoseLandmarkType.rightHip];

//     if (nose == null ||
//         bahuKiri == null ||
//         bahuKanan == null ||
//         tanganKiri == null ||
//         tanganKanan == null) {
//       return PrayerPosition.unknown;
//     }

//     // DETECT SEDEKAP
//     if (nose.likelihood > confidenceThreshold &&
//         bahuKiri.likelihood > confidenceThreshold &&
//         bahuKanan.likelihood > confidenceThreshold &&
//         sikuKiri != null &&
//         sikuKiri.likelihood > confidenceThreshold &&
//         sikuKanan != null &&
//         sikuKanan.likelihood > confidenceThreshold &&
//         tanganKiri.likelihood > confidenceThreshold &&
//         tanganKanan.likelihood > confidenceThreshold) {
//       final purataBahuY = (bahuKiri.y + bahuKanan.y) / 2;
//       final tengahBadan = (bahuKiri.x + bahuKanan.x) / 2;
//       final purataBahuZ = (bahuKiri.z + bahuKanan.z) / 2;
//       final purataTanganZ = (tanganKiri.z + tanganKanan.z) / 2;
//       final bool tanganDiHadapan = purataTanganZ < purataBahuZ + 50;
//       final purataSikuY = (sikuKiri.y + sikuKanan.y) / 2;

//       bool tanganDiKawasanDada;
//       if (pinggulKiri != null &&
//           pinggulKanan != null &&
//           pinggulKiri.likelihood > confidenceThreshold &&
//           pinggulKanan.likelihood > confidenceThreshold) {
//         final purataPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;
//         tanganDiKawasanDada = tanganKiri.y > purataBahuY - 100 &&
//             tanganKanan.y > purataBahuY - 100 &&
//             tanganKiri.y < purataPinggulY &&
//             tanganKanan.y < purataPinggulY;
//       } else {
//         tanganDiKawasanDada = tanganKiri.y > purataBahuY - 100 &&
//             tanganKanan.y > purataBahuY - 100 &&
//             tanganKiri.y > purataSikuY - 150 &&
//             tanganKanan.y > purataSikuY - 150;
//       }

//       final bool tanganBerdekatan = (tanganKanan.x - tanganKiri.x).abs() < 100;
//       final purataTanganX = (tanganKiri.x + tanganKanan.x) / 2;
//       final bool tanganDiTengah = (purataTanganX - tengahBadan).abs() < 100;
//       final bool sikuSemulajadi =
//           sikuKiri.y > purataBahuY - 80 && sikuKanan.y > purataBahuY - 80;
//       final bool tanganDiBawahHidung =
//           tanganKiri.y > nose.y - 50 && tanganKanan.y > nose.y - 50;

//       if (tanganDiKawasanDada &&
//           tanganBerdekatan &&
//           tanganDiTengah &&
//           sikuSemulajadi &&
//           tanganDiHadapan &&
//           tanganDiBawahHidung) {
//         return PrayerPosition.sedekap;
//       }
//     }

//     // DETECT TAKBIRAATUL IHRAM
//     if (nose.likelihood > confidenceThreshold &&
//         bahuKiri.likelihood > confidenceThreshold &&
//         bahuKanan.likelihood > confidenceThreshold &&
//         tanganKiri.likelihood > confidenceThreshold &&
//         tanganKanan.likelihood > confidenceThreshold &&
//         sikuKiri!.likelihood > confidenceThreshold &&
//         sikuKanan!.likelihood > confidenceThreshold) {
//       if (tanganKiri.y < bahuKiri.y &&
//           tanganKanan.y < bahuKanan.y &&
//           sikuKiri.y > bahuKiri.y &&
//           sikuKanan.y > bahuKanan.y) {
//         return PrayerPosition.ihram;
//       }
//     }

//     // DETECT QIYAM
//     if (nose.likelihood > confidenceThreshold &&
//         bahuKiri.likelihood > confidenceThreshold &&
//         bahuKanan.likelihood > confidenceThreshold) {
//       final avgBahuY = (bahuKiri.y + bahuKanan.y) / 2;

//       bool tanganNampak = tanganKiri.likelihood > confidenceThreshold &&
//           tanganKanan.likelihood > confidenceThreshold;

//       if (tanganNampak) {
//         final avgTanganY = (tanganKiri.y + tanganKanan.y) / 2;
//         final bool handsDown = avgTanganY > avgBahuY;
//         final bool handsApart = (tanganKanan.x - tanganKiri.x).abs() > 100;

//         if (handsDown && handsApart) {
//           return PrayerPosition.qiyam;
//         }
//       } else {
//         final bool badanTegak = nose.y < avgBahuY;
//         bool posisiBerdiri = true;
//         if (pinggulKiri != null &&
//             pinggulKanan != null &&
//             pinggulKiri.likelihood > confidenceThreshold &&
//             pinggulKanan.likelihood > confidenceThreshold) {
//           final avgPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;
//           posisiBerdiri = avgPinggulY > avgBahuY + 100;
//         }

//         final bool bahuSeimbang = (bahuKiri.y - bahuKanan.y).abs() < 50;

//         if (badanTegak && posisiBerdiri && bahuSeimbang) {
//           return PrayerPosition.qiyam;
//         }
//       }
//     }

//     return PrayerPosition.unknown;
//   }

//   Uint8List _convertYUV420toNV21(CameraImage image) {
//     final int width = image.width;
//     final int height = image.height;
//     final int ySize = width * height;
//     final int uvSize = width * height ~/ 2;
//     final Uint8List nv21 = Uint8List(ySize + uvSize);

//     int offset = 0;
//     final yPlane = image.planes[0];
//     for (int row = 0; row < height; row++) {
//       nv21.setRange(
//         offset,
//         offset + width,
//         yPlane.bytes.sublist(
//           row * yPlane.bytesPerRow,
//           row * yPlane.bytesPerRow + width,
//         ),
//       );
//       offset += width;
//     }

//     final uPlane = image.planes[1];
//     final vPlane = image.planes[2];
//     final chromaHeight = height ~/ 2;
//     final chromaWidth = width ~/ 2;

//     for (int row = 0; row < chromaHeight; row++) {
//       int uRowStart = row * uPlane.bytesPerRow;
//       int vRowStart = row * vPlane.bytesPerRow;
//       for (int col = 0; col < chromaWidth; col++) {
//         nv21[offset++] = vPlane.bytes[vRowStart + col * vPlane.bytesPerPixel!];
//         nv21[offset++] = uPlane.bytes[uRowStart + col * uPlane.bytesPerPixel!];
//       }
//     }

//     return nv21;
//   }
// }

// // Prayer positions enum
// enum PrayerPosition {
//   unknown,
//   qiyam,
//   ihram,
//   sedekap,
//   ruku,
//   sujud,
//   julus,
// }

// // Pose Painter for skeleton overlay
// class PosePainter extends CustomPainter {
//   final Pose? pose;
//   final Size previewSize;
//   final CameraController camera;

//   PosePainter({
//     required this.pose,
//     required this.previewSize,
//     required this.camera,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (pose == null) return;

//     const double confidenceThreshold = 0.8;
//     const Color circleColor = Colors.white;
//     const double circleRadius = 4.0;
//     const double strokeWidth = 1.0;

//     final landmarks = {
//       'nose': pose!.landmarks[PoseLandmarkType.nose],
//       'leftEye': pose!.landmarks[PoseLandmarkType.leftEyeInner],
//       'rightEye': pose!.landmarks[PoseLandmarkType.rightEyeInner],
//       'leftShoulder': pose!.landmarks[PoseLandmarkType.leftShoulder],
//       'rightShoulder': pose!.landmarks[PoseLandmarkType.rightShoulder],
//       'leftElbow': pose!.landmarks[PoseLandmarkType.leftElbow],
//       'rightElbow': pose!.landmarks[PoseLandmarkType.rightElbow],
//       'leftWrist': pose!.landmarks[PoseLandmarkType.leftWrist],
//       'rightWrist': pose!.landmarks[PoseLandmarkType.rightWrist],
//       'leftIndex': pose!.landmarks[PoseLandmarkType.leftIndex],
//       'rightIndex': pose!.landmarks[PoseLandmarkType.rightIndex],
//       'leftHip': pose!.landmarks[PoseLandmarkType.leftHip],
//       'rightHip': pose!.landmarks[PoseLandmarkType.rightHip],
//       'leftKnee': pose!.landmarks[PoseLandmarkType.leftKnee],
//       'rightKnee': pose!.landmarks[PoseLandmarkType.rightKnee],
//       'leftAnkle': pose!.landmarks[PoseLandmarkType.leftAnkle],
//       'rightAnkle': pose!.landmarks[PoseLandmarkType.rightAnkle],
//       'leftFootIndex': pose!.landmarks[PoseLandmarkType.leftFootIndex],
//       'rightFootIndex': pose!.landmarks[PoseLandmarkType.rightFootIndex],
//       'leftHeel': pose!.landmarks[PoseLandmarkType.leftHeel],
//       'rightHeel': pose!.landmarks[PoseLandmarkType.rightHeel],
//     };

//     final paint = Paint()
//       ..color = circleColor
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth;

//     landmarks.forEach((name, landmark) {
//       if (landmark == null) return;

//       if (landmark.likelihood < confidenceThreshold) return;

//       final scaleX = size.width / previewSize.height;
//       final scaleY = size.height / previewSize.width;

//       double x = landmark.x * scaleX;
//       double y = landmark.y * scaleY;

//       if (camera.description.lensDirection == CameraLensDirection.front) {
//         x = size.width - x;
//       }

//       canvas.drawCircle(Offset(x, y), circleRadius, paint);
//     });

//     // Helper to get scaled Offset
//     Offset? getOffset(PoseLandmark? landmark) {
//       if (landmark == null || landmark.likelihood < confidenceThreshold) {
//         return null;
//       }
//       final scaleX = size.width / previewSize.height;
//       final scaleY = size.height / previewSize.width;
//       double x = landmark.x * scaleX;
//       double y = landmark.y * scaleY;
//       if (camera.description.lensDirection == CameraLensDirection.front) {
//         x = size.width - x;
//       }
//       return Offset(x, y);
//     }

//     // Draw lines between joints
//     void drawLine(PoseLandmark? a, PoseLandmark? b) {
//       final offsetA = getOffset(a);
//       final offsetB = getOffset(b);
//       if (offsetA != null && offsetB != null) {
//         canvas.drawLine(offsetA, offsetB, paint);
//       }
//     }

//     // Draw skeleton lines
//     drawLine(landmarks['leftShoulder'], landmarks['rightShoulder']);
//     drawLine(landmarks['leftShoulder'], landmarks['leftElbow']);
//     drawLine(landmarks['leftElbow'], landmarks['leftWrist']);
//     drawLine(landmarks['leftElbow'], landmarks['leftIndex']);
//     drawLine(landmarks['rightShoulder'], landmarks['rightElbow']);
//     drawLine(landmarks['rightElbow'], landmarks['rightWrist']);
//     drawLine(landmarks['rightWrist'], landmarks['rightIndex']);
//     drawLine(landmarks['leftShoulder'], landmarks['leftHip']);
//     drawLine(landmarks['rightShoulder'], landmarks['rightHip']);
//     drawLine(landmarks['leftHip'], landmarks['rightHip']);
//     drawLine(landmarks['leftHip'], landmarks['leftKnee']);
//     drawLine(landmarks['rightHip'], landmarks['rightKnee']);
//     drawLine(landmarks['leftHip'], landmarks['leftKnee']);
//     drawLine(landmarks['leftKnee'], landmarks['leftAnkle']);
//     drawLine(landmarks['rightHip'], landmarks['rightKnee']);
//     drawLine(landmarks['rightKnee'], landmarks['rightAnkle']);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

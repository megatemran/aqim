import 'dart:async';

import 'package:aqim/utils/loading_screen.dart';
import 'package:aqim/utils/plugin.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class RakaatScreen extends StatefulWidget {
  const RakaatScreen({super.key});

  @override
  State<RakaatScreen> createState() => _RakaatScreenState();
}

class _RakaatScreenState extends State<RakaatScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late PoseDetector _poseDetector;
  late List<CameraDescription> _cameras;
  CameraController? _camera;
  bool _isProcessing = false;
  bool _isSwitching = false;
  bool _isShowCamera = false;
  final int _cameraIndex = 1;
  List<Pose> _poses = [];

  // For displaying debug info
  String debugText = '';

  // ⚙️ RAKAAT TIMING CONFIGURATION
  static const int _minTimeBeforeFirstRakaat = 5; // seconds
  static const int _minTimeBetweenRakaat2 = 75; // ~1 rakaat cycle
  static const int _minTimeBetweenRakaat3 = 85; // includes tahiyat awal
  static const int _minTimeBetweenRakaat4 = 40; // shorter cycle

  // 🎨 ANIMATION CONFIGURATION
  late AnimationController _rakaatAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializePoseDetector();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    // Create animation controller (600ms duration)
    _rakaatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Scale animation: 1.0 → 1.3 → 1.0 (pop effect)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_rakaatAnimationController);

    // Opacity animation for glow effect
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(_rakaatAnimationController);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_camera == null || !_camera!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // App going to background - pause camera
      debugPrint('📱 App inactive/paused - stopping camera stream');
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      // App coming back - resume camera
      debugPrint('📱 App resumed - restarting camera stream');
      _resumeCamera();
    }
  }

  void _pauseCamera() {
    try {
      if (_camera != null && _camera!.value.isStreamingImages) {
        _camera?.stopImageStream();
        debugPrint('✅ Camera stream paused');
      }
    } catch (e) {
      debugPrint('⚠️ Error pausing camera: $e');
    }
  }

  void _resumeCamera() {
    try {
      if (_camera != null &&
          _camera!.value.isInitialized &&
          !_camera!.value.isStreamingImages) {
        _camera!.startImageStream(_processCameraImage);
        debugPrint('✅ Camera stream resumed');
      }
    } catch (e) {
      debugPrint('⚠️ Error resuming camera: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (!await Permission.camera.request().isGranted) return;
      _cameras = await availableCameras();
      await _startCamera();
    } catch (e) {
      debugPrint('❌ Error initializing camera: $e');
    }
  }

  Future<void> _startCamera() async {
    try {
      _camera = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
      );
      await _camera!.initialize();
      if (!mounted) return;
      _camera!.startImageStream(_processCameraImage);
      setState(() {});
    } catch (e) {
      debugPrint('❌ Error starting camera: $e');
    }
  }

  // Future<void> _switchCamera() async {
  //   // Prevent concurrent switches
  //   if (_isSwitching || _cameras.length < 2) return;

  //   _isSwitching = true;

  //   try {
  //     if (_camera != null) {
  //       // Stop image stream first
  //       try {
  //         await _camera!.stopImageStream();
  //       } catch (e) {
  //         debugPrint('Error stopping image stream: $e');
  //       }

  //       // Wait a bit for any pending callbacks to complete
  //       await Future.delayed(const Duration(milliseconds: 100));

  //       // Dispose camera
  //       try {
  //         await _camera!.dispose();
  //       } catch (e) {
  //         debugPrint('Error disposing camera: $e');
  //       }

  //       _camera = null;
  //     }

  //     // Switch camera index
  //     _cameraIndex = (_cameraIndex + 1) % _cameras.length;

  //     // Start new camera
  //     await _startCamera();
  //   } catch (e) {
  //     debugPrint('Error switching camera: $e');
  //   } finally {
  //     _isSwitching = false;
  //   }
  // }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    );
    _poseDetector = PoseDetector(options: options);
    debugPrint('🕺 PoseDetector initialized with STREAM_MODE');
  }

  Future<void> _processCameraImage(CameraImage image) async {
    // Don't process if switching or already processing
    if (_isProcessing || _isSwitching) return;

    _isProcessing = true;

    try {
      // Check if camera is still valid
      if (!mounted || _camera == null || !_camera!.value.isInitialized) {
        return;
      }

      final bytes = _convertYUV420toNV21(image);
      final cameraDesc = _cameras[_cameraIndex];
      final rotation =
          InputImageRotationValue.fromRawValue(cameraDesc.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      _poses = await _poseDetector.processImage(inputImage);

      // Check again after async operation
      if (!mounted || _camera == null || _isSwitching) {
        return;
      }

      // ✅ Add this: Detect and count prayer position if tracking is started
      if (_isStart) {
        _detectAndCountPrayerPosition();
      }

      // final previewSize = _camera!.value.previewSize!;
      // final scaleX = previewSize.height / image.width;
      // final scaleY = previewSize.width / image.height;

      // String info =
      //     '📸 Image Size: ${image.width} x ${image.height}\n'
      //     '📷 Preview Size: ${previewSize.width.toStringAsFixed(1)} x ${previewSize.height.toStringAsFixed(1)}\n'
      //     '🔄 Sensor Orientation: ${cameraDesc.sensorOrientation}°\n';

      // if (_poses.isNotEmpty) {
      //   final nose = _poses.first.landmarks[PoseLandmarkType.nose];
      //   if (nose != null) {
      //     final screenX = nose.x * scaleX;
      //     final screenY = nose.y * scaleY;
      //     info +=
      //         '🎯 NOSE (Image coords): ${nose.x.toStringAsFixed(1)}, ${nose.y.toStringAsFixed(1)}\n'
      //         '🎯 NOSE (Screen coords): ${screenX.toStringAsFixed(1)}, ${screenY.toStringAsFixed(1)}\n';
      //   }
      // }

      // info += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

      // Final check before setState
      if (!mounted || _isSwitching) return;

      // setState(() {
      //   debugText = info;
      // });

      setState(() {});
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // String _getDetectedBodyParts() {
  //   if (_poses.isEmpty) return 'No pose detected';

  //   final pose = _poses.first;
  //   List<String> detectedParts = [];

  //   // Confidence threshold for considering a landmark as "detected"
  //   const double confidenceThreshold = 0.5;
  //   //   function to check if landmark is confidently detected
  //   bool isDetected(PoseLandmarkType? type) {
  //     final landmark = pose.landmarks[type];
  //     return landmark != null && landmark.likelihood > confidenceThreshold;
  //   }

  //   // Check for face
  //   if (isDetected(PoseLandmarkType.nose)) {
  //     detectedParts.add('Face');
  //   }

  //   // Check for upper body
  //   bool hasUpperBody =
  //       isDetected(PoseLandmarkType.leftShoulder) ||
  //       isDetected(PoseLandmarkType.rightShoulder);
  //   if (hasUpperBody) {
  //     detectedParts.add('Upper Body');
  //   }

  //   // Check for arms
  //   bool hasArms =
  //       isDetected(PoseLandmarkType.leftWrist) ||
  //       isDetected(PoseLandmarkType.rightWrist);
  //   if (hasArms) {
  //     detectedParts.add('Arms');
  //   }

  //   // Check for legs (require BOTH knees AND ankles to be confident)
  //   bool hasLegs =
  //       (isDetected(PoseLandmarkType.leftKnee) ||
  //           isDetected(PoseLandmarkType.rightKnee)) &&
  //       (isDetected(PoseLandmarkType.leftAnkle) ||
  //           isDetected(PoseLandmarkType.rightAnkle));
  //   if (hasLegs) {
  //     detectedParts.add('Legs');
  //   }

  //   if (detectedParts.isEmpty) {
  //     return 'Partial detection';
  //   }

  //   return detectedParts.join(', ');
  // }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _rakaatAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _isSwitching = true; // Prevent any new processing
    _camera?.stopImageStream();
    _camera?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_camera == null || !_camera!.value.isInitialized) {
      return const Scaffold(body: Center(child: LoadingScreen()));
    }
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isShowCamera
            ? Brightness.light
            : isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: _isShowCamera
            ? Brightness.dark
            : isDark
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: _isShowCamera ? Colors.black : cs.surface,
        systemNavigationBarIconBrightness: _isShowCamera
            ? Brightness.light
            : isDark
            ? Brightness.light
            : Brightness.dark,
        // Divider
        // systemNavigationBarDividerColor: cs.outline.withValues(alpha: 0.2),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            _isShowCamera == false
                ? Container(color: cs.surface)
                : Stack(
                    children: [
                      Positioned.fill(child: CameraPreview(_camera!)),
                      // Nose overlay
                      if (_poses.isNotEmpty && _camera != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: PosePainter(
                              pose: _poses.first,
                              previewSize: _camera!.value.previewSize!,
                              camera: _camera!,
                            ),
                          ),
                        ),
                    ],
                  ),

            Positioned(
              top: 40,
              right: 20,
              left: 20,
              child: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() {
                        _isShowCamera = !_isShowCamera;
                      });
                    },
                    icon: Icon(Icons.info_outline),
                  ),
                  // FloatingActionButton(
                  //   onPressed: () {
                  //     setState(() {
                  //       _isShowCamera = !_isShowCamera;
                  //     });
                  //   },
                  //   child: const Icon(Icons.info_outline),
                  // ),
                  // SizedBox(width: 16.w),
                  // FloatingActionButton(
                  //   onPressed: _switchCamera,
                  //   child: const Icon(Icons.cameraswitch),
                  // ),
                ],
              ),
            ),

            // Positioned(
            //   top: 50.h,
            //   left: 40.w,
            //   child: Column(
            //     crossAxisAlignment: .start,
            //     children: [
            //       Text(
            //         'Pervious: ${_previousPosition.name}',
            //         style: TextStyle(color: Colors.white, fontSize: 24.sp),
            //       ),
            //       Text(
            //         'Current: ${_currentPosition.name}',
            //         style: TextStyle(color: Colors.white, fontSize: 24.sp),
            //       ),
            //     ],
            //   ),
            // ),
            Align(
              alignment: .center,
              child: AnimatedBuilder(
                animation: _rakaatAnimationController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect (background layer)
                      if (_opacityAnimation.value > 0)
                        Transform.scale(
                          scale: _scaleAnimation.value * 1.1,
                          child: Text(
                            _rakaatCount.toString(),
                            style: TextStyle(
                              color: (_isShowCamera ? Colors.white : cs.primary)
                                  .withValues(
                                    alpha: _opacityAnimation.value * 0.5,
                                  ),
                              fontSize: 200.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // Main number (with scale animation)
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Text(
                          _rakaatCount.toString(),
                          style: TextStyle(
                            color: _isShowCamera ? Colors.white : cs.onSurface,
                            fontSize: 200.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    !_isShowCamera
                        ? SizedBox.shrink()
                        : Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cs.tertiaryContainer.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(radius),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15.w,
                                vertical: 12.h,
                              ),
                              child: Column(
                                mainAxisAlignment: .start,
                                crossAxisAlignment: .start,
                                children: [
                                  Text(
                                    'Timer: ${_timerCounter.toString()}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  Text(
                                    'Current: ${_detectPrayerPosition().name}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  Text(
                                    'Semasa: ${_currentPosition.name}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  Text(
                                    'Sebelum: ${_previousPosition.name}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    SizedBox(height: 16.h),
                    Text(
                      'Letakkan telefon di hadapan anda ketika solat\n'
                      'dan tekan MULA untuk mula mengira rakaat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isShowCamera
                            ? Colors.white.withValues(alpha: 0.6)
                            : cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset button (only show when tracking is active)
                        if (_isStart && _rakaatCount > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _resetRakaatCount,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _isShowCamera
                                      ? Colors.white
                                      : cs.outline,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Set Semula',
                                style: TextStyle(
                                  color: _isShowCamera
                                      ? Colors.white
                                      : cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                        if (_isStart && _rakaatCount > 0) SizedBox(width: 12.w),
                        // Start/Stop button
                        Expanded(
                          child: FilledButton(
                            onPressed: _toggleKiraRakaat,
                            style: FilledButton.styleFrom(
                              backgroundColor: _isStart ? cs.error : cs.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isStart ? 'Berhenti' : 'Mula',
                              style: TextStyle(color: cs.onPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Positioned(
            //   left: 10,
            //   bottom: 20,
            //   child: Column(
            //     children: [
            //       Text(
            //         _rakaatCount.toString(),
            //         style: TextStyle(color: Colors.white, fontSize: 60.sp),
            //       ),
            //       SizedBox(height: 24.h),
            //       Text(
            //         _timerCounter.toString(),
            //         style: TextStyle(color: Colors.white, fontSize: 24.sp),
            //       ),
            //       FilledButton(
            //         onPressed: _toggleKiraRakaat,
            //         style: ButtonStyle(
            //           backgroundColor: WidgetStateProperty.all(
            //             _isStart ? Colors.red : Colors.green,
            //           ),
            //         ),
            //         child: Text(_isStart ? 'Stop' : 'Start'),
            //       ),

            //       Text(
            //         'Position : ${_detectPrayerPosition().name}',
            //         style: TextStyle(color: Colors.white, fontSize: 24.sp),
            //       ),
            //       Container(
            //         padding: const EdgeInsets.all(8),
            //         color: Colors.black54,
            //         child: Column(
            //           children: [
            //             Text(
            //               _getDetectedBodyParts(),
            //               style: const TextStyle(
            //                 color: Colors.white,
            //                 fontSize: 12,
            //               ),
            //             ),
            //             Text(
            //               debugText,
            //               style: const TextStyle(
            //                 color: Colors.white,
            //                 fontSize: 12,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Uint8List _convertYUV420toNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    int offset = 0;
    final yPlane = image.planes[0];
    for (int row = 0; row < height; row++) {
      nv21.setRange(
        offset,
        offset + width,
        yPlane.bytes.sublist(
          row * yPlane.bytesPerRow,
          row * yPlane.bytesPerRow + width,
        ),
      );
      offset += width;
    }

    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final chromaHeight = height ~/ 2;
    final chromaWidth = width ~/ 2;

    for (int row = 0; row < chromaHeight; row++) {
      int uRowStart = row * uPlane.bytesPerRow;
      int vRowStart = row * vPlane.bytesPerRow;
      for (int col = 0; col < chromaWidth; col++) {
        nv21[offset++] = vPlane.bytes[vRowStart + col * vPlane.bytesPerPixel!];
        nv21[offset++] = uPlane.bytes[uRowStart + col * uPlane.bytesPerPixel!];
      }
    }

    return nv21;
  }

  Timer? _timer;
  int _timerCounter = 0;
  int _rakaatCount = 0;
  bool _isStart = false;
  PrayerPosition _previousPosition = PrayerPosition.unknown;
  PrayerPosition _currentPosition = PrayerPosition.unknown;

  /// Helper method to increment rakaat count with feedback
  void _incrementRakaat(int rakaatNumber) {
    setState(() {
      _rakaatCount++;
      _timerCounter = 0;
    });

    // 🔊 Provide haptic feedback
    HapticFeedback.mediumImpact();

    // 🎨 Trigger visual animation
    _rakaatAnimationController.forward(from: 0.0);

    debugPrint("✅ Rakaat $rakaatNumber detected");

    // TODO: Add audio feedback here if needed (e.g., play sound)
  }

  void _detectAndCountPrayerPosition() {
    final detected = _detectPrayerPosition();

    // Position changed?
    if (_currentPosition != detected) {
      // STORE OLD VALUES FIRST
      final oldPosition = _currentPosition;
      final newPosition = detected;

      // Count Sedekap when transitioning TO sedekap FROM non-sedekap
      if (newPosition == PrayerPosition.sedekap &&
          oldPosition != PrayerPosition.sedekap) {
        // RAKAAT PERTAMA - detect first sedekap after minimum time
        if (_rakaatCount == 0 && _timerCounter > _minTimeBeforeFirstRakaat) {
          if (!mounted) return;
          _incrementRakaat(1);
        }
        // RAKAAT KEDUA - after ~75 seconds (1 rakaat cycle)
        else if (_rakaatCount == 1 && _timerCounter > _minTimeBetweenRakaat2) {
          if (!mounted) return;
          _incrementRakaat(2);
        }
        // RAKAAT KETIGA - after ~95 seconds (includes tahiyat awal)
        else if (_rakaatCount == 2 && _timerCounter > _minTimeBetweenRakaat3) {
          if (!mounted) return;
          _incrementRakaat(3);
        }
        // RAKAAT KEEMPAT - after ~40 seconds (shorter, just 1 rakaat)
        else if (_rakaatCount == 3 && _timerCounter > _minTimeBetweenRakaat4) {
          if (!mounted) return;
          _incrementRakaat(4);
        }
      }

      // UPDATE STATE

      if (!mounted) return;
      setState(() {
        _previousPosition = oldPosition;
        _currentPosition = newPosition;
      });

      // PRINT USING LOCAL VARIABLES
      debugPrint('Transition: $oldPosition → $newPosition');
    }
  }

  void _toggleKiraRakaat() {
    if (_isStart) {
      // Stop timer
      _timer?.cancel();

      if (mounted) {
        setState(() {
          _isStart = false;
          _timerCounter = 0;
          _previousPosition = PrayerPosition.unknown;
          _rakaatCount = 0;
          _currentPosition = PrayerPosition.unknown;
        });
      }
    } else {
      // Start timer
      if (mounted) {
        setState(() {
          _isStart = true;
        });
      }

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _timerCounter++;
        });
      });
    }
  }

  /// Reset rakaat count without stopping
  void _resetRakaatCount() {
    if (!mounted) return;
    setState(() {
      _rakaatCount = 0;
      _timerCounter = 0;
      _previousPosition = PrayerPosition.unknown;
      _currentPosition = PrayerPosition.unknown;
    });
    HapticFeedback.lightImpact();
    debugPrint("🔄 Rakaat counter reset");
  }

  PrayerPosition _detectPrayerPosition() {
    const double confidenceThreshold = 0.6;
    final pose = _poses.isNotEmpty ? _poses.first : Pose(landmarks: {});

    // Get key landmarks
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final bahuKiri = pose.landmarks[PoseLandmarkType.leftShoulder];
    final bahuKanan = pose.landmarks[PoseLandmarkType.rightShoulder];
    final sikuKiri = pose.landmarks[PoseLandmarkType.leftElbow];
    final sikuKanan = pose.landmarks[PoseLandmarkType.rightElbow];
    final tanganKiri = pose.landmarks[PoseLandmarkType.leftWrist];
    final tanganKanan = pose.landmarks[PoseLandmarkType.rightWrist];
    final pinggulKiri = pose.landmarks[PoseLandmarkType.leftHip];
    final pinggulKanan = pose.landmarks[PoseLandmarkType.rightHip];
    final lututKiri = pose.landmarks[PoseLandmarkType.leftKnee];
    final lututKanan = pose.landmarks[PoseLandmarkType.rightKnee];

    if (nose == null ||
        bahuKiri == null ||
        bahuKanan == null ||
        tanganKiri == null ||
        tanganKanan == null) {
      return PrayerPosition.unknown;
    }

    // =====================================================
    // DETECT SEDEKAP (dengan atau tanpa pinggul)
    // =====================================================
    if (nose.likelihood > confidenceThreshold &&
        bahuKiri.likelihood > confidenceThreshold &&
        bahuKanan.likelihood > confidenceThreshold &&
        sikuKiri != null &&
        sikuKiri.likelihood > confidenceThreshold &&
        sikuKanan != null &&
        sikuKanan.likelihood > confidenceThreshold &&
        tanganKiri.likelihood > confidenceThreshold &&
        tanganKanan.likelihood > confidenceThreshold) {
      // Kira purata kedudukan untuk kestabilan
      final purataBahuY = (bahuKiri.y + bahuKanan.y) / 2;
      final tengahBadan = (bahuKiri.x + bahuKanan.x) / 2;

      // Ambil koordinat Z untuk check tangan di HADAPAN atau BELAKANG badan
      final purataBahuZ = (bahuKiri.z + bahuKanan.z) / 2;
      final purataTanganZ = (tanganKiri.z + tanganKanan.z) / 2;

      // Tangan mesti di HADAPAN bahu
      final bool tanganDiHadapan = purataTanganZ < purataBahuZ + 50;

      // Syarat-syarat utama untuk sedekap:

      // 1. Tangan berada di kawasan dada (antara atas bahu dan bawah siku)
      //    Kalau pinggul tak nampak, guna siku sebagai batas bawah
      final purataSikuY = (sikuKiri.y + sikuKanan.y) / 2;

      bool tanganDiKawasanDada;
      if (pinggulKiri != null &&
          pinggulKanan != null &&
          pinggulKiri.likelihood > confidenceThreshold &&
          pinggulKanan.likelihood > confidenceThreshold) {
        // Kalau pinggul nampak, guna pinggul sebagai batas bawah
        final purataPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;
        tanganDiKawasanDada =
            tanganKiri.y > purataBahuY - 100 &&
            tanganKanan.y > purataBahuY - 100 &&
            tanganKiri.y < purataPinggulY &&
            tanganKanan.y < purataPinggulY;
      } else {
        // Kalau pinggul TAK nampak, guna formula alternatif
        // Tangan mesti bawah dari bahu tapi atas dari siku
        tanganDiKawasanDada =
            tanganKiri.y > purataBahuY - 100 &&
            tanganKanan.y > purataBahuY - 100 &&
            tanganKiri.y >
                purataSikuY - 150 && // Tangan dekat dengan tahap siku
            tanganKanan.y > purataSikuY - 150;
      }

      // 2. Tangan rapat antara satu sama lain (posisi silang/lipat)
      final bool tanganBerdekatan = (tanganKanan.x - tanganKiri.x).abs() < 100;

      // 3. Tangan berada dekat dengan garisan tengah badan
      final purataTanganX = (tanganKiri.x + tanganKanan.x) / 2;
      final bool tanganDiTengah = (purataTanganX - tengahBadan).abs() < 100;

      // 4. Siku dalam posisi lipat semula jadi
      final bool sikuSemulajadi =
          sikuKiri.y > purataBahuY - 80 && sikuKanan.y > purataBahuY - 80;

      // 5. Tangan di bawah hidung (untuk pastikan bukan posisi doa/ihram)
      final bool tanganDiBawahHidung =
          tanganKiri.y > nose.y - 50 && tanganKanan.y > nose.y - 50;

      if (tanganDiKawasanDada &&
          tanganBerdekatan &&
          tanganDiTengah &&
          sikuSemulajadi &&
          tanganDiHadapan &&
          tanganDiBawahHidung) {
        return PrayerPosition.sedekap;
      }
    }
    // =====================================================
    // DETECT TAKBIRAATUL IHRAM
    // =====================================================
    //Detect Takbirautul Ihram position
    if (nose.likelihood > confidenceThreshold &&
        bahuKiri.likelihood > confidenceThreshold &&
        bahuKanan.likelihood > confidenceThreshold &&
        tanganKiri.likelihood > confidenceThreshold &&
        tanganKanan.likelihood > confidenceThreshold &&
        sikuKiri!.likelihood > confidenceThreshold &&
        sikuKanan!.likelihood > confidenceThreshold) {
      // Check if hands are raised near the shoulders
      if (tanganKiri.y < bahuKiri.y &&
          tanganKanan.y < bahuKanan.y &&
          sikuKiri.y > bahuKiri.y &&
          sikuKanan.y > bahuKanan.y) {
        return PrayerPosition.ihram; // Takbirautul Ihram
      }
    }
    // =====================================================
    // DETECT QIYAM (Standing - dengan atau tanpa tangan/siku)
    // =====================================================
    if (nose.likelihood > confidenceThreshold &&
        bahuKiri.likelihood > confidenceThreshold &&
        bahuKanan.likelihood > confidenceThreshold) {
      // Kira purata bahu
      final avgBahuY = (bahuKiri.y + bahuKanan.y) / 2;
      // final tengahBadan = (bahuKiri.x + bahuKanan.x) / 2;

      // Check tangan nampak atau tidak
      bool tanganNampak =
          tanganKiri.likelihood > confidenceThreshold &&
          tanganKanan.likelihood > confidenceThreshold;

      if (tanganNampak) {
        // ============================================
        // QIYAM DENGAN TANGAN NAMPAK
        // ============================================
        final avgTanganY = (tanganKiri.y + tanganKanan.y) / 2;

        // Tangan di bawah bahu (berdiri relaks)
        final bool handsDown = avgTanganY > avgBahuY;

        // Tangan tidak terlalu rapat (bukan sedekap)
        final bool handsApart = (tanganKanan.x - tanganKiri.x).abs() > 100;

        if (handsDown && handsApart) {
          return PrayerPosition.qiyam;
        }
      } else {
        // ============================================
        // QIYAM TANPA TANGAN NAMPAK
        // ============================================
        // Detect qiyam berdasarkan postur badan sahaja

        // 1. Badan tegak - hidung sepatutnya lebih tinggi dari bahu
        final bool badanTegak = nose.y < avgBahuY;

        // 2. Check pinggul kalau ada (untuk pastikan posisi berdiri)
        bool posisiBerdiri = true;
        if (pinggulKiri != null &&
            pinggulKanan != null &&
            pinggulKiri.likelihood > confidenceThreshold &&
            pinggulKanan.likelihood > confidenceThreshold) {
          // Pinggul sepatutnya jauh di bawah bahu untuk posisi berdiri
          final avgPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;
          posisiBerdiri = avgPinggulY > avgBahuY + 100;
        }

        // 3. Bahu seimbang (tidak condong ke kiri/kanan)
        final bool bahuSeimbang = (bahuKiri.y - bahuKanan.y).abs() < 50;

        if (badanTegak && posisiBerdiri && bahuSeimbang) {
          return PrayerPosition.qiyam;
        }
      }
    }

    // =====================================================
    // DETECT RUKU
    // =====================================================
    // Check confidence
    if (nose.likelihood < confidenceThreshold ||
        bahuKiri.likelihood < confidenceThreshold ||
        bahuKanan.likelihood < confidenceThreshold ||
        pinggulKiri!.likelihood < confidenceThreshold ||
        pinggulKanan!.likelihood < confidenceThreshold) {
      return PrayerPosition.unknown;
    }

    // Calculate averages
    final purataBahuY = (bahuKiri.y + bahuKanan.y) / 2;
    final purataPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;

    // Condition 1: Kepala di bawah bahu (membongkok)
    final bool kepalaBawahBahu = nose.y > purataBahuY + 50;

    // Condition 2: Badan bengkok (pinggul di bawah bahu tapi tak terlalu rendah)
    final bool badanBengkok =
        purataPinggulY > purataBahuY + 100 &&
        purataPinggulY < purataBahuY + 350;

    // Condition 3: Kepala tidak terlalu rendah (bukan sujud)
    final bool bukanSujud = nose.y < purataPinggulY + 150;

    // Optional: Check tangan dekat lutut (if available)
    bool tanganDekatLutut = true;
    if (lututKiri != null &&
        lututKanan != null &&
        tanganKiri.likelihood > confidenceThreshold &&
        tanganKanan.likelihood > confidenceThreshold) {
      final purataTanganY = (tanganKiri.y + tanganKanan.y) / 2;
      final purataLututY = (lututKiri.y + lututKanan.y) / 2;
      tanganDekatLutut = (purataTanganY - purataLututY).abs() < 150;
    }

    if (kepalaBawahBahu && badanBengkok && bukanSujud && tanganDekatLutut) {
      return PrayerPosition.ruku;
    }

    // =====================================================
    // DETECT SUJUD
    // =====================================================

    // Check confidence
    if (nose.likelihood < confidenceThreshold ||
        bahuKiri.likelihood < confidenceThreshold ||
        bahuKanan.likelihood < confidenceThreshold) {
      return PrayerPosition.unknown;
    }
    // calculate averages

    // Condition 1: Kepala sangat rendah (dekat lantai)
    final bool kepalaSangatRendah = nose.y > purataBahuY + 200;

    // Condition 2: Bahu juga rendah (badan sujud)
    bool bahuRendah = true;
    if (pinggulKiri.likelihood > confidenceThreshold &&
        pinggulKanan.likelihood > confidenceThreshold) {
      final purataPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;
      // Bahu hampir sama level dengan pinggul atau lebih rendah
      bahuRendah = purataBahuY > purataPinggulY - 100;
    }

    // Condition 3: Check Z-axis (kepala ke hadapan)
    bool kepalaDiHadapan = true;
    if (nose.z != 0 && bahuKiri.z != 0) {
      // Check if Z available
      final purataBahuZ = (bahuKiri.z + bahuKanan.z) / 2;
      kepalaDiHadapan = nose.z > purataBahuZ + 20;
    }

    if (kepalaSangatRendah && bahuRendah && kepalaDiHadapan) {
      return PrayerPosition.sujud;
    }

    return PrayerPosition.unknown;
  }
}

// Prayer positions enum
enum PrayerPosition {
  unknown,
  qiyam, // Standing
  ihram, // Takbirautul Ihram
  sedekap, // Tangan bersedekap di dada
  ruku, // Bowing
  sujud, // Prostration
  julus, // Sitting
}

class PosePainter extends CustomPainter {
  final Pose? pose;
  final Size previewSize;
  final CameraController camera;

  PosePainter({
    required this.pose,
    required this.previewSize,
    required this.camera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    // Confidence threshold
    const double confidenceThreshold = 0.8; //0.5
    const Color circleColor = Colors.white;
    const double circleRadius = 4.0;
    const double strokeWidth = 1.0;

    // Landmarks to draw
    final landmarks = {
      'nose': pose!.landmarks[PoseLandmarkType.nose],
      'leftEye': pose!.landmarks[PoseLandmarkType.leftEyeInner],
      'rightEye': pose!.landmarks[PoseLandmarkType.rightEyeInner],
      'leftShoulder': pose!.landmarks[PoseLandmarkType.leftShoulder],
      'rightShoulder': pose!.landmarks[PoseLandmarkType.rightShoulder],
      'leftElbow': pose!.landmarks[PoseLandmarkType.leftElbow],
      'rightElbow': pose!.landmarks[PoseLandmarkType.rightElbow],
      'leftWrist': pose!.landmarks[PoseLandmarkType.leftWrist],
      'rightWrist': pose!.landmarks[PoseLandmarkType.rightWrist],
      'leftIndex': pose!.landmarks[PoseLandmarkType.leftIndex],
      'rightIndex': pose!.landmarks[PoseLandmarkType.rightIndex],
      // 'leftPinky': pose!.landmarks[PoseLandmarkType.leftPinky],
      // 'rightPinky': pose!.landmarks[PoseLandmarkType.rightPinky],
      // 'leftThumb': pose!.landmarks[PoseLandmarkType.leftThumb],
      // 'rightThumb': pose!.landmarks[PoseLandmarkType.rightThumb],
      'leftHip': pose!.landmarks[PoseLandmarkType.leftHip],
      'rightHip': pose!.landmarks[PoseLandmarkType.rightHip],
      'leftKnee': pose!.landmarks[PoseLandmarkType.leftKnee],
      'rightKnee': pose!.landmarks[PoseLandmarkType.rightKnee],
      'leftAnkle': pose!.landmarks[PoseLandmarkType.leftAnkle],
      'rightAnkle': pose!.landmarks[PoseLandmarkType.rightAnkle],
      'leftFootIndex': pose!.landmarks[PoseLandmarkType.leftFootIndex],
      'rightFootIndex': pose!.landmarks[PoseLandmarkType.rightFootIndex],
      'leftHeel': pose!.landmarks[PoseLandmarkType.leftHeel],
      'rightHeel': pose!.landmarks[PoseLandmarkType.rightHeel],
    };

    final paint = Paint()
      ..color = circleColor
      ..style = PaintingStyle
          .stroke // Hollow circle
      ..strokeWidth = strokeWidth;

    landmarks.forEach((name, landmark) {
      if (landmark == null) return;

      // Only draw if likelihood >= threshold
      if (landmark.likelihood < confidenceThreshold) return;

      final scaleX = size.width / previewSize.height;
      final scaleY = size.height / previewSize.width;

      double x = landmark.x * scaleX;
      double y = landmark.y * scaleY;

      // Mirror X if front camera
      if (camera.description.lensDirection == CameraLensDirection.front) {
        x = size.width - x;
      }

      // Draw hollow circle
      canvas.drawCircle(Offset(x, y), circleRadius, paint);

      // debugPrint(
      //   '📍 $name (Screen coords): $x, $y, likelihood: ${landmark.likelihood}',
      // );
    });

    ///
    /// DRAW SKELETON LINES
    ///
    // Helper to get scaled Offset
    Offset? getOffset(PoseLandmark? landmark) {
      if (landmark == null || landmark.likelihood < confidenceThreshold) {
        return null;
      }
      final scaleX = size.width / previewSize.height;
      final scaleY = size.height / previewSize.width;
      double x = landmark.x * scaleX;
      double y = landmark.y * scaleY;
      if (camera.description.lensDirection == CameraLensDirection.front) {
        x = size.width - x;
      }
      return Offset(x, y);
    }

    // Draw lines between joints
    void drawLine(PoseLandmark? a, PoseLandmark? b) {
      final offsetA = getOffset(a);
      final offsetB = getOffset(b);
      if (offsetA != null && offsetB != null) {
        canvas.drawLine(offsetA, offsetB, paint);
      }
    }

    // Shoulder line
    drawLine(landmarks['leftShoulder'], landmarks['rightShoulder']);
    // Shoulder → Elbow → Wrist
    drawLine(landmarks['leftShoulder'], landmarks['leftElbow']);
    drawLine(landmarks['leftElbow'], landmarks['leftWrist']);
    drawLine(landmarks['leftElbow'], landmarks['leftIndex']);
    drawLine(landmarks['rightShoulder'], landmarks['rightElbow']);
    drawLine(landmarks['rightElbow'], landmarks['rightWrist']);
    drawLine(landmarks['rightWrist'], landmarks['rightIndex']);
    // Shoulder → Hip
    drawLine(landmarks['leftShoulder'], landmarks['leftHip']);
    drawLine(landmarks['rightShoulder'], landmarks['rightHip']);
    drawLine(landmarks['leftHip'], landmarks['rightHip']);
    drawLine(landmarks['leftHip'], landmarks['leftKnee']);
    drawLine(landmarks['rightHip'], landmarks['rightKnee']);
    // Hip → Knee → Ankle
    drawLine(landmarks['leftHip'], landmarks['leftKnee']);
    drawLine(landmarks['leftKnee'], landmarks['leftAnkle']);
    drawLine(landmarks['rightHip'], landmarks['rightKnee']);
    drawLine(landmarks['rightKnee'], landmarks['rightAnkle']);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

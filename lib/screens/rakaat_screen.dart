import 'dart:async';

import 'package:aqim/services/ads_service.dart';
import 'package:aqim/utils/loading_screen.dart';
import 'package:aqim/utils/plugin.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_brightness/screen_brightness.dart';

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
  final bool _isShowCamera = false;
  final int _cameraIndex = 1;
  List<Pose> _poses = [];
  final AdsService _adsService = AdsService();
  InterstitialAd? _interstitialAd;
  bool _isDisposed = false;

  // For displaying debug info
  String debugText = '';

  // Brightness control
  double _currentBrightness = 0.5;
  double? _originalBrightness;
  bool _isSliderVisible = false;

  // ⚙️ RAKAAT TIMING CONFIGURATION
  static const int _minTimeBeforeFirstRakaat = 5; // seconds
  static const int _minTimeBetweenRakaat2 = 68; // 75 ~1 rakaat cycle
  static const int _minTimeBetweenRakaat3 = 78; // 85 includes tahiyat awal
  static const int _minTimeBetweenRakaat4 = 40; // 40 shorter cycle

  // 🎨 ANIMATION CONFIGURATION
  late AnimationController _rakaatAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Hide status bar and navigation bar completely
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    // Also hide all overlays
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    _initializeBrightness();
    _initializeCamera();
    _initializePoseDetector();
    _initializeAnimation();
    _loadInterstitialAdForExit(); // Load ad but don't show until exit
  }

  Future<void> _initializeBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
      // Normal = 50% (0.5), Maximum = 60% (0.6)
      // Clamp to max 0.6 for slider display
      _currentBrightness = (_originalBrightness ?? 0.5).clamp(0.0, 0.6);
      // Don't change actual brightness - let user control via slider
      debugPrint(
        '💡 Original brightness: $_originalBrightness, Slider position: $_currentBrightness',
      );
    } catch (e) {
      debugPrint('❌ Error getting brightness: $e');
    }
  }

  Future<void> _resetBrightness() async {
    try {
      if (_originalBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
        if (mounted) {
          setState(() {
            _currentBrightness = _originalBrightness!;
          });
        }
        debugPrint('💡 Brightness restored to: $_originalBrightness');
      }
    } catch (e) {
      debugPrint('❌ Error resetting brightness: $e');
    }
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
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    _rakaatAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _isSwitching = true; // Prevent any new processing
    _camera?.stopImageStream();
    _camera?.dispose();
    _poseDetector.close();
    _interstitialAd?.dispose();
    _resetBrightness(); // Reset brightness before exiting
    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_camera == null || !_camera!.value.isInitialized) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _handleExit(context);
        },
        child: const Scaffold(body: Center(child: LoadingScreen())),
      );
    }
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _isShowCamera == false
                ? Container(color: Colors.black)
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
                  Row(
                    children: [
                      // Brightness toggle button
                      IconButton.filledTonal(
                        onPressed: () {
                          setState(() {
                            _isSliderVisible = !_isSliderVisible;
                          });
                        },
                        icon: Icon(
                          _isSliderVisible
                              ? Icons.brightness_medium
                              : Icons.brightness_low,
                        ),
                      ),
                      SizedBox(width: 8),
                      // Info button
                      IconButton.filledTonal(
                        onPressed: () async {
                          // Save current brightness before showing dialog
                          final savedBrightness = _currentBrightness;

                          // Temporarily set to normal brightness for dialog
                          if (_originalBrightness != null) {
                            await ScreenBrightness().setScreenBrightness(
                              _originalBrightness!,
                            );
                          }

                          if (mounted) {
                            // Show dialog
                            await caraLetakTelefon();

                            // Restore previous brightness after dialog closes
                            await ScreenBrightness().setScreenBrightness(
                              savedBrightness,
                            );

                            if (mounted) {
                              setState(() {
                                _currentBrightness = savedBrightness;
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.info_outline),
                      ),
                    ],
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
            // Brightness Slider (Vertical) - Right Side with Animation
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: _isSliderVisible ? 10 : -70,
              top: 200,
              bottom: 200,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isSliderVisible ? 1.0 : 0.0,
                child: Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    mainAxisAlignment: .center,
                    children: [
                      Icon(
                        Icons.brightness_medium,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                            ),
                            child: Slider(
                              value: _currentBrightness.clamp(0.0, 0.6),
                              min: 0.0,
                              max: 0.6,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              onChanged: (value) async {
                                setState(() {
                                  _currentBrightness = value;
                                });
                                try {
                                  // Use cubic curve for MUCH dimmer low brightness
                                  // This allows VERY low brightness levels
                                  final adjustedValue = value == 0.0
                                      ? 0.0
                                      : (value * value * value) / (0.6 * 0.6);
                                  await ScreenBrightness().setScreenBrightness(
                                    adjustedValue.clamp(0.0, 1.0),
                                  );
                                  debugPrint(
                                    '💡 Slider: $value → Brightness: $adjustedValue',
                                  );
                                } catch (e) {
                                  debugPrint('❌ Error setting brightness: $e');
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.brightness_low,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
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
                            _isCountingDown
                                ? _countdown.toString()
                                : _rakaatCount.toString(),
                            style: TextStyle(
                              color: _isCountingDown
                                  ? Colors.green.withValues(
                                      alpha: _opacityAnimation.value * 0.5,
                                    )
                                  : Colors.white.withValues(
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
                          _isCountingDown
                              ? _countdown.toString()
                              : _rakaatCount.toString(),
                          style: TextStyle(
                            color: _isCountingDown
                                ? Colors.green
                                : Colors.greenAccent,
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
                    // Text(
                    //   'Letakkan telefon di hadapan anda ketika solat\n'
                    //   'dan tekan MULA untuk mula mengira rakaat.',
                    //   textAlign: TextAlign.center,
                    //   style: TextStyle(
                    //     color: _isShowCamera
                    //         ? Colors.white.withValues(alpha: 0.6)
                    //         : cs.onSurface.withValues(alpha: 0.6),
                    //     fontSize: 14,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),
                    // SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset button (only show when tracking is active)
                        if (_isStart && _rakaatCount > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _resetRakaatCount,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Set Semula',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        if (_isStart && _rakaatCount > 0) SizedBox(width: 12.w),
                        // Start/Stop button
                        Expanded(
                          child: FilledButton(
                            onPressed: _toggleKiraRakaat,
                            style: FilledButton.styleFrom(
                              backgroundColor: (_isStart || _isCountingDown)
                                  ? Colors.red
                                  : Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              (_isStart || _isCountingDown)
                                  ? 'Berhenti'
                                  : 'Mula',
                              style: const TextStyle(color: Colors.white),
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

  /// Handle exit with ad display
  Future<void> _handleExit(BuildContext context) async {
    if (_interstitialAd != null && isShowAds) {
      debugPrint('📢 Showing rakaat exit ad');
      try {
        await _interstitialAd!.show();
        // Ad will be disposed in the callback, then we pop
      } catch (e) {
        debugPrint('❌ Error showing exit ad: $e');
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    } else {
      debugPrint('⏭️ No ad to show, exiting directly');
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
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
  bool _isCountingDown = false;
  int _countdown = 3;
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

    // Add audio feedback here if needed (e.g., play sound)
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
    if (_isStart || _isCountingDown) {
      // Stop timer and countdown
      _timer?.cancel();

      if (mounted) {
        setState(() {
          _isStart = false;
          _isCountingDown = false;
          _countdown = 3;
          _timerCounter = 0;
          _previousPosition = PrayerPosition.unknown;
          _rakaatCount = 0;
          _currentPosition = PrayerPosition.unknown;
        });
      }
    } else {
      // Start countdown 3, 2, 1
      if (mounted) {
        setState(() {
          _isCountingDown = true;
          _countdown = 3;
        });
      }

      // Countdown timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;

        if (_countdown > 1) {
          // Continue countdown
          setState(() {
            _countdown--;
          });
          // Trigger animation
          _rakaatAnimationController.forward(from: 0.0);
        } else if (_countdown == 1) {
          // Last countdown, prepare to start
          setState(() {
            _countdown = 0;
          });
          _rakaatAnimationController.forward(from: 0.0);
        } else {
          // Countdown finished, start tracking
          timer.cancel();
          if (mounted) {
            setState(() {
              _isCountingDown = false;
              _isStart = true;
              _timerCounter = 0;
            });
          }

          // Start rakaat tracking timer
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!mounted) return;
            setState(() {
              _timerCounter++;
            });
          });
        }
      });
    }
  }

  /// Load Interstitial Ad for exit (don't show immediately)
  void _loadInterstitialAdForExit() {
    if (!isShowAds) {
      debugPrint('❌ Ads disabled - skipping rakaat interstitial');
      return;
    }

    // Prevent multiple loads - dispose old ad properly
    _interstitialAd?.dispose();
    _interstitialAd = null;

    InterstitialAd.load(
      adUnitId: _adsService.rakaatInterstitial1AdString,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('✅ Rakaat exit ad loaded (ready to show on exit)');

          // Check if screen is still mounted before setting
          if (_isDisposed || !mounted) {
            ad.dispose();
            return;
          }

          _interstitialAd = ad;
          _setFullScreenContentCallback(ad);

          // Don't show the ad here - it will be shown when user exits
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ Failed to load rakaat exit ad: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _setFullScreenContentCallback(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('✅ Rakaat exit ad showed full screen content.');
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('❌ Rakaat exit ad failed to show: $err');
        ad.dispose();
        _interstitialAd = null;
        // Navigate back even if ad fails
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('✅ Rakaat exit ad was dismissed, navigating back.');
        ad.dispose();
        _interstitialAd = null;
        // Navigate back after ad is dismissed
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
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
    const double confidenceThreshold = 0.5;
    final pose = _poses.isNotEmpty ? _poses.first : Pose(landmarks: {});

    // Get all landmarks
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftEye = pose.landmarks[PoseLandmarkType.leftEye];
    final rightEye = pose.landmarks[PoseLandmarkType.rightEye];
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

    // Minimum requirement: shoulders must be visible
    if (bahuKiri == null ||
        bahuKanan == null ||
        bahuKiri.likelihood < confidenceThreshold ||
        bahuKanan.likelihood < confidenceThreshold) {
      return PrayerPosition.unknown;
    }

    final purataBahuY = (bahuKiri.y + bahuKanan.y) / 2;
    final tengahBadanX = (bahuKiri.x + bahuKanan.x) / 2;

    // =====================================================
    // 1️⃣ DETECT SUJUD (HIGHEST PRIORITY)
    // =====================================================

    // Method 1: Face completely hidden
    bool noseHidden = nose == null || nose.likelihood < 0.3;
    bool eyesHidden =
        (leftEye == null || leftEye.likelihood < 0.3) &&
        (rightEye == null || rightEye.likelihood < 0.3);

    if (noseHidden && eyesHidden) {
      debugPrint('🕌 SUJUD Method 1: Face completely hidden');
      return PrayerPosition.sujud;
    }

    // Method 2: Nose EXTREMELY low
    if (nose != null && nose.likelihood > 0.2) {
      final noseToShoulderDist = nose.y - purataBahuY;

      if (noseToShoulderDist > 250) {
        debugPrint('🕌 SUJUD Method 2: Nose extremely low');
        return PrayerPosition.sujud;
      }
    }

    // Method 3: Body compressed
    if (pinggulKiri != null &&
        pinggulKanan != null &&
        pinggulKiri.likelihood > confidenceThreshold &&
        pinggulKanan.likelihood > confidenceThreshold) {
      final purataPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;
      final bodyHeight = purataPinggulY - purataBahuY;

      if (bodyHeight < 200) {
        if (nose == null ||
            nose.likelihood < confidenceThreshold ||
            nose.y > purataBahuY + 100) {
          debugPrint('🕌 SUJUD Method 3: Body compressed');
          return PrayerPosition.sujud;
        }
      }

      // Method 4: Nose below hips
      if (nose != null && nose.likelihood > 0.2) {
        if (nose.y > purataPinggulY + 30) {
          debugPrint('🕌 SUJUD Method 4: Nose below hips');
          return PrayerPosition.sujud;
        }
      }
    }

    // Method 5: Elbows extremely low
    if (sikuKiri != null &&
        sikuKanan != null &&
        sikuKiri.likelihood > confidenceThreshold &&
        sikuKanan.likelihood > confidenceThreshold) {
      final purataSikuY = (sikuKiri.y + sikuKanan.y) / 2;
      final elbowToShoulderDist = purataSikuY - purataBahuY;

      if (elbowToShoulderDist > 300) {
        bool lowProfile = false;

        if (nose != null && nose.likelihood > 0.2) {
          lowProfile = nose.y > purataBahuY + 100;
        } else {
          lowProfile = true;
        }

        if (lowProfile) {
          debugPrint('🕌 SUJUD Method 5: Elbows very low');
          return PrayerPosition.sujud;
        }
      }
    }

    // Method 6: Wrists on ground
    if (tanganKiri != null &&
        tanganKanan != null &&
        tanganKiri.likelihood > confidenceThreshold &&
        tanganKanan.likelihood > confidenceThreshold) {
      final purataTanganY = (tanganKiri.y + tanganKanan.y) / 2;
      final wristToShoulderDist = purataTanganY - purataBahuY;

      if (wristToShoulderDist > 350) {
        bool noseLowOrHidden =
            nose == null ||
            nose.likelihood < confidenceThreshold ||
            nose.y > purataBahuY + 150;

        if (noseLowOrHidden) {
          debugPrint('🕌 SUJUD Method 6: Wrists on ground');
          return PrayerPosition.sujud;
        }
      }
    }

    // Method 7: Body folded with knees
    if (lututKiri != null &&
        lututKanan != null &&
        lututKiri.likelihood > confidenceThreshold &&
        lututKanan.likelihood > confidenceThreshold) {
      final purataLututY = (lututKiri.y + lututKanan.y) / 2;
      final kneeToShoulderDist = purataLututY - purataBahuY;

      if (kneeToShoulderDist < 300 && kneeToShoulderDist > 0) {
        bool bodyFolded = false;

        if (nose != null && nose.likelihood > 0.2) {
          bodyFolded = nose.y > purataBahuY + 150;
        } else if (pinggulKiri != null && pinggulKanan != null) {
          final purataPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;
          final bodyHeight = purataPinggulY - purataBahuY;
          bodyFolded = bodyHeight < 250;
        }

        if (bodyFolded) {
          debugPrint('🕌 SUJUD Method 7: Body folded');
          return PrayerPosition.sujud;
        }
      }
    }

    // =====================================================
    // 2️⃣ DETECT RUKU (BOWING)
    // =====================================================
    // =====================================================
    // 2️⃣ DETECT RUKU (BOWING) - ULTRA RELAXED VERSION
    // =====================================================
    if (nose != null && nose.likelihood > confidenceThreshold) {
      // PRIMARY METHOD: With hips visible
      if (pinggulKiri != null &&
          pinggulKanan != null &&
          pinggulKiri.likelihood > confidenceThreshold &&
          pinggulKanan.likelihood > confidenceThreshold) {
        final purataPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;
        final bodyHeight = purataPinggulY - purataBahuY;

        // 1. Head bowed down (RELAXED: reduced from 80 to 60)
        final noseToShoulderDist = nose.y - purataBahuY;
        final bool kepalaBawah = noseToShoulderDist > 60;

        // 2. Nose still above hips (RELAXED: reduced from 80 to 50)
        final noseToHipDist = purataPinggulY - nose.y;
        final bool kepalaDiAtasPinggul = noseToHipDist > 50;

        // 3. Body bent forward (RELAXED: reduced from 100 to 80)
        final bool badanBengkok = purataPinggulY > purataBahuY + 80;

        // 4. Body NOT compressed (RELAXED: lower bound reduced)
        final bool bodyNotCompressed = bodyHeight > 150 && bodyHeight < 600;

        // MAIN RUKUK DETECTION
        if (kepalaBawah &&
            kepalaDiAtasPinggul &&
            badanBengkok &&
            bodyNotCompressed) {
          debugPrint(
            '🙇 RUKU: NoseToShoulder=${noseToShoulderDist.toInt()}, '
            'NoseToHip=${noseToHipDist.toInt()}, '
            'BodyHeight=${bodyHeight.toInt()}',
          );
          return PrayerPosition.ruku;
        }
      }

      // SECONDARY METHOD: Using shoulders and nose only (no hips needed)
      // This catches rukuk even when hips are not clearly visible
      final noseToShoulderDist = nose.y - purataBahuY;

      // Conditions:
      // - Nose significantly below shoulders (bowing)
      // - But not too extreme (not sujud)
      if (noseToShoulderDist > 60 && noseToShoulderDist < 250) {
        // Additional check: make sure it's not sujud by checking if face is still visible
        final bool faceStillVisible =
            nose.likelihood > confidenceThreshold &&
                (leftEye != null && leftEye.likelihood > 0.3) ||
            (rightEye != null && rightEye.likelihood > 0.3);

        if (faceStillVisible) {
          debugPrint(
            '🙇 RUKU (secondary): NoseToShoulder=${noseToShoulderDist.toInt()}',
          );
          return PrayerPosition.ruku;
        }
      }

      // TERTIARY METHOD: Using elbows and wrists (when hips not visible)
      if (sikuKiri != null &&
          sikuKanan != null &&
          sikuKiri.likelihood > confidenceThreshold &&
          sikuKanan.likelihood > confidenceThreshold &&
          tanganKiri != null &&
          tanganKanan != null &&
          tanganKiri.likelihood > confidenceThreshold &&
          tanganKanan.likelihood > confidenceThreshold) {
        final purataSikuY = (sikuKiri.y + sikuKanan.y) / 2;
        final purataTanganY = (tanganKiri.y + tanganKanan.y) / 2;

        // Head bowed (RELAXED)
        final bool headBowed = nose.y > purataBahuY + 60;

        // Elbows below shoulders (RELAXED: reduced from 150 to 120)
        final bool elbowsLow = purataSikuY > purataBahuY + 120;

        // Wrists below elbows (RELAXED: reduced from 50 to 30)
        final bool wristsLow = purataTanganY > purataSikuY + 30;

        // But not too low (not sujud)
        final bool notTooLow = purataTanganY < purataBahuY + 500;

        // Face still visible
        final bool faceVisible = nose.likelihood > 0.4;

        if (headBowed && elbowsLow && wristsLow && notTooLow && faceVisible) {
          debugPrint('🙇 RUKU (tertiary): Using elbows/wrists');
          return PrayerPosition.ruku;
        }
      }

      // QUATERNARY METHOD: Simple angle check
      // Just check if nose is moderately below shoulders with stable visibility
      if (nose.y > purataBahuY + 70 && nose.y < purataBahuY + 200) {
        // Make sure shoulders are relatively level (not tilted weirdly)
        final shoulderBalance = (bahuKiri.y - bahuKanan.y).abs();

        if (shoulderBalance < 80) {
          debugPrint('🙇 RUKU (quaternary): Simple bowing detected');
          return PrayerPosition.ruku;
        }
      }
    }

    // =====================================================
    // 3️⃣ DETECT TAKBIRAATUL IHRAM (Hands raised)
    // =====================================================
    if (nose != null &&
        nose.likelihood > confidenceThreshold &&
        tanganKiri != null &&
        tanganKiri.likelihood > confidenceThreshold &&
        tanganKanan != null &&
        tanganKanan.likelihood > confidenceThreshold &&
        sikuKiri != null &&
        sikuKiri.likelihood > confidenceThreshold &&
        sikuKanan != null &&
        sikuKanan.likelihood > confidenceThreshold) {
      final purataTanganY = (tanganKiri.y + tanganKanan.y) / 2;

      final bool handsRaised = purataTanganY < purataBahuY - 30;
      final bool bodyUpright = nose.y < purataBahuY - 30;
      final bool handsNearFace = (purataTanganY - nose.y).abs() < 150;

      if (handsRaised && bodyUpright && handsNearFace) {
        debugPrint('🤲 IHRAM detected');
        return PrayerPosition.ihram;
      }
    }

    // =====================================================
    // 4️⃣ DETECT SEDEKAP (Hands folded)
    // =====================================================
    if (nose != null &&
        nose.likelihood > confidenceThreshold &&
        tanganKiri != null &&
        tanganKiri.likelihood > confidenceThreshold &&
        tanganKanan != null &&
        tanganKanan.likelihood > confidenceThreshold) {
      final purataTanganY = (tanganKiri.y + tanganKanan.y) / 2;
      final purataTanganX = (tanganKiri.x + tanganKanan.x) / 2;

      final bool bodyUpright = nose.y < purataBahuY - 20;

      bool handsInChestArea = false;
      if (pinggulKiri != null &&
          pinggulKanan != null &&
          pinggulKiri.likelihood > confidenceThreshold &&
          pinggulKanan.likelihood > confidenceThreshold) {
        final purataPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;
        handsInChestArea =
            purataTanganY > nose.y &&
            purataTanganY > purataBahuY - 50 &&
            purataTanganY < purataPinggulY - 30;
      } else {
        handsInChestArea =
            purataTanganY > nose.y &&
            purataTanganY > purataBahuY - 50 &&
            purataTanganY < purataBahuY + 350;
      }

      final bool handsTogether = (tanganKanan.x - tanganKiri.x).abs() < 180;
      final bool handsAtCenter = (purataTanganX - tengahBadanX).abs() < 150;
      final bool handsNotRaised = purataTanganY > purataBahuY - 80;

      if (bodyUpright &&
          handsInChestArea &&
          handsTogether &&
          handsAtCenter &&
          handsNotRaised) {
        debugPrint('🤲 SEDEKAP detected');
        return PrayerPosition.sedekap;
      }
    }

    // =====================================================
    // 5️⃣ DETECT QIYAM (Standing)
    // =====================================================
    if (nose != null && nose.likelihood > confidenceThreshold) {
      final bool headUp = nose.y < purataBahuY - 30;

      bool bodyVertical = true;
      if (pinggulKiri != null &&
          pinggulKanan != null &&
          pinggulKiri.likelihood > confidenceThreshold &&
          pinggulKanan.likelihood > confidenceThreshold) {
        final purataPinggulY = (pinggulKiri.y + pinggulKanan.y) / 2;
        bodyVertical = purataPinggulY > purataBahuY + 150;
      }

      final bool legsVisible =
          (lututKiri != null && lututKiri.likelihood > 0.3) ||
          (lututKanan != null && lututKanan.likelihood > 0.3);

      final bool shouldersLevel = (bahuKiri.y - bahuKanan.y).abs() < 60;

      bool handsAtSides = false;
      if (tanganKiri != null &&
          tanganKanan != null &&
          tanganKiri.likelihood > confidenceThreshold &&
          tanganKanan.likelihood > confidenceThreshold) {
        final purataTanganY = (tanganKiri.y + tanganKanan.y) / 2;
        final bool handsDown = purataTanganY > purataBahuY + 50;
        final bool handsApart = (tanganKanan.x - tanganKiri.x).abs() > 130;
        handsAtSides = handsDown && handsApart;
      } else {
        handsAtSides = true;
      }

      if (headUp &&
          bodyVertical &&
          shouldersLevel &&
          (handsAtSides || legsVisible)) {
        debugPrint('🧍 QIYAM detected');
        return PrayerPosition.qiyam;
      }
    }

    // =====================================================
    // 6️⃣ FALLBACK
    // =====================================================
    if (nose != null &&
        nose.likelihood > confidenceThreshold &&
        nose.y < purataBahuY - 20) {
      debugPrint('🧍 QIYAM (fallback)');
      return PrayerPosition.qiyam;
    }

    debugPrint('❓ UNKNOWN');
    return PrayerPosition.unknown;
  }

  // Tambah method ini dalam class _RakaatScreenState
  Future<void> caraLetakTelefon() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Stack(
              children: [
                // Gambar utama
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/cara_letak_telefon.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Close button di atas
                Positioned(
                  top: 50,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Indicator di bawah
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: .center,
                      children: [
                        // Tap to close text
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Jika anda sering terlupa bilangan rakaat, letakkan telefon di tengah sejadah seperti dalam gambar dan tekan 'Mula'. Aplikasi ini menggunakan teknologi pose detection untuk mengesan pergerakan solat dan merekod setiap rakaat secara automatik.",
                            textAlign: .center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

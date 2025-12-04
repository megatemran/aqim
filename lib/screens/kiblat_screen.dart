import 'dart:async';
import 'dart:math';
import 'package:aqim/services/ads_service.dart';
import 'package:aqim/utils/aqim_icons.dart';
import 'package:aqim/utils/loading_screen.dart';
import 'package:aqim/utils/plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/location_service.dart';

class KiblatScreen extends StatefulWidget {
  const KiblatScreen({super.key});

  @override
  State<KiblatScreen> createState() => _KiblatScreenState();
}

class _KiblatScreenState extends State<KiblatScreen> {
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  double? qiblaBearing;
  double? deviceHeading = 0;
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription<CompassEvent>? _compassSubscription;
  final AdsService _adsService = AdsService();
  InterstitialAd? _interstitialAd;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _compassSubscription?.cancel(); // ✅ Clean up compass subscription
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      // ✅ Get Qibla bearing with timeout
      final bearing = await calculateQiblaDirection().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      if (!mounted) return;

      // ✅ Listen to compass with proper error handling
      _compassSubscription = FlutterCompass.events?.listen(
        (event) {
          if (mounted && event.heading != null) {
            setState(() {
              deviceHeading = event.heading;
            });
          }
        },
        onError: (error) {
          debugPrint('❌ Compass error: $error');
        },
      );

      if (!mounted) return;

      setState(() {
        qiblaBearing = bearing;
        isLoading = false;
        errorMessage = null;
      });
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Timeout: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Masa tamat untuk mendapatkan lokasi. Sila cuba lagi.';
      });
    } catch (e) {
      debugPrint('❌ Error initializing Kiblat: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Ralat mendapatkan lokasi: ${e.toString()}';
      });
    }
  }

  Future<double> calculateQiblaDirection() async {
    // ✅ Get location with timeout
    final locationData = await LocationService().getCurrentLocation();

    // Convert degrees to radians
    double lat1 = locationData.latitude * pi / 180;
    double lon1 = locationData.longitude * pi / 180;
    double lat2 = kaabaLatitude * pi / 180;
    double lon2 = kaabaLongitude * pi / 180;

    // Calculate bearing using formula
    double dLon = lon2 - lon1;

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double bearing = atan2(y, x);

    // Convert from radians to degrees
    bearing = bearing * 180 / pi;

    // Normalize to 0-360
    bearing = (bearing + 360) % 360;

    debugPrint('Qibla Bearing: ${bearing.toStringAsFixed(2)}°');
    return bearing;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ Show error state
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kiblat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: cs.error),
                const SizedBox(height: 16),
                Text('Ralat', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                    });
                    _initialize();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Cuba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ Show loading state
    if (isLoading || qiblaBearing == null || deviceHeading == null) {
      return LoadingScreen();
    }

    // Calculate rotation for compass dial (opposite direction of device heading)
    double compassRotation = -deviceHeading! * pi / 180;

    return Scaffold(
      appBar: AppBar(title: const Text('Kiblat')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Aqim.kaaba_01, size: 20),
            const SizedBox(height: 10),

            // Compass Container
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating Compass circle background (N, E, S, W rotate)
                  Transform.rotate(
                    angle: compassRotation,
                    child: CustomPaint(
                      size: const Size(300, 300),
                      painter: CompassPainter(),
                    ),
                  ),

                  // Bearing line pointing to Qibla
                  CustomPaint(
                    size: const Size(300, 300),
                    painter: BearingLinePainter(
                      bearing: qiblaBearing!,
                      heading: deviceHeading!,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Show bearing info
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            //   decoration: BoxDecoration(
            //     color: cs.surfaceContainerHighest,
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Column(
            //     children: [
            //       Text(
            //         'Arah Kiblat',
            //         style: TextStyle(
            //           fontSize: 12,
            //           color: cs.onSurface.withValues(alpha: 0.7),
            //         ),
            //       ),
            //       const SizedBox(height: 4),
            //       Text(
            //         '${qiblaBearing!.toStringAsFixed(1)}°',
            //         style: TextStyle(
            //           fontSize: 24,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.green,
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

  /// Load Interstitial Ad on screen opening
  void _loadInterstitialAd() {
    if (!isShowAds) {
      debugPrint('❌ Ads disabled - skipping kiblat interstitial');
      return;
    }

    // Prevent multiple loads - dispose old ad properly
    _interstitialAd?.dispose();
    _interstitialAd = null;

    InterstitialAd.load(
      adUnitId: _adsService.kiblatInterstitial1AdString,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('✅ Kiblat interstitial ad loaded');

          // Check if screen is still mounted before setting
          if (_isDisposed || !mounted) {
            ad.dispose();
            return;
          }

          _interstitialAd = ad;
          _setFullScreenContentCallback(ad);

          // Show the ad immediately after setup
          ad.show().catchError((error) {
            debugPrint('❌ Failed to show kiblat ad: $error');
            ad.dispose();
            _interstitialAd = null;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ Failed to load kiblat interstitial ad: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _setFullScreenContentCallback(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('✅ Kiblat ad showed full screen content.');
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('❌ Kiblat ad failed to show: $err');
        ad.dispose();
        _interstitialAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('✅ Kiblat ad was dismissed.');
        ad.dispose();
        _interstitialAd = null;
      },
    );
  }
}

class BearingLinePainter extends CustomPainter {
  final double bearing;
  final double heading;

  BearingLinePainter({required this.bearing, required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Calculate the angle for the line (bearing relative to device heading)
    final angle = (bearing - heading) * pi / 180;

    // End point of the line (at the edge of compass)
    final endX = center.dx + (radius - 40) * sin(angle);
    final endY = center.dy - (radius - 40) * cos(angle);
    final endPoint = Offset(endX, endY);

    // Draw line from center to bearing
    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, endPoint, linePaint);

    // Draw arrow head at the end
    final arrowSize = 15.0;
    final arrowPath = Path();

    // Arrow tip is at endPoint
    arrowPath.moveTo(endPoint.dx, endPoint.dy);

    // Left wing of arrow
    final leftWingX = endPoint.dx - arrowSize * sin(angle + pi / 6);
    final leftWingY = endPoint.dy + arrowSize * cos(angle + pi / 6);
    arrowPath.lineTo(leftWingX, leftWingY);

    // Right wing of arrow
    final rightWingX = endPoint.dx - arrowSize * sin(angle - pi / 6);
    final rightWingY = endPoint.dy + arrowSize * cos(angle - pi / 6);
    arrowPath.lineTo(rightWingX, rightWingY);

    arrowPath.close();

    final arrowPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);

    // Optional: Draw a circle at center
    final centerDotPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 5, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Needle line paint
    final needlePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw red needle (pointing up)
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - size.height * 0.35), // 35% up
      needlePaint,
    );

    // Optional: Draw white/gray needle (pointing down)
    final backNeedlePaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(center.dx, center.dy + size.height * 0.35), // 35% down
      backNeedlePaint,
    );

    // Center dot
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 6, centerDotPaint);

    // Center dot border
    final centerBorderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 6, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for compass circle
class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle
    final outerPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 10, outerPaint);

    // Draw cardinal directions (U=Utara, T=Timur, S=Selatan, B=Barat)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final directions = ['U', 'T', 'S', 'B'];
    final angles = [0, 90, 180, 270];

    for (int i = 0; i < directions.length; i++) {
      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: i == 0 ? Colors.red : Colors.black,
        ),
      );
      textPainter.layout();

      final angle = angles[i] * pi / 180;
      final x = center.dx + (radius - 35) * sin(angle) - textPainter.width / 2;
      final y = center.dy - (radius - 35) * cos(angle) - textPainter.height / 2;

      textPainter.paint(canvas, Offset(x, y));
    }

    // Draw tick marks
    for (int i = 0; i < 360; i += 10) {
      final angle = i * pi / 180;
      final isMainTick = i % 30 == 0;
      final tickLength = isMainTick ? 15.0 : 8.0;
      final tickWidth = isMainTick ? 2.0 : 1.0;

      final start = Offset(
        center.dx + (radius - 10) * sin(angle),
        center.dy - (radius - 10) * cos(angle),
      );
      final end = Offset(
        center.dx + (radius - 10 - tickLength) * sin(angle),
        center.dy - (radius - 10 - tickLength) * cos(angle),
      );

      final tickPaint = Paint()
        ..color = Colors.grey[400]!
        ..strokeWidth = tickWidth;
      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

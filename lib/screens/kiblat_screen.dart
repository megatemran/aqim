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

class _KiblatScreenState extends State<KiblatScreen>
    with SingleTickerProviderStateMixin {
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;
  late final AnimationController _controller;
  double? qiblaBearing;
  double? deviceHeading = 0;
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription<CompassEvent>? _compassSubscription;
  final AdsService _adsService = AdsService();
  InterstitialAd? _interstitialAd;
  bool _isDisposed = false;

  // Compass calibration
  bool _showCalibration = false;
  int _unreliableCount = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // 🔁 Repeat forever
    _initialize();
    _loadInterstitialAdForExit();
  }

  @override
  void dispose() {
    _controller.dispose();
    _isDisposed = true;
    _compassSubscription?.cancel();
    _debounceTimer?.cancel();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final bearing = await calculateQiblaDirection().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Location request timed out'),
      );

      if (!mounted) return;

      _compassSubscription = FlutterCompass.events?.listen((event) {
        if (!mounted) return;

        deviceHeading = event.heading;

        // Trigger calibration jika heading null atau accuracy null
        if (event.heading == null || event.accuracy == null) {
          _unreliableCount++;
          if (_unreliableCount >= 3 && !_showCalibration) {
            setState(() {
              _showCalibration = true;
            });
          }
        } else {
          // accuracy ok → reset
          _unreliableCount = 0;
          if (_showCalibration) {
            setState(() {
              _showCalibration = false;
            });
          }
        }
        setState(() {}); // update compass
      });

      if (!mounted) return;
      setState(() {
        qiblaBearing = bearing;
        isLoading = false;
        errorMessage = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Masa tamat untuk mendapatkan lokasi. Sila cuba lagi.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Ralat mendapatkan lokasi: ${e.toString()}';
      });
    }
  }

  Future<double> calculateQiblaDirection() async {
    final locationData = await LocationService().getCurrentLocation();
    double lat1 = locationData.latitude * pi / 180;
    double lon1 = locationData.longitude * pi / 180;
    double lat2 = kaabaLatitude * pi / 180;
    double lon2 = kaabaLongitude * pi / 180;

    double dLon = lon2 - lon1;
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (errorMessage != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _handleExit(context);
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Kiblat')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: cs.error),
                  const SizedBox(height: 16),
                  Text(
                    'Ralat',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
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
        ),
      );
    }

    if (isLoading || qiblaBearing == null || deviceHeading == null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _handleExit(context);
        },
        child: LoadingScreen(),
      );
    }

    double compassRotation = -deviceHeading! * pi / 180;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Kiblat')),
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Aqim.kaaba_01, size: 20),
                  const SizedBox(height: 10),
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
                        Transform.rotate(
                          angle: compassRotation,
                          child: CustomPaint(
                            size: const Size(300, 300),
                            painter: CompassPainter(),
                          ),
                        ),
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
                ],
              ),
            ),
            // Calibration overlay
            if (_showCalibration)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _showCalibration ? 1.0 : 0.0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final t = _controller.value * 2 * pi;
                              final dx = sin(t) * 30;
                              final dy = sin(t * 2) * 15;
                              final rot = sin(t) * 0.3;

                              return Transform.translate(
                                offset: Offset(dx, dy),
                                child: Transform.rotate(
                                  angle: rot,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primaryContainer,
                              ),
                              child: Icon(
                                Icons.phone_android,
                                size: 80,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),

                          const SizedBox(height: 35),
                          Text(
                            'Kompas anda tidak tepat',
                            textAlign: .center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Jauhkan dari Magnet ataupun apa-apa alat yang boleh menggangu kompas anda serta gerakkan telefon anda dalam bentuk angka 8 (∞) sehingga kompas menjadi stabil.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    cs.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Text(
                              //   'Menunggu kalibrasi...',
                              //   style: TextStyle(
                              //     color: Colors.white.withValues(alpha: 0.7),
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          // OutlinedButton.icon(
                          //   onPressed: () {
                          //     setState(() {
                          //       _showCalibration = false;
                          //     });
                          //   },
                          //   icon: const Icon(Icons.close),
                          //   label: const Text('Tutup'),
                          //   style: OutlinedButton.styleFrom(
                          //     foregroundColor: Colors.white,
                          //     side: const BorderSide(color: Colors.white),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExit(BuildContext context) async {
    if (_interstitialAd != null && isShowAds) {
      try {
        await _interstitialAd!.show();
      } catch (_) {
        if (context.mounted) Navigator.of(context).pop();
      }
    } else {
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  void _loadInterstitialAdForExit() {
    if (!isShowAds) return;
    _interstitialAd?.dispose();
    _interstitialAd = null;

    InterstitialAd.load(
      adUnitId: _adsService.kiblatInterstitial1AdString,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_isDisposed || !mounted) {
            ad.dispose();
            return;
          }
          _interstitialAd = ad;
          _setFullScreenContentCallback(ad);
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _setFullScreenContentCallback(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        if (mounted) Navigator.of(context).pop();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        if (mounted) Navigator.of(context).pop();
      },
    );
  }
}

// ==== Painters ====

class BearingLinePainter extends CustomPainter {
  final double bearing;
  final double heading;
  BearingLinePainter({required this.bearing, required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final angle = (bearing - heading) * pi / 180;

    final endX = center.dx + (radius - 40) * sin(angle);
    final endY = center.dy - (radius - 40) * cos(angle);
    final endPoint = Offset(endX, endY);

    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, endPoint, linePaint);

    final arrowSize = 15.0;
    final arrowPath = Path()
      ..moveTo(endPoint.dx, endPoint.dy)
      ..lineTo(
        endPoint.dx - arrowSize * sin(angle + pi / 6),
        endPoint.dy + arrowSize * cos(angle + pi / 6),
      )
      ..lineTo(
        endPoint.dx - arrowSize * sin(angle - pi / 6),
        endPoint.dy + arrowSize * cos(angle - pi / 6),
      )
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = Colors.green);
    canvas.drawCircle(center, 5, Paint()..color = Colors.green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final outerPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 10, outerPaint);

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
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.grey[400]!
          ..strokeWidth = tickWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

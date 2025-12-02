// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ui' as ui;
import 'package:aqim/services/ads_service.dart';
import 'package:aqim/services/global_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';

import '../utils/plugin.dart';

class AzanFullScreen extends StatefulWidget {
  const AzanFullScreen({
    super.key,
    required this.prayerName,
    required this.prayerTime,
    this.onDismiss,
    required this.onThemeChange,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentThemeMode,
    required this.currentLanguage,
  });
  final String prayerName;
  final String prayerTime;
  final VoidCallback? onDismiss;
  final Function(ThemeMode) onThemeChange;
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final ThemeMode currentThemeMode;
  final String currentLanguage;

  @override
  State<AzanFullScreen> createState() => _AzanFullScreenState();
}

class _AzanFullScreenState extends State<AzanFullScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Timer _clockTimer;
  String _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
  bool _isStopping = false;
  String _azanFile = 'azan_munif_hijjaz.mp3'; // Default
  final GlobalService _globalService = GlobalService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _shouldPlaySound = false;
  bool _shouldVibrate = false;
  bool _shouldUseLed = false;
  final adsService = AdsService();
  BannerAd? _banner01;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAzan();
    _loadPrayerSettings();
    _setupUI();
    _setupAnimations();
    _startClock();
    _setupAudioPlayer();

    // Play sound if enabled
    if (_shouldPlaySound) {
      _playAzan();
    }

    // Vibrate if enabled
    if (_shouldVibrate) {
      _triggerVibration();
    }

    debugPrint('✅ AzanFullScreen initialized');
    debugPrint('🔔 Prayer: ${widget.prayerName}');
    debugPrint('🎵 Should play: $_shouldPlaySound');
    debugPrint('📳 Should vibrate: $_shouldVibrate');
    debugPrint('💡 Should LED: $_shouldUseLed');
  }

  Future<void> _loadBannerAzan() async {
    try {
      await adsService.initGoogleMobileAds();

      // DON'T assign the return value immediately
      adsService.loadBannerAzan1(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _banner01 = ad as BannerAd;
              _isBannerLoaded = true;
            });
            debugPrint('✅ Banner ad loaded successfully');
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('❌ Failed to load banner ad: ${err.message}');
          if (mounted) {
            setState(() {
              _banner01 = null;
              _isBannerLoaded = false;
            });
          }
          ad.dispose();
        },
      );
    } catch (e) {
      debugPrint('❌ Error in loadBannerAzan: $e');
      if (mounted) {
        setState(() {
          _banner01 = null;
          _isBannerLoaded = false;
        });
      }
    }
  }

  /// Load prayer-specific settings based on prayer name
  void _loadPrayerSettings() {
    final prayerKey = widget.prayerName.toLowerCase();

    // Get settings for this specific prayer
    switch (prayerKey) {
      case 'subuh':
        _shouldPlaySound = _globalService.subuhEnabled;
        _azanFile = _globalService.subuhSound;
        _shouldVibrate = _globalService.subuhVibrate;
        _shouldUseLed = _globalService.subuhLed;
        break;
      case 'zohor':
        _shouldPlaySound = _globalService.zohorEnabled;
        _azanFile = _globalService.zohorSound;
        _shouldVibrate = _globalService.zohorVibrate;
        _shouldUseLed = _globalService.zohorLed;
        break;
      case 'asar':
        _shouldPlaySound = _globalService.asarEnabled;
        _azanFile = _globalService.asarSound;
        _shouldVibrate = _globalService.asarVibrate;
        _shouldUseLed = _globalService.asarLed;
        break;
      case 'maghrib':
        _shouldPlaySound = _globalService.maghribEnabled;
        _azanFile = _globalService.maghribSound;
        _shouldVibrate = _globalService.maghribVibrate;
        _shouldUseLed = _globalService.maghribLed;
        break;
      case 'isyak':
        _shouldPlaySound = _globalService.isyakEnabled;
        _azanFile = _globalService.isyakSound;
        _shouldVibrate = _globalService.isyakVibrate;
        _shouldUseLed = _globalService.isyakLed;
        break;
      default:
        _shouldPlaySound = false;
        _azanFile = 'azan_munif_hijjaz.mp3';
        _shouldVibrate = false;
        _shouldUseLed = false;
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  Future<void> _playAzan() async {
    try {
      if (!_shouldPlaySound) {
        debugPrint('⏸️ Sound disabled for ${widget.prayerName}');
        return;
      }

      setState(() => _isPlaying = true);

      // Ensure .mp3 extension
      String soundFile = _azanFile;
      if (!soundFile.endsWith('.mp3')) {
        soundFile = '$soundFile.mp3';
      }

      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
      debugPrint('🔊 Playing azan: $soundFile for ${widget.prayerName}');
    } catch (e) {
      debugPrint('❌ Error playing azan: $e');
    }
  }

  Future<void> _triggerVibration() async {
    try {
      if (!_shouldVibrate) return;

      // Check if device has vibration capability
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Vibrate with pattern: [wait, vibrate, wait, vibrate, ...]
        Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500],
          intensities: [0, 128, 0, 255, 0, 128],
        );
        debugPrint('📳 Vibration triggered');
      }
    } catch (e) {
      debugPrint('❌ Error triggering vibration: $e');
    }
  }

  void _setupUI() {
    // Lock to portrait mode
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // ✅ Use edge-to-edge with manual control of overlays
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // ✅ Make system bars transparent so content flows behind them
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  // ✅ Toggle play/pause
  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        debugPrint('⏸️ Audio paused');
      } else {
        await _audioPlayer.resume();
        debugPrint('▶️ Audio resumed');
      }
    } catch (e) {
      debugPrint('❌ Error toggling play/pause: $e');
    }
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isStopping) {
        setState(() {
          _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
        });
      }
    });
  }

  // ✅ Stop alarm and close fullscreen
  Future<void> _stopAlarm() async {
    if (_isStopping) return;

    _isStopping = true;
    _clockTimer.cancel();

    try {
      debugPrint('⏹️ Stopping audio and closing fullscreen');
      await _audioPlayer.stop();

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      debugPrint('✅ Fullscreen closed');
    } catch (e) {
      debugPrint('❌ Error stopping alarm: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _animationController.dispose();
    _audioPlayer.dispose();

    // ✅ Dispose banner ad
    _banner01?.dispose();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    debugPrint('🧹 AzanFullScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _stopAlarm,
      onLongPress: _stopAlarm,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.teal.shade900,
                Colors.teal.shade700,
                Colors.teal.shade500,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🕌 Animated Mosque Icon
                SizedBox(height: 15),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: const Icon(
                    Icons.mosque,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // 🕋 Prayer Name
                Text(
                  'Solat ${widget.prayerName}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                Text(
                  widget.prayerTime,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),

                Text(
                  _currentTime,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                // 🕒 Live Updating Current Time
                Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    // vertical: 12,
                  ),
                  child: Text(
                    'وَٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ ۚ وَإِنَّهَا لَكَبِيرَةٌ إِلَّا عَلَى ٱلْخَـٰشِعِينَ',
                    textAlign: TextAlign.center,
                    textDirection: ui.TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lateef',
                      color: Colors.white,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    // vertical: 12,
                  ),
                  child: Text(
                    textAlign: .center,
                    'Dan mintalah pertolongan (kepada Allah) dengan jalan sabar dan mengerjakan sembahyang; dan sesungguhnya sembahyang itu amatlah berat kecuali kepada orang-orang yang khusyuk, Al-Baqarah:45',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
                ),

                // ⏰ Prayer Time Info
                const Spacer(),

                // 🎵 Audio Player Card (only show if sound is enabled)
                if (_shouldPlaySound)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Track Info
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sedang Dimainkan',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getAzanDisplayName(_azanFile),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Progress Bar
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _totalDuration.inSeconds > 0
                                    ? _currentPosition.inSeconds /
                                          _totalDuration.inSeconds
                                    : 0,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_currentPosition),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  _formatDuration(_totalDuration),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Player Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: IconButton(
                                onPressed: _togglePlayPause,
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 32,
                                ),
                                color: const Color(0xFF006B5B),
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  // Show message if sound is disabled
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Notifikasi Dimatikan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Azan tidak dimainkan kerana notifikasi dimatikan dalam tetapan',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    // horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    'Tekan lama atau double tap di skrin untuk tutup',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // 📱 Banner Ad (Bottom Bar)
                if (_isBannerLoaded && _banner01 != null && isShowAds)
                  Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: _banner01!.size.width.toDouble(),
                        height: _banner01!.size.height.toDouble(),
                        child: AdWidget(ad: _banner01!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAzanDisplayName(String azanFile) {
    // Remove .mp3 extension if present
    final cleanFile = azanFile.replaceAll('.mp3', '');

    if (cleanFile.contains('munif_hijjaz') ||
        cleanFile == 'azan_munif_hijjaz') {
      return 'Azan Munif Hijjaz';
    }
    if (cleanFile.contains('maghrib_tv3') ||
        cleanFile == 'azan_maghrib_tv3_2018') {
      return 'Azan Maghrib TV3 2018';
    }
    return 'Azan Default';
  }
}

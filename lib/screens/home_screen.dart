import 'dart:async';
import 'dart:ui' as ui;

import 'package:aqim/main.dart';
import 'package:aqim/screens/kiblat_screen.dart';
import 'package:aqim/screens/rakaat_screen.dart';
import 'package:aqim/screens/settings_screen2.dart';
import 'package:aqim/services/doa_service.dart';
import 'package:aqim/services/home_widget_service.dart';
import 'package:aqim/services/prayer_alarm_service.dart';
import 'package:aqim/services/prayer_times_service.dart';
import 'package:aqim/utils/plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_time_model.dart';
import '../services/ads_service.dart';
import '../services/location_service.dart';
import '../utils/aqim_icons.dart';
import '../utils/home_button.dart';
import '../utils/icon_app_square.dart';
import '../utils/loading_screen.dart';
import '../utils/qr_derma_dialog.dart';
import 'doa_screen.dart';
import 'prayer_times_screen.dart';
import 'widgets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onThemeChange,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentThemeMode,
    required this.currentLanguage,
  });
  final Function(ThemeMode) onThemeChange;
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final ThemeMode currentThemeMode;
  final String currentLanguage;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final adsService = AdsService();
  final prayerTimeService = PrayerTimesService();
  final doaService = DoaService();
  final loc = LocationService();
  final homewidget = HomeWidgetService();
  bool _isLoading = true;
  //bool _permissionsGranted = false;
  List<dynamic>? _doaData = [];
  Map<String, dynamic>? _randomDoa;
  late AnimationController _animationController;
  Timer? _countdownTimer;
  String? _errorMessage;
  String? _nextPrayerName;
  String? _nextPrayerTime;
  Duration? _nextPrayerTimeLeft;
  BannerAd? _bannerHome;
  bool _isBannerHomeLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    // ✅ Load banner FIRST (uses preloaded banner for instant display)
    _loadBannerHome();

    // Then initialize screen data
    _initializeHomeScreenFast();
  }

  int _bannerLoadAttempts = 0;
  static const int _maxBannerLoadAttempts = 3;

  void _loadBannerHome() {
    if (!isShowAds) {
      debugPrint('❌ Ads disabled - skipping home banner');
      return;
    }
    AdsService().loadBannerHome1(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _bannerHome = ad as BannerAd;
            _isBannerHomeLoaded = true;
            _bannerLoadAttempts = 0; // Reset on success
          });
          debugPrint('✅ Home banner ad loaded successfully');
        }
      },
      onAdFailedToLoad: (ad, err) {
        debugPrint('❌ Failed to load home banner ad: ${err.message}');
        if (mounted) {
          setState(() {
            _bannerHome = null;
            _isBannerHomeLoaded = false;
          });
        }
        ad.dispose();

        // Retry logic for "No fill" errors
        if (_bannerLoadAttempts < _maxBannerLoadAttempts && err.code == 3) {
          _bannerLoadAttempts++;
          debugPrint(
            '🔄 Retrying banner load (attempt $_bannerLoadAttempts/$_maxBannerLoadAttempts)',
          );
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) _loadBannerHome();
          });
        }
      },
    );
  }

  Future<void> _initializeHomeScreenFast() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 🔒 Lock orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      final locationData = await globalService.getLocationData();
      // ✅ Run parallel tasks
      final results = await Future.wait([
        prayerTimeService.getPrayerTimesData(locationData),
        DoaService.fetchDuas(),
      ], eagerError: false);

      final prayerData = results[0] as PrayerTimeData;
      final doaData = results[1] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        prayerTimeData = prayerData;
        _doaData = doaData;
      });

      await _setupNextPrayer();
      // await noti.initSetupNotification();

      // ✅ Check exact alarm permission after setup (critical for precise prayer times)
      _checkExactAlarmPermission();

      // ✅ Update widget in background WITHOUT blocking UI
      _updateWidgetInBackground();

      // ✅ Check battery optimization (non-blocking)
      _checkBatteryOptimization();

      debugPrint('✅ All initialization complete!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateWidgetInBackground() {
    HomeWidgetService()
        .updateWidget()
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⏱️ Widget update timeout - continuing anyway');
          },
        )
        .then((_) async {
          // ✅ Schedule prayer alarms after widget update completes
          debugPrint('📅 Scheduling prayer alarms...');
          final success = await PrayerAlarmService.scheduleAllPrayerAlarms();
          debugPrint(
            success
                ? '✅ Prayer alarms scheduled successfully'
                : '❌ Failed to schedule prayer alarms',
          );
        })
        .catchError((e) {
          debugPrint('❌ Widget update error: $e');
        });
  }

  /// Check battery optimization and prompt user if needed
  Future<void> _checkBatteryOptimization() async {
    try {
      // Wait a bit to not overwhelm user on first launch
      await Future.delayed(const Duration(seconds: 2));

      // final isDisabled =
      //     await PrayerAlarmService.isBatteryOptimizationDisabled();
      final status = await Permission.ignoreBatteryOptimizations.status;

      if (!status.isGranted && mounted) {
        // _showBatteryOptimizationDialog();

        await Permission.ignoreBatteryOptimizations.isGranted;
      } else {
        // Permission dah diberi
        debugPrint('✅ Battery optimization already disabled');
      }
    } catch (e) {
      debugPrint('❌ Error checking battery optimization: $e');
    }
  }

  // void _showBatteryOptimizationDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Izinkan Penggera Waktu Solat'),
  //         content: const Text(
  //           'Untuk memastikan penggera waktu solat berfungsi dengan baik walaupun dalam keadaan bateri rendah atau aplikasi tidak digunakan, sila benarkan aplikasi ini untuk mengabaikan pengoptimuman bateri.\n\n'
  //           'Ini penting untuk memastikan anda tidak terlepas waktu solat.',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Nanti'),
  //           ),
  //           FilledButton(
  //             onPressed: () async {
  //               Navigator.of(context).pop();
  //               await PrayerAlarmService.requestDisableBatteryOptimization();
  //             },
  //             child: const Text('Benarkan'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  /// Check and request exact alarm permission if needed (Android 12+)
  /// This is ONLY shown if user skipped permission intro screen or permission was revoked
  Future<void> _checkExactAlarmPermission() async {
    try {
      // Wait a bit for UI to settle before showing dialog
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // ✅ Only show if permission intro was completed (not first launch)
      // This avoids duplicate permission request
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('prefIsFirstLaunch') ?? true;

      if (isFirstLaunch) {
        // User is still in onboarding flow - don't show dialog
        debugPrint('⏭️ Skipping exact alarm dialog - user in onboarding');
        return;
      }

      // Show permission dialog if needed (for existing users or revoked permissions)
    } catch (e) {
      debugPrint('❌ Error checking exact alarm permission: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bannerHome?.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    if (_isLoading) {
      return LoadingScreen();
    } else if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: cs.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to Initialize App',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _initializeHomeScreenFast,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_randomDoa == null && _doaData != null && _doaData!.isNotEmpty) {
      // ✅ Load random doa AFTER UI renders
      Future.microtask(() async {
        _randomDoa = await DoaService.getRandomDoa(_doaData);
        if (mounted) setState(() {});
      });
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerHigh,
        title: Row(
          children: [
            IconAppSquare(size: 15),
            SizedBox(width: 8.w),
            Text(
              'Aqim - Aqimusollah - Dirikanlah solat',
              style: TextStyle(color: cs.onSurface, fontSize: 14.sp),
            ),
          ],
        ),
        actions: [
          IconButton(
            // style: IconButton.styleFrom(
            //   backgroundColor: cs.primary,
            //   foregroundColor: cs.onPrimary,
            // ),
            icon: Icon(Icons.settings_outlined, size: 20.sp),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      SettingsScreen2(
                        onThemeToggle: widget.onThemeToggle,
                        onLanguageChange: widget.onLanguageChange,
                        currentThemeMode: widget.currentThemeMode,
                        currentLanguage: widget.currentLanguage,
                        onThemeChange: widget.onThemeChange,
                      ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            tooltip: 'Setting',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // ✅ Align to start
          mainAxisAlignment: MainAxisAlignment.start, // ✅ Start from top
          children: [
            Container(
              width: double.infinity,
              // height: 100.h,
              padding: EdgeInsets.only(bottom: 20.h, left: 20.w),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25.r),
                  bottomRight: Radius.circular(25.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.3),
                    blurRadius: 22,
                    offset: const Offset(1, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  Text(
                    'Assalamualaikum',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.9),
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    // ✅ Works on ALL devices, shows English dates
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Text(
                  //   DateFormat(
                  //     'EEEE, d MMMM yyyy',
                  //     'ms_MY',
                  //   ).format(DateTime.now()),
                  //   style: TextStyle(
                  //     color: cs.onSurface,
                  //     fontSize: 16.sp,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: cs.onSurface, size: 14.sp),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          '${prayerTimeData?.userLocationData['locality']}, ${prayerTimeData?.userLocationData['administrativeArea']},  ',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.9),
                            fontSize: 12.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            //MIDDLE
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.w, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrayerTimeCard(isDark, cs),
                  SizedBox(height: 16.h),
                  // 📱 Banner Ad (centered)
                  if (_isBannerHomeLoaded && _bannerHome != null && isShowAds)
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 16.h),
                      child: Center(
                        child: SizedBox(
                          width: _bannerHome!.size.width.toDouble(),
                          height: _bannerHome!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerHome!),
                        ),
                      ),
                    ),
                  // FilledButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => SettingsScreen2(
                  //           onThemeToggle: widget.onThemeToggle,
                  //           onLanguageChange: widget.onLanguageChange,
                  //           currentThemeMode: widget.currentThemeMode,
                  //           currentLanguage: widget.currentLanguage,
                  //           onThemeChange: widget.onThemeChange,
                  //         ),
                  //       ),
                  //     );
                  //   },
                  //   child: const Text('Settins Screen 2'),
                  // ),
                  // FilledButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const PrayerAlarmDebugScreen(),
                  //       ),
                  //     );
                  //   },
                  //   child: const Text('Prayer Alarm Debug Screen'),
                  // ),
                  // FilledButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => AzanFullScreen(
                  //           prayerName: 'asar',
                  //           prayerTime: '16:30',
                  //           onThemeChange: widget.onThemeChange,
                  //           onThemeToggle: widget.onThemeToggle,
                  //           onLanguageChange: widget.onLanguageChange,
                  //           currentThemeMode: widget.currentThemeMode,
                  //           currentLanguage: widget.currentLanguage,
                  //         ),
                  //       ),
                  //     );
                  //   },
                  //   child: const Text('Test fullscreen azan'),
                  // ),
                  // FilledButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => RakaatScreen()),
                  //     );
                  //   },
                  //   child: Text('Rakaat Screen'),
                  // ),
                  // FilledButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => RakaatScreen2(),
                  //       ),
                  //     );
                  //   },
                  //   child: Text('Rakaat Screen 2'),
                  // ),
                  // SizedBox(height: 16.h),
                  _buildQuickActions(isDark, cs),
                  SizedBox(height: 16.h),
                  _buildDailyDuaCard(isDark, cs),
                  // SizedBox(height: 16.h),
                  // _buildDailyHadithCard(isDark, cs),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyDuaCard(bool isDark, ColorScheme cs) {
    if (_randomDoa == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Doa Harian',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 20.sp),
              onPressed: () async => await _onRefreshDoa(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoaScreen(
                  onThemeToggle: widget.onThemeToggle,
                  doaData: _doaData!,
                ),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(3, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: cs.onSurface,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        _randomDoa!['title']['ms'],
                        maxLines: 4,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _randomDoa!['arabic'],
                    // textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 34.sp,
                      height: 1.6,
                      // fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      fontFamily: 'Lateef',
                    ),

                    // textAlign: TextAlign.right,
                    textDirection: ui.TextDirection.rtl,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  _randomDoa!['transliteration'],

                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  _randomDoa!['translation']['ms'],
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.6,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _randomDoa!['source'],
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerTimeCard(bool isDark, ColorScheme cs) {
    return Card(
      elevation: 8,
      shadowColor: cs.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (BuildContext context, Widget? child) {
          final opacityRange = isDark ? 0.5 : 0.3;
          final baseOpacity = isDark ? 0.5 : 0.7;
          return Opacity(
            opacity: baseOpacity + (opacityRange * _animationController.value),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg1.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.2),
                    BlendMode.darken,
                  ),
                ),
                color: cs.primary,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.3),
                    blurRadius: 22,
                    offset: const Offset(1, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // 🔹 Header section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solat Seterusnya',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _nextPrayerName ?? 'empty',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _nextPrayerTime ?? '--:--',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_nextPrayerTimeLeft != null)
                            Text(
                              _formatTimeLeft(_nextPrayerTimeLeft!),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(radius),
                          shape: BoxShape.rectangle,
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: cs.onSurface,
                          size: 30.sp,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // 🔹 Footer button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.tertiaryContainer,
                        foregroundColor: cs.onTertiaryContainer,
                        //padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    PrayerTimesScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Semua Waktu Solat',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Icons.arrow_forward, size: 18.sp),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============ BUILD QUICK ACTIONS ============
  Widget _buildQuickActions(bool isDark, ColorScheme cs) {
    // final screenWidth = MediaQuery.of(context).size.width;
    final actions = [
      {
        'icon': Aqim.sujood,
        'label': 'Solat',
        'route': 'solat',
        'color': Color(0xFF2A8F7F),
      },
      {
        'icon': Aqim.dua,
        'label': 'Doa',
        'route': 'dua',
        'color': Color(0xFF2A8F7F),
      },
      // {
      //   'icon': Aqim.ramadhan_02,
      //   'label': 'Hadith',
      //   'route': 'hadith',
      //   'color': Color(0xFF6A1B9A),
      // },
      {
        'icon': Aqim.kaaba_01,
        'label': 'Kiblat',
        'route': 'qibla',
        'color': Color(0xFFE64A19),
      },
      // {
      //   'icon': Aqim.ramadhanMonth,
      //   'label': 'Kalendar',
      //   'route': 'calendar',
      //   'color': Color(0xFF1565C0),
      // },
      {
        'icon': Aqim.ketupat,
        'label': 'Widgets',
        'route': 'widgets',
        'color': Color(0xFF1565C0),
      },
      {
        'icon': Aqim.kaaba_02,
        'label': 'Rakaat',
        'route': 'rakaat',
        'color': Color(0xFF1565C0),
      },
      {
        'icon': Aqim.zakat,
        'label': 'Donation',
        'route': 'donation',
        'color': Color(0xFF1565C0),
      },
      // {
      //   'icon': Icons.settings_outlined,
      //   'label': 'Setting',
      //   'route': 'settings',
      //   'color': Color(0xFF1565C0),
      // },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          'Menu Utama',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.0, //screenWidth > 800 ? 1.1 : 1.0,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return HomeButton(
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              onPressed: () {
                switch (action['route']) {
                  case 'dua':
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            DoaScreen(
                              onThemeToggle: widget.onThemeToggle,
                              doaData: _doaData!,
                            ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    break;
                  case 'hadith':
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const HadithScreen()),
                    // );
                    break;
                  case 'qibla':
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            KiblatScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    break;
                  case 'solat':
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            PrayerTimesScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    break;
                  case 'calendar':
                    // Navigator.push(
                    //   context,
                    //   PageRouteBuilder(
                    //     pageBuilder: (context, animation, secondaryAnimation) =>
                    //         HijriCalendarScreen(),
                    //     transitionsBuilder:
                    //         (context, animation, secondaryAnimation, child) {
                    //           return FadeTransition(
                    //             opacity: animation,
                    //             child: child,
                    //           );
                    //         },
                    //     transitionDuration: const Duration(milliseconds: 300),
                    //   ),
                    // );
                    break;
                  case 'widgets':
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            WidgetsScreen(onThemeToggle: widget.onThemeToggle),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    break;
                  case 'rakaat':
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            RakaatScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    break;
                  case 'donation':
                    showDialog(
                      context: context,
                      builder: (context) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(context),
                        child: const QrDermaDialog(),
                      ),
                    );

                    break;
                  case 'settings':
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            SettingsScreen2(
                              onThemeToggle: widget.onThemeToggle,
                              onLanguageChange: widget.onLanguageChange,
                              currentThemeMode: widget.currentThemeMode,
                              currentLanguage: widget.currentLanguage,
                              onThemeChange: widget.onThemeChange,
                            ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    break;
                  default:
                    debugPrint('⚠️ Unknown route: ${action['route']}');
                    break;
                }
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _setupNextPrayer() async {
    if (prayerTimeData == null) {
      return;
    }

    try {
      final now = DateTime.now();
      final prayers = prayerTimeData!.prayers;

      if (prayers.isEmpty) {
        return;
      }

      // ✅ FILTER TO ONLY 5 MAIN PRAYERS
      final mainPrayers = prayers.where((p) {
        final name = p.name.toLowerCase();
        return name == 'subuh' ||
            name == 'zohor' ||
            name == 'asar' ||
            name == 'maghrib' ||
            name == 'isyak';
      }).toList();

      if (mainPrayers.isEmpty) {
        debugPrint('❌ No main prayers found!');
        return;
      }

      String? nextName;
      String? nextTime;
      DateTime? nextDateTime;

      // Find next prayer that hasn't passed yet
      for (int i = 0; i < mainPrayers.length; i++) {
        final prayer = mainPrayers[i];

        try {
          final timeParts = prayer.time.split(':');
          if (timeParts.length < 2) {
            continue;
          }

          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final dt = DateTime(now.year, now.month, now.day, hour, minute);

          if (dt.isAfter(now)) {
            nextName = prayer.name;
            nextTime = prayer.time;
            nextDateTime = dt;
            break;
          }
        } catch (e) {
          debugPrint('❌ Error parsing: $e');
          continue;
        }
      }

      // If all times have passed, set next to Subuh tomorrow
      if (nextName == null || nextTime == null) {
        final subuh = mainPrayers.firstWhere(
          (p) => p.name.toLowerCase() == 'subuh',
          orElse: () => mainPrayers.first,
        );

        try {
          final timeParts = subuh.time.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final tomorrow = now.add(const Duration(days: 1));

          nextName = subuh.name;
          nextTime = subuh.time;
          nextDateTime = DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
            hour,
            minute,
          );
        } catch (e) {
          debugPrint('❌ Error parsing Subuh time: $e');
          return;
        }
      }

      // Calculate time left until next prayer
      final timeLeft = nextDateTime!.difference(now);

      // ✅ UPDATE prayer times data with isPassed and isNext flags (keep ALL 7 prayers)
      final updatedPrayers = prayers.map((prayer) {
        try {
          final timeParts = prayer.time.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final dt = DateTime(now.year, now.month, now.day, hour, minute);
          final isPassed = dt.isBefore(now);

          // Only mark 5 main prayers as "next" (not Imsak/Syuruk)
          final isMainPrayer = [
            'subuh',
            'zohor',
            'asar',
            'maghrib',
            'isyak',
          ].contains(prayer.name.toLowerCase());
          final isNext = isMainPrayer && prayer.name == nextName;

          return prayer.copyWith(isPassed: isPassed, isNext: isNext);
        } catch (e) {
          debugPrint('❌ Error updating ${prayer.name}: $e');
          return prayer;
        }
      }).toList();

      // Update prayerTimeData with ALL 7 prayers (including Imsak and Syuruk)
      prayerTimeData = prayerTimeData!.copyWith(prayers: updatedPrayers);

      if (!mounted) return;

      setState(() {
        _nextPrayerName = nextName;
        _nextPrayerTime = nextTime;
        _nextPrayerTimeLeft = timeLeft;
      });

      _startCountdownTimer();

      // final hours = _nextPrayerTimeLeft!.inHours;
      // final minutes = _nextPrayerTimeLeft!.inMinutes % 60;

      // debugPrint('');
      // debugPrint('   ✅ NEXT PRAYER: $nextName');
      // debugPrint('   ⏰ TIME: $nextTime');
      // debugPrint('   ⏳ TIME LEFT: ${hours}h ${minutes}m');
      // debugPrint('═' * 70);
      // debugPrint('');
    } catch (e, st) {
      debugPrint('❌ Error in _setupNextPrayer: $e');
      debugPrint('📋 $st');
    }
  }

  void _startCountdownTimer() {
    // ✅ Cancel existing timer if any
    _countdownTimer?.cancel();

    // ✅ Update every 1 second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_nextPrayerTimeLeft != null) {
        setState(() {
          _nextPrayerTimeLeft =
              _nextPrayerTimeLeft! - const Duration(seconds: 1);

          if (_nextPrayerTimeLeft!.isNegative) {
            _countdownTimer?.cancel();
            debugPrint('🕌 Prayer time reached!');
            // ✅ Optionally refresh to get next prayer
            _setupNextPrayer();
          }
        });
      }
    });
  }

  /// Format duration as "45m 30s" or "2h 15m 45s"
  String _formatTimeLeft(Duration duration) {
    if (duration.isNegative) return '0m 0s';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Future<void> _onRefreshDoa() async {
    _randomDoa = await DoaService.getRandomDoa(_doaData);
    if (mounted) setState(() {}); // ✅ Added mounted check
  }
}

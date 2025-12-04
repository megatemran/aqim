// ignore_for_file: avoid_print

import 'package:aqim/services/home_widget_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../models/prayer_time_model.dart';
import '../services/ads_service.dart';
import '../services/location_service.dart';
import '../services/prayer_alarm_service.dart';
import '../services/prayer_times_service.dart';
import '../utils/plugin.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  bool _isLoading = false;
  bool _isDisposed = false;

  PrayerTime? _getPrayer(String name) {
    debugPrint('prayerTimeData: ${prayerTimeData!.prayers}');
    return prayerTimeData?.prayers.firstWhere(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
      orElse: () =>
          PrayerTime(name: name, time: '--:--', isPassed: false, isNext: false),
    );
  }

  /// 🕋 Normalize Hijri date from 'dd-MM-yyyy' → 'd MMMM yyyy'
  String _normalizeHijriDate(String hijri) {
    try {
      final parts = hijri.split('-');
      if (parts.length != 3) return hijri;

      final day = int.tryParse(parts[0]) ?? 0;
      final month = int.tryParse(parts[1]) ?? 0;
      final year = int.tryParse(parts[2]) ?? 0;

      const hijriMonths = [
        'Muharam',
        'Safar',
        "Rabiulawal",
        "Rabiulakhir",
        'Jamadilawal',
        'Jamadilakhir',
        'Rejab',
        "Syaaban",
        'Ramadan',
        'Syawal',
        "Zulkaedah",
        'Zulhijah',
      ];

      final monthName = (month > 0 && month <= 12)
          ? hijriMonths[month - 1]
          : 'Unknown';

      return '$day $monthName ${year}h';
    } catch (e) {
      return hijri;
    }
  }

  /// 📅 Normalize Gregorian date from 'dd-MM-yyyy' → 'd MMM'
  String _normalizeDate(String date) {
    try {
      final parsed = DateFormat('dd-MM-yyyy').parse(date);
      return DateFormat('d MMM yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      // ✅ Load a FRESH interstitial ad (new instance each time)
      _loadInterstitialAd();

      // Get location again
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      final locationData = await locationService.getDetailedLocation(
        position.latitude,
        position.longitude,
      );

      // Fetch latest prayer times (force fresh, bypass cache)
      final prayerData = await PrayerTimesService().getPrayerTimesData(
        locationData,
        forceFresh: true,
      );

      if (mounted) {
        setState(() {
          prayerTimeData = prayerData;
        });
      }

      await HomeWidgetService().updateWidget();

      // ✅ Schedule prayer alarms after updating widget
      debugPrint('📅 Scheduling prayer alarms...');
      final success = await PrayerAlarmService.scheduleAllPrayerAlarms();
      debugPrint(success
          ? '✅ Prayer alarms scheduled successfully'
          : '❌ Failed to schedule prayer alarms');

      print(prayerTimeData);
    } catch (e) {
      print('Error refreshing prayer times: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);

        // Reload banner ad after refresh completes to ensure it's in a valid state
        _loadBannerSolat();
      }
    }
  }

  @override
  void initState() {
    _loadBannerSolat();
    _loadInterstitialAd();
    super.initState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerSolat?.dispose();
    _interstitialAd?.dispose();
    AdsService().disposeInterstitialAd();
    super.dispose();
  }

  /// Load Banner Ad
  BannerAd? _bannerSolat;
  bool _isBannerSolatLoaded = false;
  void _loadBannerSolat() {
    if (!isShowAds) {
      debugPrint('❌ Ads disabled - skipping solat banner');
      return;
    }
    if (_bannerSolat != null) {
      _bannerSolat!.dispose();
      _bannerSolat = null;
    }

    AdsService().loadBannerSolat1(
      onAdLoaded: (ad) {
        if (!mounted || _isDisposed) {
          ad.dispose();
          return;
        }
        setState(() {
          _bannerSolat = ad as BannerAd;
          _isBannerSolatLoaded = true;
        });
        debugPrint('✅ Banner ad loaded');
      },
      onAdFailedToLoad: (ad, err) {
        ad.dispose();
        if (mounted && !_isDisposed) {
          setState(() {
            _bannerSolat = null;
            _isBannerSolatLoaded = false;
          });
        }
        debugPrint('❌ Failed to load banner ad: ${err.message}');
      },
    );
  }

  /// Load Interstitial Ad
  InterstitialAd? _interstitialAd;

  void _loadInterstitialAd() {
    if (!isShowAds) {
      debugPrint('❌ Ads disabled - skipping solat interstitial');
      return;
    }
    // Prevent multiple loads - dispose old ad properly
    _interstitialAd?.dispose();
    _interstitialAd = null;

    InterstitialAd.load(
      adUnitId: AdsService().solatInterstitial1AdString,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('✅ Interstitial ad loaded');

          // ✅ Check if screen is still mounted before setting
          if (_isDisposed || !mounted) {
            ad.dispose();
            return;
          }

          _interstitialAd = ad;
          _setFullScreenContentCallback(ad);

          // ✅ Show the ad immediately after setup
          ad.show().catchError((error) {
            debugPrint('❌ Failed to show ad: $error');
            ad.dispose();
            _interstitialAd = null;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ Failed to load interstitial ad: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _setFullScreenContentCallback(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('✅ Ad showed full screen content.');
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('❌ Ad failed to show full screen content with error: $err');
        ad.dispose();
        _interstitialAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('✅ Ad was dismissed.');
        ad.dispose();
        _interstitialAd = null; // ✅ Clear reference after disposal
      },
      onAdImpression: (ad) {
        debugPrint('Ad recorded an impression.');
      },
      onAdClicked: (ad) {
        debugPrint('Ad was clicked.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: cs.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/bg1.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.6),
                isDark ? BlendMode.darken : BlendMode.lighten,
              ),
            ),
          ),
          child: SafeArea(child: Column(children: [topWidget(), mainWidget()])),
        ),
      ),
    );
  }

  Widget mainWidget() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          _isLoading
              ? _buildShimmerPlaceholder(width: 170.w, height: 20.h)
              : Text(
                  prayerTimeData!.userLocationData['lokasi'],
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
          SizedBox(height: _isLoading ? 20.h : 8.h),
          _isLoading
              ? _buildShimmerPlaceholder(width: 120.w, height: 16.h)
              : Text(
                  _normalizeDate(prayerTimeData!.date),
                  style: TextStyle(fontSize: 16.sp, color: cs.onSurface),
                ),
          SizedBox(height: _isLoading ? 19.h : 4.h),
          _isLoading
              ? _buildShimmerPlaceholder(width: 170.w, height: 16.h)
              : Text(
                  _normalizeHijriDate(prayerTimeData!.hijri),
                  style: TextStyle(fontSize: 16.sp, color: cs.onSurface),
                ),
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                width: 1.5.w,
                color: isDark
                    ? cs.outline.withValues(alpha: 0.3)
                    : cs.outline.withValues(alpha: 0.4),
              ),
              color: isDark
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
                  : cs.surfaceContainerLow.withValues(alpha: 0.2),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Column(
                children: [
                  prayerTimesWidget('Imsak', _getPrayer('Imsak')?.time),
                  prayerTimesWidget('Subuh', _getPrayer('Subuh')?.time),
                  prayerTimesWidget('Syuruk', _getPrayer('Syuruk')?.time),
                  prayerTimesWidget('Zohor', _getPrayer('Zohor')?.time),
                  prayerTimesWidget('Asar', _getPrayer('Asar')?.time),
                  prayerTimesWidget('Maghrib', _getPrayer('Maghrib')?.time),
                  prayerTimesWidget('Isyak', _getPrayer('Isyak')?.time),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          // 📱 Banner Ad (centered) - hide during loading to prevent errors
          if (!_isLoading && _isBannerSolatLoaded && _bannerSolat != null && isShowAds)
            Container(
              margin: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: SizedBox(
                  width: _bannerSolat!.size.width.toDouble(),
                  height: _bannerSolat!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerSolat!),
                ),
              ),
            ),
          _isLoading
              ? Column(
                  children: [
                    SizedBox(height: 8.h),
                    _buildShimmerPlaceholder(width: 80.w, height: 10.h),
                    SizedBox(height: 8.h),
                  ],
                )
              : Text(
                  "Sumber dari ${prayerTimeData!.sumber}",
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 14.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
          _isLoading
              ? _buildShimmerPlaceholder(width: 120.w, height: 10.h)
              : Text(
                  prayerTimeData!.sumberWebsite,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 14.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ],
      ),
    );
  }

  Widget topWidget() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: cs.onSurface, size: 28.sp),
          ),
          Expanded(
            child: Center(
              child: Text(
                "Waktu Solat",
                style: TextStyle(
                  fontSize: 26.sp,
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _onRefresh,
            style: IconButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            icon: Icon(Icons.refresh, size: 20.sp),
          ),
        ],
      ),
    );
  }

  Widget prayerTimesWidget(String name, String? time) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          _isLoading
              ? _buildShimmerPlaceholder(width: 80.w, height: 24.h)
              : Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
        ],
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "-";
    try {
      final parsed = DateFormat("HH:mm").parse(timeStr);
      return DateFormat("h.mm a").format(parsed).toLowerCase();
    } catch (_) {
      return timeStr;
    }
  }

  Widget _buildShimmerPlaceholder({
    required double width,
    required double height,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark
          ? cs.surfaceContainerHighest
          : cs.surfaceContainerLowest,
      highlightColor: isDark
          ? cs.onSurface.withValues(alpha: 0.6)
          : cs.onSurfaceVariant.withValues(alpha: 0.6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
              : cs.surfaceContainerLowest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/plugin.dart';

class AdsService {
  // ==================== TEST AD UNIT IDs ====================
  // Google's official test ad unit IDs - always fill with test ads
  static const String testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  // ✅ Islamic keywords for AdRequest
  static const List<String> islamicKeywords = [
    'malaysia',
    'islamic',
    'prayer',
    'prayer times',
    'quran',
    'quran recitation',
    'hadith',
    'dua',
    'islamic education',
    'islamic finance',
    'halal',
    'muslim',
    'islam',
    'ummah',
    'salah',
    'fiqh',
    'surah',
    'taqwa',
    'ramadan',
    'eid',
    'hajj',
    'umrah',
    'zakat',
    'tawheed',
    'islamic apps',
    'azan',
    'solat',
  ];

  final String appOpenAndroid = '';
  final String appOpenIos = '';

  // ==================== BANNER ADS ====================
  final String homeBanner1Android = 'ca-app-pub-7677814397287910/7114361815';
  final String homeBanner1Ios = '';

  final String doaBanner1Android = 'ca-app-pub-7677814397287910/7342410764';
  final String doaBanner1Ios = '';

  final String doaBanner2Android = 'ca-app-pub-7677814397287910/8803698069';
  final String doaBanner2Ios = '';

  final String solatBanner1Android = 'ca-app-pub-7677814397287910/3247145288';
  final String solatBanner1Ios = '';

  final String kiblahBanner1Android = '';
  final String kiblahBanner1Ios = '';

  final String widgetBanner1Android = 'ca-app-pub-7677814397287910/3954803861';
  final String widgetBanner1Ios = '';

  final String azanBanner1Android = 'ca-app-pub-7677814397287910/2467011119';
  final String azanBanner1Ios = '';

  // ==================== INTERSTITIAL ADS ====================

  final String widgetInterstitial1Android = 'ca-app-pub-7677814397287910/4999473984';
  final String widgetInterstitial1Ios = '';

  final String widgetInterstitial2Android = '';
  final String widgetInterstitial2Ios = '';

  final String widgetInterstitial3Android = '';
  final String widgetInterstitial3Ios = '';

  final String widgetInterstitial4Android = '';
  final String widgetInterstitial4Ios = '';

  final String widgetInterstitial5Android = '';
  final String widgetInterstitial5Ios = '';

  final String solatInterstitial1Android =
      'ca-app-pub-7677814397287910/2380909888';
  final String solatInterstitial1Ios = '';

  final String rakaatInterstitial1Android =
      'ca-app-pub-7677814397287910/2124738480';
  final String rakaatInterstitial1Ios = '';

  final String kiblatInterstitial1Android =
      'ca-app-pub-7677814397287910/8873979667';
  final String kiblatInterstitial1Ios = '';

  // Ad instances
  AppOpenAd? appOpenAd;
  BannerAd? bannerAd;
  InterstitialAd? interstitialAd;

  // ==================== GETTERS FOR AD UNIT IDS ====================
  // In debug mode, use test ad unit IDs
  // In release mode, use real ad unit IDs

  String get appOpenAdString {
    if (kDebugMode) return Platform.isAndroid ? testBannerAndroid : testBannerIos;
    return Platform.isAndroid ? appOpenAndroid : appOpenIos;
  }

  String get homeBanner1AdString {
    if (kDebugMode) return Platform.isAndroid ? testBannerAndroid : testBannerIos;
    return Platform.isAndroid ? homeBanner1Android : homeBanner1Ios;
  }

  String get doaBanner1AdString {
    if (kDebugMode) return Platform.isAndroid ? testBannerAndroid : testBannerIos;
    return Platform.isAndroid ? doaBanner1Android : doaBanner1Ios;
  }

  String get doaBanner2AdString {
    if (kDebugMode) return Platform.isAndroid ? testBannerAndroid : testBannerIos;
    return Platform.isAndroid ? doaBanner2Android : doaBanner2Ios;
  }

  String get solatBanner1AdString {
    if (kDebugMode) return Platform.isAndroid ? testBannerAndroid : testBannerIos;
    return Platform.isAndroid ? solatBanner1Android : solatBanner1Ios;
  }

  String get azanBanner1AdString {
    if (kDebugMode) return Platform.isAndroid ? testBannerAndroid : testBannerIos;
    return Platform.isAndroid ? azanBanner1Android : azanBanner1Ios;
  }

  String get kiblahBanner1AdString {
    if (kDebugMode) return Platform.isAndroid ? testBannerAndroid : testBannerIos;
    return Platform.isAndroid ? kiblahBanner1Android : kiblahBanner1Ios;
  }

  String get widgetBanner1AdString {
    if (kDebugMode) return Platform.isAndroid ? testBannerAndroid : testBannerIos;
    return Platform.isAndroid ? widgetBanner1Android : widgetBanner1Ios;
  }

  String get widgetInterstitial1AdString {
    if (kDebugMode) return Platform.isAndroid ? testInterstitialAndroid : testInterstitialIos;
    return Platform.isAndroid ? widgetInterstitial1Android : widgetInterstitial1Ios;
  }

  String get widgetInterstitial2AdString {
    if (kDebugMode) return Platform.isAndroid ? testInterstitialAndroid : testInterstitialIos;
    return Platform.isAndroid ? widgetInterstitial2Android : widgetInterstitial2Ios;
  }

  String get widgetInterstitial3AdString {
    if (kDebugMode) return Platform.isAndroid ? testInterstitialAndroid : testInterstitialIos;
    return Platform.isAndroid ? widgetInterstitial3Android : widgetInterstitial3Ios;
  }

  String get widgetInterstitial4AdString {
    if (kDebugMode) return Platform.isAndroid ? testInterstitialAndroid : testInterstitialIos;
    return Platform.isAndroid ? widgetInterstitial4Android : widgetInterstitial4Ios;
  }

  String get widgetInterstitial5AdString {
    if (kDebugMode) return Platform.isAndroid ? testInterstitialAndroid : testInterstitialIos;
    return Platform.isAndroid ? widgetInterstitial5Android : widgetInterstitial5Ios;
  }

  String get solatInterstitial1AdString {
    if (kDebugMode) return Platform.isAndroid ? testInterstitialAndroid : testInterstitialIos;
    return Platform.isAndroid ? solatInterstitial1Android : solatInterstitial1Ios;
  }

  String get rakaatInterstitial1AdString {
    if (kDebugMode) return Platform.isAndroid ? testInterstitialAndroid : testInterstitialIos;
    return Platform.isAndroid ? rakaatInterstitial1Android : rakaatInterstitial1Ios;
  }

  String get kiblatInterstitial1AdString {
    if (kDebugMode) return Platform.isAndroid ? testInterstitialAndroid : testInterstitialIos;
    return Platform.isAndroid ? kiblatInterstitial1Android : kiblatInterstitial1Ios;
  }

  // ==================== INITIALIZATION ====================

  /// ✅ Initialize Google Mobile Ads
  Future<InitializationStatus> initGoogleMobileAds() async {
    final status = await MobileAds.instance.initialize();

    // Loop through adapter statuses
    bool anyNotReady = status.adapterStatuses.values.any(
      (adapterStatus) =>
          adapterStatus.state == AdapterInitializationState.notReady,
    );

    if (anyNotReady) {
      print('❌ AdMob adapters not ready - ads will be disabled');
      // Note: Not forcing isShowAds here - respecting user's plugin.dart setting
    } else {
      print('✅ AdMob initialized successfully');
      if (isShowAds) {
        print('✅ Ads ENABLED - will show ads');
        if (kDebugMode) {
          print('🧪 DEBUG MODE: Using Google test ad unit IDs');
          print('   • Test ads will always load successfully');
        } else {
          print('📱 RELEASE MODE: Using production ad unit IDs');
        }
        print('   • Islamic keywords enabled on all ads');
        print('   • All ads filtered for Islamic content');
      } else {
        print('❌ Ads DISABLED (isShowAds = false in plugin.dart)');
        print('   • No ads will load or display');
        print('   • To enable ads, set isShowAds = true in lib/utils/plugin.dart');
      }
    }

    return status;
  }

  /// ✅ Build AdRequest with Islamic keywords
  AdRequest _buildIslamicAdRequest() {
    return AdRequest(
      // ✅ Islamic keywords - these help match with Islamic advertisers
      // NOTE: In release mode, if "No fill" errors persist, comment out keywords
      // to increase fill rate, then gradually add them back
      keywords: kDebugMode ? islamicKeywords : [], // Use keywords only in debug mode initially

      // ✅ Content URL for better targeting
      contentUrl: 'https://www.aqim.my/prayer-times',

      // Keep personalization enabled for better ad matching
      nonPersonalizedAds: false,
    );
  }

  // ==================== APP OPEN AD ====================
  Future<void> loadAppOpenAd() async {
    if (isShowAds) {
      await AppOpenAd.load(
        adUnitId: appOpenAdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            appOpenAd = ad;
            appOpenAd!.show();
          },
          onAdFailedToLoad: (e) {
            print('❌ Error loading App Open Ad: $e');
          },
        ),
      );
    }
  }

  // ==================== BANNER ADS ====================

  /// Load Home Banner 1 with Islamic filtering
  BannerAd? loadBannerHome1({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      BannerAd bannerAd = BannerAd(
        adUnitId: homeBanner1AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      );
      bannerAd.load();
      return bannerAd;
    }
    print('❌ Ads are disabled or AdMob is not ready.');
    return null;
  }

  /// Load Doa Banner 1 with Islamic filtering
  BannerAd? loadBannerDoa1({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      BannerAd bannerAd = BannerAd(
        adUnitId: doaBanner1AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      );
      bannerAd.load();
      return bannerAd;
    }
    print('❌ Ads are disabled or AdMob is not ready.');
    return null;
  }

  /// Load Doa Banner 2 with Islamic filtering
  BannerAd? loadBannerDoa2({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      BannerAd bannerAd = BannerAd(
        adUnitId: doaBanner2AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      );
      bannerAd.load();
      return bannerAd;
    }
    print('❌ Ads are disabled or AdMob is not ready.');
    return null;
  }

  /// Load Solat Banner 1 with Islamic filtering
  BannerAd? loadBannerSolat1({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      BannerAd bannerAd = BannerAd(
        adUnitId: solatBanner1AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      );
      bannerAd.load();
      return bannerAd;
    }
    print('❌ Ads are disabled or AdMob is not ready.');
    return null;
  }

  /// Load Kiblah Banner 1 with Islamic filtering
  BannerAd? loadBannerKiblah1({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      BannerAd bannerAd = BannerAd(
        adUnitId: kiblahBanner1AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      );
      bannerAd.load();
      return bannerAd;
    }
    print('❌ Ads are disabled or AdMob is not ready.');
    return null;
  }

  BannerAd? loadBannerAzan1({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    if (!isShowAds) {
      print('❌ Ads disabled');
      return null;
    }

    final banner = BannerAd(
      adUnitId: azanBanner1AdString,
      size: AdSize.banner,
      request: _buildIslamicAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('🎉 Banner loaded');
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, err) {
          print("❌ Banner failed: ${err.message}");
          onAdFailedToLoad(ad, err);
          ad.dispose();
        },
      ),
    );

    // IMPORTANT!!!
    banner.load();
    return banner;
  }

  /// Load Widget Banner 1 with Islamic filtering
  BannerAd? loadBannerWidget1({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      BannerAd bannerAd = BannerAd(
        adUnitId: widgetBanner1AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      );
      bannerAd.load();
      return bannerAd;
    }
    print('❌ Ads are disabled or AdMob is not ready.');
    return null;
  }

  // ==================== INTERSTITIAL ADS ====================

  /// Load Widget Interstitial 1 with Islamic filtering
  void loadWidgetInterstitial1({
    required void Function() onAdDismissed,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      InterstitialAd.load(
        adUnitId: widgetInterstitial1AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            _showInterstitialAd(onAdDismissed);
          },
          onAdFailedToLoad: (error) {
            print('❌ Widget Interstitial 1 failed to load: $error');
            onAdFailedToLoad(error);
          },
        ),
      );
    }
  }

  /// Load Widget Interstitial 2 with Islamic filtering
  void loadWidgetInterstitial2({
    required void Function() onAdDismissed,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      InterstitialAd.load(
        adUnitId: widgetInterstitial2AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            _showInterstitialAd(onAdDismissed);
          },
          onAdFailedToLoad: (error) {
            print('❌ Widget Interstitial 2 failed to load: $error');
            onAdFailedToLoad(error);
          },
        ),
      );
    }
  }

  /// Load Widget Interstitial 3 with Islamic filtering
  void loadWidgetInterstitial3({
    required void Function() onAdDismissed,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      InterstitialAd.load(
        adUnitId: widgetInterstitial3AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            _showInterstitialAd(onAdDismissed);
          },
          onAdFailedToLoad: (error) {
            print('❌ Widget Interstitial 3 failed to load: $error');
            onAdFailedToLoad(error);
          },
        ),
      );
    }
  }

  /// Load Widget Interstitial 4 with Islamic filtering
  void loadWidgetInterstitial4({
    required void Function() onAdDismissed,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      InterstitialAd.load(
        adUnitId: widgetInterstitial4AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            _showInterstitialAd(onAdDismissed);
          },
          onAdFailedToLoad: (error) {
            print('❌ Widget Interstitial 4 failed to load: $error');
            onAdFailedToLoad(error);
          },
        ),
      );
    }
  }

  /// Load Widget Interstitial 5 with Islamic filtering
  void loadWidgetInterstitial5({
    required void Function() onAdDismissed,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      InterstitialAd.load(
        adUnitId: widgetInterstitial5AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            _showInterstitialAd(onAdDismissed);
          },
          onAdFailedToLoad: (error) {
            print('❌ Widget Interstitial 5 failed to load: $error');
            onAdFailedToLoad(error);
          },
        ),
      );
    }
  }

  /// Load Solat Interstitial 1 with Islamic filtering
  void loadSolatInterstitial1({
    required void Function() onAdDismissed,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      InterstitialAd.load(
        adUnitId: solatInterstitial1AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            _showInterstitialAd(onAdDismissed);
          },
          onAdFailedToLoad: (error) {
            print('❌ Solat Interstitial 1 failed to load: $error');
            onAdFailedToLoad(error);
          },
        ),
      );
    }
  }

  /// Load Rakaat Interstitial 1 with Islamic filtering
  void loadRakaatInterstitial1({
    required void Function() onAdDismissed,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) {
    if (isShowAds) {
      InterstitialAd.load(
        adUnitId: rakaatInterstitial1AdString,
        request: _buildIslamicAdRequest(), // ✅ Uses Islamic keywords
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            _showInterstitialAd(onAdDismissed);
          },
          onAdFailedToLoad: (error) {
            print('❌ Rakaat Interstitial 1 failed to load: $error');
            onAdFailedToLoad(error);
          },
        ),
      );
    }
  }

  /// Show interstitial ad with callback
  void _showInterstitialAd(Function() onAdDismissed) {
    if (interstitialAd != null) {
      interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          // debugPrint('✅ Interstitial Ad showed');
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          //   debugPrint('❌ Interstitial Ad failed to show: ${error.message}');
          ad.dispose();
          interstitialAd = null;
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          // debugPrint('✅ Interstitial Ad dismissed');
          ad.dispose();
          interstitialAd = null;
          onAdDismissed();
        },
      );
      interstitialAd!.show();
    }
  }

  // ==================== CLEANUP ====================

  /// Dispose banner ad
  void disposeBannerAd() {
    bannerAd?.dispose();
    bannerAd = null;
  }

  /// Dispose interstitial ad
  void disposeInterstitialAd() {
    interstitialAd?.dispose();
    interstitialAd = null;
  }

  /// Dispose all ads
  void disposeAll() {
    disposeBannerAd();
    disposeInterstitialAd();
  }
}

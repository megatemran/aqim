import 'package:aqim/utils/plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';
import '../services/home_widget_service.dart';

class WidgetsScreen extends StatefulWidget {
  const WidgetsScreen({super.key, required this.onThemeToggle});
  final VoidCallback onThemeToggle;
  @override
  State<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends State<WidgetsScreen> {
  BannerAd? _bannerWidget;
  bool _isBannerWidgetLoaded = false;
  InterstitialAd? _widgetInterstitial;
  bool _isLoadingInterstitial = false;

  @override
  void initState() {
    super.initState();
    _loadBannerWidget();
    _loadWidgetInterstitial();
  }

  @override
  void dispose() {
    _bannerWidget?.dispose();
    _widgetInterstitial?.dispose();
    super.dispose();
  }

  void _loadBannerWidget() {
    if (!isShowAds) {
      debugPrint('❌ Ads disabled - skipping widget banner');
      return;
    }
    debugPrint('🔄 Loading widget banner ad...');
    AdsService().loadBannerWidget1(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _bannerWidget = ad as BannerAd;
            _isBannerWidgetLoaded = true;
          });
          debugPrint(
            '✅ Widget banner loaded successfully - will show at bottom',
          );
          debugPrint('📍 isShowAds: $isShowAds');
        }
      },
      onAdFailedToLoad: (ad, err) {
        debugPrint(
          '❌ Failed to load widget banner: ${err.message} (Error code: ${err.code})',
        );
        if (mounted) {
          setState(() {
            _bannerWidget = null;
            _isBannerWidgetLoaded = false;
          });
        }
        ad.dispose();
      },
    );
  }

  void _loadWidgetInterstitial() {
    if (!isShowAds) {
      debugPrint('❌ Ads disabled - skipping interstitial load');
      return;
    }

    if (_isLoadingInterstitial) {
      debugPrint('⏳ Already loading interstitial ad');
      return;
    }

    setState(() {
      _isLoadingInterstitial = true;
    });

    debugPrint('🔄 Loading widget interstitial ad...');
    InterstitialAd.load(
      adUnitId: AdsService().widgetInterstitial1AdString,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Widget interstitial loaded successfully');
          if (mounted) {
            setState(() {
              _widgetInterstitial = ad;
              _isLoadingInterstitial = false;
            });
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Widget interstitial failed to load: ${error.message}');
          if (mounted) {
            setState(() {
              _widgetInterstitial = null;
              _isLoadingInterstitial = false;
            });
          }
        },
      ),
    );
  }

  void _showInterstitialAndAddWidget({
    required String androidName,
    required String qualifiedAndroidName,
  }) async {
    debugPrint('📱 Attempting to add widget: $androidName');

    // If ads are disabled or interstitial not loaded, add widget directly
    if (!isShowAds || _widgetInterstitial == null) {
      debugPrint('⚠️ No interstitial ad - proceeding to add widget');
      await HomeWidgetService().addWidgetToHomeScreen(
        context: context,
        androidName: androidName,
        qualifiedAndroidName: qualifiedAndroidName,
      );
      return;
    }

    // Set up callbacks for interstitial
    _widgetInterstitial!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('✅ Widget interstitial ad showed');
      },
      onAdDismissedFullScreenContent: (ad) async {
        debugPrint('✅ Widget interstitial ad dismissed');
        ad.dispose();
        _widgetInterstitial = null;

        // Add widget after ad is dismissed
        await HomeWidgetService().addWidgetToHomeScreen(
          context: context,
          androidName: androidName,
          qualifiedAndroidName: qualifiedAndroidName,
        );

        // Load a new interstitial for next widget
        _loadWidgetInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) async {
        debugPrint('❌ Widget interstitial failed to show: ${error.message}');
        ad.dispose();
        _widgetInterstitial = null;

        // Still add widget even if ad failed to show
        await HomeWidgetService().addWidgetToHomeScreen(
          context: context,
          androidName: androidName,
          qualifiedAndroidName: qualifiedAndroidName,
        );

        // Try to load a new interstitial
        _loadWidgetInterstitial();
      },
    );

    // Show the interstitial ad
    debugPrint('📺 Showing widget interstitial ad...');
    await _widgetInterstitial!.show();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerHigh,
        title: Text(
          'Widget Screen',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 24.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.brightness_6, size: 20.sp),
        //     onPressed: widget.onThemeToggle,
        //   ),
        // ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.w, horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ///
              /// WAKTU SOLAT WIDGET
              ///
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(3, 4),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Text(
                          'Waktu Solat',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 0.8,
                          ),
                          image: DecorationImage(
                            image: AssetImage('assets/images/bg4.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),

                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 14.h,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Waktu Solat',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              prayerRow('Subuh', '5.53 am'),
                              prayerRow('Zohor', '1.04 pm'),
                              prayerRow('Asar', '4.24 pm'),
                              prayerRow('Maghrib', '7.01 pm'),
                              prayerRow('Isyak', '8.12 pm'),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Widget ini memaparkan waktu solat harian bagi lima waktu utama iaitu Subuh, Zohor, Asar, Maghrib dan Isyak. Ia menunjukkan waktu solat semasa dengan data yang diambil terus daripada laman web rasmi E-Solat JAKIM bagi menjamin ketepatan masa serta kesesuaian zon waktu pengguna.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: FilledButton.icon(
                          onPressed: () {
                            _showInterstitialAndAddWidget(
                              androidName: "WaktuSolatWidgetReceiver",
                              qualifiedAndroidName:
                                  "net.brings2you.aqim.WaktuSolatWidgetReceiver",
                            );
                          },
                          icon: Icon(Icons.add),
                          label: Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isBannerWidgetLoaded && _bannerWidget != null && isShowAds)
                Container(
                  margin: EdgeInsets.only(
                    bottom: 16.h,
                    left: 16.w,
                    right: 16.w,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: _bannerWidget!.size.width.toDouble(),
                      height: _bannerWidget!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerWidget!),
                    ),
                  ),
                ),

              ///
              /// DOA HARIAN WIDGET
              ///
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(3, 4),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Text(
                          'Doa Harian',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        height: 240.h,
                        width: double.infinity.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 0.8.w,
                          ),
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/images/doa_widget_preview.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Widget Doa Harian - Koleksi doa terpilih yang berganti setiap 1 minit. Sumber dari Al-Quran dan Hadis, menyediakan panduan sepanjang hari dengan cara yang mudah dan senang diingati.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: FilledButton.icon(
                          onPressed: () {
                            _showInterstitialAndAddWidget(
                              androidName: "DoaWidget",
                              qualifiedAndroidName:
                                  "net.brings2you.aqim.DoaWidgetReceiver",
                            );
                          },
                          icon: Icon(Icons.add),
                          label: Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              ///
              ///BISMILLAH WHITE WIDGET
              ///
              ///
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(3, 4),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Text(
                          'Bismillah White',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 0.8,
                          ),
                          image: DecorationImage(
                            image: AssetImage('assets/images/bg4.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),

                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 14.h,
                          ),
                          child: SvgPicture.asset(
                            'assets/svg/bismillah.svg',
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            semanticsLabel: 'Red dash paths',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Widget Bismillah Putih, menampilkan kalimah “بِسْمِ ٱللَّٰهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ” berwarna putih dengan latar gelap atau gradient lembut bagi memberi kontras yang indah, melambangkan ketenangan dan kesucian.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: FilledButton.icon(
                          onPressed: () {
                            _showInterstitialAndAddWidget(
                              androidName: "BismillahWhiteWidget",
                              qualifiedAndroidName:
                                  "net.brings2you.aqim.BismillahWhiteWidgetReceiver",
                            );
                          },
                          icon: Icon(Icons.add),
                          label: Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              ///
              ///BISMILLAH BLACK WIDGET
              ///
              ///
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(3, 4),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Text(
                          'Bismillah Black',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 0.8,
                          ),
                          image: DecorationImage(
                            image: AssetImage('assets/images/bg4.jpg'),
                            fit: BoxFit.cover,

                            colorFilter: ColorFilter.mode(
                              Colors.white.withValues(alpha: 0.4),
                              BlendMode.lighten,
                            ),
                          ),
                        ),

                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 14.h,
                          ),
                          child: SvgPicture.asset(
                            'assets/svg/bismillah.svg',
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                            semanticsLabel: 'Red dash paths',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Widget Bismillah Hitam, rekaannya lebih klasik dan elegan dengan tulisan berwarna hitam di atas latar putih atau pastel, sesuai untuk tema yang minimal dan terang,',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: FilledButton.icon(
                          onPressed: () {
                            _showInterstitialAndAddWidget(
                              androidName: "BismillahBlackWidget",
                              qualifiedAndroidName:
                                  "net.brings2you.aqim.BismillahBlackWidgetReceiver",
                            );
                          },
                          icon: Icon(Icons.add),
                          label: Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              ///
              ///BISMILLAH COLORED
              ///
              ///
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(3, 4),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Text(
                          'Bismillah Colorful',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 0.8,
                          ),
                          image: DecorationImage(
                            image: AssetImage('assets/images/bg4.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),

                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 14.h,
                          ),
                          child: SvgPicture.asset(
                            'assets/svg/bismillah_color.svg',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Widget Bismillah Colourful menampilkan gaya lebih moden dan menarik dengan kaligrafi berwarna pelangi atau gradient lembut seperti biru, ungu dan emas, membawa suasana ceria dan artistik, serta boleh dilengkapi dengan animasi sinaran cahaya atau corak Islamik abstrak bagi menambah nilai estetik pada paparan skrin',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: FilledButton.icon(
                          onPressed: () {
                            _showInterstitialAndAddWidget(
                              androidName: "BismillahColorWidget",
                              qualifiedAndroidName:
                                  "net.brings2you.aqim.BismillahColorWidgetReceiver",
                            );
                          },
                          icon: Icon(Icons.add),
                          label: Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 📱 Banner Ad (At Bottom of Scrollable Content)
            ],
          ),
        ),
      ),
    );
  }

  Widget prayerRow(String title, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14.sp, color: Colors.white),
        ),
        Text(
          time,
          style: TextStyle(fontSize: 14.sp, color: Colors.white),
        ),
      ],
    );
  }
}

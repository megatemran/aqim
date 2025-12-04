// ignore_for_file: avoid_print

import 'dart:ui' as ui;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';
import '../services/doa_service.dart';
import '../utils/aqim_icons.dart';
import '../utils/plugin.dart';

class DoaScreen extends StatefulWidget {
  const DoaScreen({
    super.key,
    required this.onThemeToggle,
    required this.doaData,
  });
  final VoidCallback onThemeToggle;
  final List<dynamic> doaData;

  @override
  State<DoaScreen> createState() => _DoaScreenState();
}

class _DoaScreenState extends State<DoaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBannerDoa();
    _loadBannerDoa2();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerDoa?.dispose();
    _bannerDoa2?.dispose();
    super.dispose();
  }

  BannerAd? _bannerDoa;
  bool _isBannerDoaLoaded = false;
  BannerAd? _bannerDoa2;
  bool _isBannerDoa2Loaded = false;

  void _loadBannerDoa() {
    if (!isShowAds) {
      debugPrint('❌ Ads disabled - skipping doa banner 1');
      return;
    }
    AdsService().loadBannerDoa1(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _bannerDoa = ad as BannerAd;
            _isBannerDoaLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, err) {
        print('Failed to load a banner ad: ${err.message}');
        if (mounted) {
          setState(() {
            _bannerDoa = null;
            _isBannerDoaLoaded = false;
          });
        }
        ad.dispose();
      },
    );
  }

  void _loadBannerDoa2() {
    if (!isShowAds) {
      debugPrint('❌ Ads disabled - skipping doa banner 2');
      return;
    }
    AdsService().loadBannerDoa2(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _bannerDoa2 = ad as BannerAd;
            _isBannerDoa2Loaded = true;
          });
          debugPrint('✅ Doa banner 2 loaded successfully');
        }
      },
      onAdFailedToLoad: (ad, err) {
        debugPrint('❌ Failed to load doa banner 2: ${err.message}');
        if (mounted) {
          setState(() {
            _bannerDoa2 = null;
            _isBannerDoa2Loaded = false;
          });
        }
        ad.dispose();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _buildAppBar(cs),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // _buildHeaderSection(cs, isDark),
            _buildCarouselSection(cs, isDark),
            // 📱 Banner Ad (centered)
            if (_isBannerDoaLoaded && _bannerDoa != null && isShowAds)
              Container(
                margin: EdgeInsets.symmetric(vertical: 16.h),
                child: Center(
                  child: SizedBox(
                    width: _bannerDoa!.size.width.toDouble(),
                    height: _bannerDoa!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerDoa!),
                  ),
                ),
              ),
            _buildTabNavigation(cs),
            _buildCategoryGrid(cs),
          ],
        ),
      ),
    );
  }

  // ✨ AppBar
  PreferredSizeWidget _buildAppBar(ColorScheme cs) {
    return AppBar(
      elevation: 0,
      backgroundColor: cs.surface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doa-Doa',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'Halaman Doa-Doa Harian',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),

      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(
          height: 1.h,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎠 Carousel Section (Adaptive Height)
  Widget _buildCarouselSection(ColorScheme cs, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'Ayat-Ayat Tentang Doa',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // ✅ Adaptive Carousel
          CarouselSlider.builder(
            itemCount: DoaService().doaHeader.length,
            options: CarouselOptions(
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              autoPlayInterval: const Duration(seconds: 6),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              enableInfiniteScroll: true,
              height: null,
              onPageChanged: (index, reason) {
                setState(() => _selectedCarouselIndex = index);
              },
            ),
            itemBuilder: (context, index, realIdx) {
              final doa = DoaService().doaHeader[index];
              return ConstrainedBox(
                constraints: BoxConstraints(minHeight: 220.h),
                child: IntrinsicHeight(
                  child: _buildCarouselCard(doa, cs, isDark),
                ),
              );
            },
          ),

          // Indicators
          SizedBox(height: 16.h),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                DoaService().doaHeader.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  height: 8.h,
                  width: _selectedCarouselIndex == index ? 24.w : 8.w,
                  decoration: BoxDecoration(
                    color: _selectedCarouselIndex == index
                        ? cs.secondaryContainer
                        : cs.secondaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎴 Carousel Card
  Widget _buildCarouselCard(
    Map<String, dynamic> doa,
    ColorScheme cs,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer,

        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Flexible(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: cs.onSecondaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: cs.onSecondaryContainer,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Ayat Quran',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: cs.onSecondaryContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Arabic Text
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      doa['arabic'],
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lateef',
                        color: cs.onSecondaryContainer,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Translation
                  Text(
                    doa['ms'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.5,
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      doa['ref'],

                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: cs.onSecondaryContainer.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reference
        ],
      ),
    );
  }

  // 📑 Tab Navigation
  Widget _buildTabNavigation(ColorScheme cs) {
    return Container(
      color: cs.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 1.h,
        dividerColor: cs.outlineVariant.withValues(alpha: 0.2),
        tabs: const [
          Tab(text: 'Semua Kategori'),
          Tab(text: 'Popular'),
        ],
      ),
    );
  }

  // 📱 Category Grid
  Widget _buildCategoryGrid(ColorScheme cs) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 1.2,
      child: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildGridContent(cs, DoaService().kategoriDoa),
          _buildGridContent(
            cs,
            DoaService().kategoriDoa.length > 10
                ? DoaService().kategoriDoa.sublist(0, 10)
                : DoaService().kategoriDoa,
          ),
        ],
      ),
    );
  }

  Widget _buildGridContent(
    ColorScheme cs,
    List<Map<String, String>> categories,
  ) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12.w,
          crossAxisSpacing: 8.w,
          childAspectRatio: 0.85,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final icons = _getCategoryIcon(category['ms'] ?? '');

          return _buildCategoryCard(
            category['ms'] ?? '',
            icons['icon'] as IconData,
            icons['color'] as Color,
            cs,
          );
        },
      ),
    );
  }

  // 🎯 Category Card
  Widget _buildCategoryCard(
    String title,
    IconData icon,
    Color iconColor,
    ColorScheme cs,
  ) {
    return InkWell(
      splashColor: Colors.white,
      onTap: () {
        _showDetailsDoaModal(context, title, icon, iconColor, cs);
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.7),
            width: 1,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38.sp, color: cs.primary),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: cs.onSurface,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 Category Icon Map
  Map<String, dynamic> _getCategoryIcon(String category) {
    const colorMap = {
      'Harian': (icon: Icons.access_time_outlined, color: Color(0xFFA0AF84)),
      'Kebersihan': (icon: Icons.water_drop_outlined, color: Color(0xFFF4743B)),
      'Makan': (icon: Icons.restaurant_outlined, color: Color(0xFF9A031E)),
      'Masjid': (icon: Icons.mosque_outlined, color: Color(0xFF11B5E4)),
      'Wuduk': (icon: Aqim.wudu_2, color: Color(0xFFBEB8EB)),
      'Puasa': (icon: Aqim.ramadhan_03, color: Color(0xFF5299D3)),
      'Rumah': (icon: Aqim.alAqsaMosque, color: Color(0xFFFFE066)),
      'Perlindungan': (icon: Aqim.muslim, color: Color(0xFF70C1B3)),
      'Perjalanan': (icon: Aqim.camel_2, color: Color(0xFFBEB8EB)),
      'Pakaian': (icon: Aqim.clothes, color: Color(0xFFD2CCA1)),
      'Cuaca': (icon: Icons.cloud_outlined, color: Color(0xFF7EBCE6)),
      'Taubat': (icon: Aqim.salah, color: Color(0xFF69D1C5)),
      'Doa': (icon: Aqim.dua, color: Color(0xFFF72585)),
      'Musibah': (icon: Icons.warning_amber, color: Color(0xFF1446A0)),
      'Hutang': (icon: Aqim.alms, color: Color(0xFFCDD3CE)),
      'Kesejahteraan': (icon: Aqim.quran_01, color: Color(0xFF753742)),
      'Adab': (icon: Icons.handshake_outlined, color: Color(0xFF94A89A)),
      'Akhlak': (icon: Icons.auto_awesome_outlined, color: Color(0xFFFFD166)),
      'Azan': (icon: Aqim.adzan, color: Color(0xFF611C35)),
      'Ibu Bapa': (icon: Icons.people_outline, color: Color(0xFF1A5F4F)),
    };

    final entry =
        colorMap[category] ?? (icon: Icons.star, color: Color(0xFF42A5F5));
    return {'icon': entry.icon, 'color': entry.color};
  }

  void _showDetailsDoaModal(
    BuildContext context,
    String categoryTitle,
    IconData categoryIcon,
    Color iconColor,
    ColorScheme cs,
  ) async {
    // Capture local context reference (safe)
    final localContext = context;

    List<dynamic> data = widget.doaData;

    // if (data.isEmpty) {
    //   // fallback to local file
    //   final String local = await rootBundle.loadString(
    //     'assets/json/duas_all.json',
    //   );
    //   data = jsonDecode(local);
    // }

    String categoryEn = DoaService().getCategory(categoryTitle);
    final List<Map<String, dynamic>> filteredDuas = data
        .where(
          (d) =>
              d['category'].toString().toLowerCase() ==
              categoryEn.toLowerCase(),
        )
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // ✅ SAFEST way to use context after async:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (filteredDuas.isEmpty) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(content: Text("No Doa found for category $categoryEn")),
        );
        return;
      }

      showModalBottomSheet(
        context: localContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(categoryIcon, color: cs.onSurface),
                        const SizedBox(width: 8),
                        Text(
                          categoryTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    SizedBox(height: 16.h),
                    Expanded(
                      child: PageView.builder(
                        itemCount: filteredDuas.length,
                        itemBuilder: (context, index) {
                          final doa = filteredDuas[index];
                          return SingleChildScrollView(
                            // padding: const EdgeInsets.symmetric(
                            //   horizontal: 2.,
                            //   vertical: 12,
                            // ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  doa['title']['ms'] ?? doa['title']['en'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  doa['arabic'],
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontSize: 45.sp,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Lateef',
                                    color: cs.onSurface,
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  doa['transliteration'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontStyle: FontStyle.italic,
                                    color: cs.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  doa['translation']['ms'] ??
                                      doa['translation']['en'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    height: 1.5,
                                    fontSize: 16.sp,
                                    color: cs.onSurface,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    doa['source'],
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: cs.onSurfaceVariant.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '${index + 1} / ${filteredDuas.length}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: cs.outline,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // 📱 Doa Banner Ad 2
                    if (_isBannerDoa2Loaded && _bannerDoa2 != null && isShowAds)
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 16.h),
                        child: Center(
                          child: SizedBox(
                            width: _bannerDoa2!.size.width.toDouble(),
                            height: _bannerDoa2!.size.height.toDouble(),
                            child: AdWidget(ad: _bannerDoa2!),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    });
  }
}

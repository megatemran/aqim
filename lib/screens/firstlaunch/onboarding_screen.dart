// ============================================
// FILE 2: screens/onboarding_screen.dart
// ============================================
import 'package:aqim/services/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/plugin.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  final Function(ThemeMode, String) onComplete;
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLanguageChanged;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  ThemeMode _selectedTheme = ThemeMode.system;
  String _selectedLanguage = 'ms';

  @override
  void initState() {
    _initAsync();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initAsync() async {
    await _setDefaultSettings();
  }

  Future<void> _setDefaultSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if this is first time (no settings saved yet)
      final isFirstTime = prefs.getBool('is_first_time') ?? true;

      if (!isFirstTime) {
        debugPrint('⚡ Settings already exist, skipping default setup');
        return;
      }

      debugPrint('🎯 First time setup - Setting default values...');

      // NOTIFICATION SETTINGS
      await prefs.setBool(prefNotificationsEnabled, true);
      await prefs.setBool(prefSoundEnabled, true);
      await prefs.setBool(prefVibrationEnabled, true);

      // PRAYER ENABLE/DISABLE
      await prefs.setBool(prefSubuhEnabled, true);
      await prefs.setBool(prefZohorEnabled, true);
      await prefs.setBool(prefAsarEnabled, true);
      await prefs.setBool(prefMaghribEnabled, true);
      await prefs.setBool(prefIsyakEnabled, true);

      // PRAYER SOUNDS
      await prefs.setString(prefSubuhSound, 'azan_subuh_tv3_2018');
      await prefs.setString(prefZohorSound, 'azan_zohor_ashfaq_hussain');
      await prefs.setString(prefAsarSound, 'azan_asar_tv1_2018');
      await prefs.setString(prefMaghribSound, 'azan_maghrib_tv3_2018');
      await prefs.setString(prefIsyakSound, 'azan_isyak_munif_hijjaz');

      // PRAYER VIBRATION
      await prefs.setBool(prefSubuhVibrate, true);
      await prefs.setBool(prefZohorVibrate, true);
      await prefs.setBool(prefAsarVibrate, true);
      await prefs.setBool(prefMaghribVibrate, true);
      await prefs.setBool(prefIsyakVibrate, true);

      // PRAYER LED
      await prefs.setBool(prefSubuhLed, true);
      await prefs.setBool(prefZohorLed, true);
      await prefs.setBool(prefAsarLed, true);
      await prefs.setBool(prefMaghribLed, true);
      await prefs.setBool(prefIsyakLed, true);

      // PRAYER FULLSCREEN
      await prefs.setBool(prefSubuhFullscreen, true);
      await prefs.setBool(prefZohorFullscreen, true);
      await prefs.setBool(prefAsarFullscreen, true);
      await prefs.setBool(prefMaghribFullscreen, true);
      await prefs.setBool(prefIsyakFullscreen, true);

      // PRAYER REMINDERS (5 minutes)
      await prefs.setBool(prefSubuhReminder5Min, false);
      await prefs.setBool(prefZohorReminder5Min, false);
      await prefs.setBool(prefAsarReminder5Min, false);
      await prefs.setBool(prefMaghribReminder5Min, false);
      await prefs.setBool(prefIsyakReminder5Min, false);

      // PRAYER REMINDERS (10 minutes)
      await prefs.setBool(prefSubuhReminder10Min, false);
      await prefs.setBool(prefZohorReminder10Min, false);
      await prefs.setBool(prefAsarReminder10Min, false);
      await prefs.setBool(prefMaghribReminder10Min, false);
      await prefs.setBool(prefIsyakReminder10Min, false);

      // PRAYER REMINDERS (15 minutes)
      await prefs.setBool(prefSubuhReminder15Min, false);
      await prefs.setBool(prefZohorReminder15Min, false);
      await prefs.setBool(prefAsarReminder15Min, false);
      await prefs.setBool(prefMaghribReminder15Min, false);
      await prefs.setBool(prefIsyakReminder15Min, false);

      // TIME FORMAT
      await prefs.setBool(prefIs24HourFormat, true);

      // Mark as no longer first time
      await prefs.setBool('is_first_time', false);

      debugPrint('✅ Default settings saved successfully!');
    } catch (e) {
      debugPrint('error setdefaultsettings: $e');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    widget.onComplete(_selectedTheme, _selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 4.h,
                      margin: EdgeInsets.only(right: index < 2 ? 8.w : 0),
                      decoration: BoxDecoration(
                        color: _currentPage >= index
                            ? const Color(0xFF1A5F4F)
                            : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomePage(isDark),
                  _buildLanguageSelectionPage(isDark),
                  _buildThemeSelectionPage(isDark),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: EdgeInsets.all(24.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5F4F),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    _currentPage == 2
                        ? AppLocalizations.maybeOf(
                                context,
                              )?.translate('get_started') ??
                              'Mulakan'
                        : AppLocalizations.maybeOf(
                                context,
                              )?.translate('continue') ??
                              'Teruskan',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
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

  Widget _buildWelcomePage(bool isDark) {
    final loc = AppLocalizations.maybeOf(context) ?? AppLocalizations('ms');

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5F4F), Color(0xFF2A8F7F)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A5F4F).withValues(alpha: 0.3),
                    blurRadius: 30.r,
                    offset: Offset(0, 10.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.mosque_rounded,
                size: 80.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40.h),
            Text(
              loc.translate('welcome'),
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              loc.translate('app_description'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelectionPage(bool isDark) {
    final loc = AppLocalizations.maybeOf(context) ?? AppLocalizations('ms');

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_rounded,
              size: 80.sp,
              color: const Color(0xFF1A5F4F),
            ),
            SizedBox(height: 32.h),
            Text(
              loc.translate('choose_theme'),
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            _buildThemeOption(
              icon: Icons.light_mode_rounded,
              title: loc.translate('light'),
              value: ThemeMode.light,
              isDark: isDark,
            ),
            SizedBox(height: 16.h),
            _buildThemeOption(
              icon: Icons.dark_mode_rounded,
              title: loc.translate('dark'),
              value: ThemeMode.dark,
              isDark: isDark,
            ),
            SizedBox(height: 16.h),
            _buildThemeOption(
              icon: Icons.brightness_auto_rounded,
              title: loc.translate('auto'),
              value: ThemeMode.system,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required ThemeMode value,
    required bool isDark,
  }) {
    final isSelected = _selectedTheme == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTheme = value);
        widget.onThemeChanged(value);
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A5F4F).withValues(alpha: 0.1)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A5F4F) : Colors.transparent,
            width: 2.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1A5F4F)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
                size: 28.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF1A5F4F),
                size: 28.sp,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectionPage(bool isDark) {
    final loc = AppLocalizations.maybeOf(context) ?? AppLocalizations('ms');

    final languages = [
      {'code': 'ms', 'name': 'Bahasa Melayu', 'flag': '🇲🇾'},
      // {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      // {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language_rounded,
              size: 80.sp,
              color: const Color(0xFF1A5F4F),
            ),
            SizedBox(height: 32.h),
            Text(
              loc.translate('choose_language'),
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            ...languages.map(
              (lang) => Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: _buildLanguageOption(
                  flag: lang['flag']!,
                  name: lang['name']!,
                  code: lang['code']!,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String flag,
    required String name,
    required String code,
    required bool isDark,
  }) {
    final isSelected = _selectedLanguage == code;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedLanguage = code);
        widget.onLanguageChanged(code);
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0x221A5F4F) // 0x22 = 13% alpha (no withOpacity)
              : (isDark ? const Color(0x0DFFFFFF) : Colors.grey),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A5F4F) : Colors.transparent,
            width: 2.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x1AFFFFFF)
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Text(flag, style: TextStyle(fontSize: 28.sp)),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF1A5F4F),
                size: 28.sp,
              ),
          ],
        ),
      ),
    );
  }
}

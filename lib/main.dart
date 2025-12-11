import 'package:aqim/screens/home_screen.dart';
import 'package:aqim/services/global_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'screens/azan_full_screen.dart';
import 'screens/firstlaunch/legal_acceptance_screen.dart';
import 'screens/firstlaunch/onboarding_screen.dart';
import 'screens/firstlaunch/permission_intro_screen.dart';
import 'services/ads_service.dart';
import 'services/app_localization.dart';
import 'services/app_review_service.dart';
import 'services/app_update_service.dart';
import 'services/home_widget_service.dart';
import 'services/prayer_alarm_service.dart';
import 'utils/color_seed.dart';
import 'utils/loading_screen.dart';
import 'utils/plugin.dart';

final globalService = GlobalService();

// ✅ Create a GlobalKey for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ Track if AzanFullScreen is currently showing to prevent duplicates
bool _isAzanScreenCurrentlyShowing = false;

/// ✅ Configure edge-to-edge system UI for Android 15+ compatibility
/// This replaces deprecated SystemChrome.setSystemUIOverlayStyle() methods
void _configureEdgeToEdgeSystemUI() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Set transparent system bars for edge-to-edge display
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Configure edge-to-edge system UI for Android 15+ compatibility
  _configureEdgeToEdgeSystemUI();

  await globalService.initialize();
  await HomeWidgetService().homeWidgetInit();
  await AdsService().initGoogleMobileAds();

  // ✅ Preload ALL banner ads early (so they're ready when screens appear)
  // This happens in background while app initializes (non-blocking)
  AdsService.preloadAllBanners();

  WakelockPlus.enable();
  // ✅ Initialize Prayer Alarm Service
  // This handles alarms when the app is already running (not terminated)
  await PrayerAlarmService.initialize(
    onAlarmReceived: (prayerName, prayerTime) {
      debugPrint('🔔 [MAIN.DART] Prayer Alarm Received while app is active!');
      debugPrint('   Prayer: $prayerName');
      debugPrint('   Time: $prayerTime');
      debugPrint(
        '   Navigator state: ${navigatorKey.currentState != null ? "READY" : "NULL"}',
      );

      // Show azan screen when app is active
      if (navigatorKey.currentState != null) {
        debugPrint('📱 [MAIN.DART] Calling _showAzanScreenWhenActive()');
        _showAzanScreenWhenActive(prayerName, prayerTime);
      } else {
        debugPrint(
          '❌ [MAIN.DART] Navigator is NULL, cannot show AzanFullScreen',
        );
      }
    },
  );

  // ✅ Check for in-app updates (non-blocking)
  Future.delayed(const Duration(seconds: 2), () {
    AppUpdateService.checkForUpdate();
  });

  // ✅ Check and request in-app review (once per month, non-blocking)
  Future.delayed(const Duration(seconds: 5), () {
    AppReviewService.checkAndRequestReview();
  });

  runApp(const MyApp());
}

// Helper function to show azan when app is already running
void _showAzanScreenWhenActive(
  String prayerName,
  String prayerTime, {
  int retryCount = 0,
}) {
  debugPrint(
    '🚀 [_showAzanScreenWhenActive] START - Prayer: $prayerName, Time: $prayerTime (attempt ${retryCount + 1})',
  );

  final navigator = navigatorKey.currentState;
  if (navigator == null) {
    debugPrint(
      '❌ [_showAzanScreenWhenActive] Navigator not available (attempt ${retryCount + 1}/5)',
    );

    // Retry up to 5 times with increasing delays
    if (retryCount < 5) {
      final delay = Duration(
        milliseconds: 100 * (retryCount + 1),
      ); // 100ms, 200ms, 300ms, 400ms, 500ms
      debugPrint(
        '⏳ [_showAzanScreenWhenActive] Retrying in ${delay.inMilliseconds}ms...',
      );
      Future.delayed(delay, () {
        _showAzanScreenWhenActive(
          prayerName,
          prayerTime,
          retryCount: retryCount + 1,
        );
      });
    } else {
      debugPrint(
        '❌ [_showAzanScreenWhenActive] Navigator still not ready after 5 attempts, giving up',
      );
    }
    return;
  }

  debugPrint('✅ [_showAzanScreenWhenActive] Navigator is available');

  // Check if AzanFullScreen is already open
  if (_isAzanScreenCurrentlyShowing) {
    debugPrint(
      '⚠️ [_showAzanScreenWhenActive] AzanFullScreen already open, navigating to HomeScreen instead',
    );

    // Reset flag and pop all routes to go to HomeScreen
    _isAzanScreenCurrentlyShowing = false;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) {
          return FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return LoadingScreen();
              }
              final prefs = snapshot.data!;
              final themeMode =
                  ThemeMode.values[prefs.getInt(prefThemeMode) ?? 0];
              final languageCode = prefs.getString(prefLanguageCode) ?? 'ms';

              return HomeScreen(
                currentThemeMode: themeMode,
                currentLanguage: languageCode,
                onThemeToggle: () {},
                onLanguageChange: (_) {},
                onThemeChange: (_) {},
              );
            },
          );
        },
      ),
      (route) => false,
    );
    return;
  }

  debugPrint(
    '📱 [_showAzanScreenWhenActive] Showing azan screen (app is active)',
  );
  debugPrint(
    '📱 [_showAzanScreenWhenActive] Setting _isAzanScreenCurrentlyShowing = true',
  );
  _isAzanScreenCurrentlyShowing = true;

  // Get current theme and language from SharedPreferences
  debugPrint('📱 [_showAzanScreenWhenActive] Loading SharedPreferences...');
  SharedPreferences.getInstance().then((prefs) {
    debugPrint('📱 [_showAzanScreenWhenActive] SharedPreferences loaded');
    final themeMode = ThemeMode.values[prefs.getInt(prefThemeMode) ?? 0];
    final languageCode = prefs.getString(prefLanguageCode) ?? 'ms';

    debugPrint(
      '📱 [_showAzanScreenWhenActive] About to push AzanFullScreen route...',
    );
    navigator
        .push(
          PageRouteBuilder(
            fullscreenDialog: true,
            settings: const RouteSettings(
              name: 'AzanFullScreen',
              arguments: {'isAzanScreen': true},
            ),

            // PAGE
            pageBuilder: (context, animation, secondaryAnimation) {
              debugPrint(
                '🎨 [_showAzanScreenWhenActive] pageBuilder called - building AzanFullScreen widget',
              );
              return AzanFullScreen(
                prayerName: prayerName,
                prayerTime: prayerTime,
                currentThemeMode: themeMode,
                currentLanguage: languageCode,
                onThemeToggle: () {},
                onLanguageChange: (_) {},
                onThemeChange: (_) {},
              );
            },

            // FADE ANIMATION
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },

            transitionDuration: const Duration(milliseconds: 300),
          ),
        )
        .then((_) {
          _isAzanScreenCurrentlyShowing = false;
          debugPrint(
            '✅ [_showAzanScreenWhenActive] AzanFullScreen dismissed, flag reset',
          );
        });

    debugPrint(
      '📱 [_showAzanScreenWhenActive] navigator.push() called successfully',
    );
  });

  debugPrint('🏁 [_showAzanScreenWhenActive] END');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _languageCode = 'ms';
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLegalAccepted = false;
  bool _isFirstLaunch = true;
  bool _isLoading = true;
  bool _isPermission = false;

  // ✅ Track pending prayer alarm to show as initial screen
  bool _hasPendingAlarm = false;
  String _pendingPrayerName = '';
  String _pendingPrayerTime = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      debugPrint('🔄 [_loadPreferences] START');
      final prefs = await SharedPreferences.getInstance();

      // ✅ Check for pending prayer alarm from Android
      final hasPendingAlarm = prefs.getBool('has_pending_alarm') ?? false;
      debugPrint('📋 [_loadPreferences] has_pending_alarm: $hasPendingAlarm');

      if (hasPendingAlarm) {
        final prayerName = prefs.getString('pending_prayer_name') ?? '';
        final prayerTime = prefs.getString('pending_prayer_time') ?? '';
        final timestamp = prefs.getInt('pending_prayer_timestamp') ?? 0;

        debugPrint('📋 [_loadPreferences] Pending alarm details:');
        debugPrint('   Prayer: $prayerName');
        debugPrint('   Time: $prayerTime');
        debugPrint('   Timestamp: $timestamp');

        // Check if alarm is recent (within last 5 minutes)
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        debugPrint('   Age: ${age / 1000}s');

        if (age < 5 * 60 * 1000 && prayerName.isNotEmpty) {
          debugPrint(
            '🔔 [_loadPreferences] Found valid pending alarm: $prayerName at $prayerTime',
          );

          // Clear the pending alarm flag
          await prefs.setBool('has_pending_alarm', false);
          debugPrint('🧹 [_loadPreferences] Cleared has_pending_alarm flag');

          // ✅ Store alarm data to show as initial screen
          // This avoids navigator race condition issues
          _hasPendingAlarm = true;
          _pendingPrayerName = prayerName;
          _pendingPrayerTime = prayerTime;
          debugPrint(
            '✅ [_loadPreferences] Will show AzanFullScreen as initial screen',
          );
        } else {
          debugPrint(
            '⏰ [_loadPreferences] Pending alarm too old or invalid, ignoring',
          );
          await prefs.setBool('has_pending_alarm', false);
        }
      }

      final legalAccepted = prefs.getBool(prefIsLegalAccepted) ?? false;
      final firstLaunch = prefs.getBool(prefIsFirstLaunch) ?? true;
      final permission = prefs.getBool(prefIsPermission) ?? true;
      final themeMode = ThemeMode.values[prefs.getInt(prefThemeMode) ?? 0];
      final languageCode = prefs.getString(prefLanguageCode) ?? 'ms';

      debugPrint('📋 [_loadPreferences] Preferences loaded:');
      debugPrint('   Legal accepted: $legalAccepted');
      debugPrint('   First launch: $firstLaunch');
      debugPrint('   Permission: $permission');
      debugPrint('   Theme: $themeMode');
      debugPrint('   Language: $languageCode');

      setState(() {
        _isLegalAccepted = legalAccepted;
        _isFirstLaunch = firstLaunch;
        _isPermission = permission;
        _themeMode = themeMode;
        _languageCode = languageCode;
        _isLoading = false;
      });

      debugPrint('✅ [_loadPreferences] COMPLETE - _isLoading set to false');
    } catch (e) {
      debugPrint('❌ [_loadPreferences] ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(home: LoadingScreen());
    }
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      splitScreenMode: true,
      minTextAdapt: false,
      ensureScreenSize: false,
      builder: (context, child) {
        return LocalizationProvider(
          localizations: AppLocalizations(_languageCode),
          child: MaterialApp(
            navigatorKey: navigatorKey, // ✅ Attach navigator key for dialog
            debugShowMaterialGrid: false,
            showPerformanceOverlay: false,
            title: 'Aqim - Waktu Solat Malaysia',
            debugShowCheckedModeBanner: false,
            themeMode: _themeMode,
            theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
            darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
            home: _buildStartUpScreen(),
          ),
        );
      },
    );
  }

  Widget _buildStartUpScreen() {
    debugPrint('🔧 [_buildStartUpScreen] Called');
    debugPrint('   _hasPendingAlarm: $_hasPendingAlarm');
    debugPrint('   _pendingPrayerName: $_pendingPrayerName');
    debugPrint('   _pendingPrayerTime: $_pendingPrayerTime');

    // ✅ If there's a pending alarm, show AzanFullScreen directly as initial screen
    // This avoids navigator race condition when trying to navigate after startup
    if (_hasPendingAlarm) {
      debugPrint(
        '📱 [_buildStartUpScreen] Showing AzanFullScreen as initial screen for pending alarm',
      );
      debugPrint('   Prayer: $_pendingPrayerName');
      debugPrint('   Time: $_pendingPrayerTime');
      _isAzanScreenCurrentlyShowing = true;
      return AzanFullScreen(
        prayerName: _pendingPrayerName,
        prayerTime: _pendingPrayerTime,
        currentThemeMode: _themeMode,
        currentLanguage: _languageCode,
        onThemeToggle: () {
          final newMode = _themeMode == ThemeMode.light
              ? ThemeMode.dark
              : ThemeMode.light;
          setState(() => _themeMode = newMode);
        },
        onLanguageChange: (String code) {
          setState(() => _languageCode = code);
        },
        onThemeChange: (ThemeMode newMode) {
          setState(() => _themeMode = newMode);
        },
      );
    }

    // Always show the proper startup screen
    // Azan will be pushed on top after first frame if needed
    if (!_isLegalAccepted) {
      return LegalAcceptanceScreen(
        onAccepted: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(prefIsLegalAccepted, true);
          setState(() {
            _isLegalAccepted = true;
          });
        },
      );
    }

    if (_isFirstLaunch) {
      debugPrint('🎨 Paparan skrin pelancaran');
      return OnboardingScreen(
        onComplete: _completeOnboarding,
        onThemeChanged: (ThemeMode newMode) {
          setState(() => _themeMode = newMode);
        },
        onLanguageChanged: (String newLang) {
          setState(() => _languageCode = newLang);
        },
      );
    }
    if (!_isPermission) {
      return PermissionIntroScreen(
        onContinue: () async {
          if (mounted) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(prefIsPermission, true);
            setState(() {
              _isPermission = true;
            });
          }
        },
      );
    }
    return HomeScreen(
      currentThemeMode: _themeMode,
      currentLanguage: _languageCode,
      onThemeToggle: () {
        final newMode = _themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light;
        setState(() => _themeMode = newMode);
      },
      onLanguageChange: (String code) {
        setState(() => _languageCode = code);
      },
      onThemeChange: (ThemeMode newMode) {
        setState(() => _themeMode = newMode);
      },
    );
  }

  void _completeOnboarding(ThemeMode themeMode, String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefThemeMode, themeMode.index);
    await prefs.setString(prefLanguageCode, languageCode);
    await prefs.setBool(prefIsFirstLaunch, false);
    await prefs.setBool(prefIsPermission, false);

    if (mounted) {
      setState(() {
        _themeMode = themeMode;
        _languageCode = languageCode;
        _isFirstLaunch = false;
        _isPermission = false;
      });
    }
  }
}

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
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

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
      debugPrint('🔔 Prayer Alarm Received while app is active!');
      debugPrint('   Prayer: $prayerName');
      debugPrint('   Time: $prayerTime');

      // Show azan screen when app is active
      if (navigatorKey.currentState != null) {
        _showAzanScreenWhenActive(prayerName, prayerTime);
      }
    },
  );

  //SHOW ERROR WIDGET
  // ErrorWidget.builder = (FlutterErrorDetails details) {
  //   return Material(
  //     child: Container(
  //       color: Colors.green,
  //       child: Column(
  //         mainAxisAlignment: .center,
  //         children: [
  //           Text(
  //             details.exception.toString(),
  //             style: TextStyle(
  //               fontSize: 30,
  //               fontWeight: .bold,
  //               color: Colors.white,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // };
  runApp(const MyApp());
}

// Helper function to show azan when app is already running
void _showAzanScreenWhenActive(String prayerName, String prayerTime) {
  final navigator = navigatorKey.currentState;
  if (navigator == null) {
    debugPrint('❌ Navigator not available');
    return;
  }

  // Check if AzanFullScreen is already open
  if (_isAzanScreenCurrentlyShowing) {
    debugPrint(
      '⚠️ AzanFullScreen already open, navigating to HomeScreen instead',
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

  debugPrint('📱 Showing azan screen (app is active)');
  _isAzanScreenCurrentlyShowing = true;

  // Get current theme and language from SharedPreferences
  SharedPreferences.getInstance().then((prefs) {
    final themeMode = ThemeMode.values[prefs.getInt(prefThemeMode) ?? 0];
    final languageCode = prefs.getString(prefLanguageCode) ?? 'ms';

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
          debugPrint('✅ AzanFullScreen dismissed, flag reset');
        });
  });
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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Check for pending prayer alarm from Android
      final hasPendingAlarm = prefs.getBool('has_pending_alarm') ?? false;
      if (hasPendingAlarm) {
        final prayerName = prefs.getString('pending_prayer_name') ?? '';
        final prayerTime = prefs.getString('pending_prayer_time') ?? '';
        final timestamp = prefs.getInt('pending_prayer_timestamp') ?? 0;

        // Check if alarm is recent (within last 5 minutes)
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age < 5 * 60 * 1000 && prayerName.isNotEmpty) {
          debugPrint(
            '🔔 Found pending alarm on startup: $prayerName at $prayerTime',
          );

          // Clear the pending alarm flag
          await prefs.setBool('has_pending_alarm', false);

          // Schedule showing the azan screen after first frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showAzanScreen(prayerName, prayerTime);
          });
        } else {
          debugPrint('⏰ Pending alarm too old or invalid, ignoring');
          await prefs.setBool('has_pending_alarm', false);
        }
      }

      setState(() {
        _isLegalAccepted = prefs.getBool(prefIsLegalAccepted) ?? false;
        _isFirstLaunch = prefs.getBool(prefIsFirstLaunch) ?? true;
        _isPermission = prefs.getBool(prefIsPermission) ?? true;
        _themeMode = ThemeMode.values[prefs.getInt(prefThemeMode) ?? 0];
        _languageCode = prefs.getString(prefLanguageCode) ?? 'ms';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ _loadPreferences: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAzanScreen(String prayerName, String prayerTime) {
    if (navigatorKey.currentState == null) {
      debugPrint('❌ Navigator not ready for azan screen');
      return;
    }

    debugPrint('📱 Showing fullscreen azan for $prayerName');
    _isAzanScreenCurrentlyShowing = true;

    navigatorKey.currentState!
        .pushAndRemoveUntil(
          PageRouteBuilder(
            fullscreenDialog: true,
            settings: const RouteSettings(
              name: 'AzanFullScreen',
              arguments: {'isAzanScreen': true},
            ),

            // ⬇️ PAGE
            pageBuilder: (context, animation, secondaryAnimation) =>
                AzanFullScreen(
                  prayerName: prayerName,
                  prayerTime: prayerTime,
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
                ),

            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },

            transitionDuration: const Duration(milliseconds: 300),
          ),
          (route) => false,
        )
        .then((_) {
          _isAzanScreenCurrentlyShowing = false;
          debugPrint('✅ AzanFullScreen dismissed, flag reset');
        });
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

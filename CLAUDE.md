# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Aqim** is a Flutter-based Islamic prayer times application for Malaysia, providing prayer schedules, Qibla direction, rakaat counter, duas, and home widgets. The app supports both Malaysian prayer times (via JAKIM API) and international locations (via AlAdhan API).

## PLEASE REMEMBER THIS

dont use withOpacity() because its deprecated use withValues()

## ⚠️ CRITICAL: Backup Policy (MUST FOLLOW)

**BEFORE making ANY changes to code files, you MUST create a git backup commit first.**

### Mandatory Backup Workflow

When the user asks you to modify ANY file(s), follow these steps **WITHOUT EXCEPTION**:

1. **STOP and CREATE BACKUP FIRST**
   ```bash
   # Stage all current changes
   git add -A

   # Create backup commit with clear message
   git commit -m "🔒 BACKUP [dated][time]: Before [brief description of upcoming changes] 
   This is a mandatory safety backup before making changes.

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

2. **VERIFY backup was created**
   ```bash
   git log --oneline -1
   ```

3. **ONLY THEN proceed with the requested changes**

### Examples

**BAD (DO NOT DO THIS):**
```
User: "Please update rakaat_screen.dart"
Claude: *immediately edits the file* ❌
```

**GOOD (ALWAYS DO THIS):**
```
User: "Please update rakaat_screen.dart"
Claude: "Before I make any changes, let me create a backup commit first..."
        *creates backup commit*
        "Backup created successfully (commit abc123). Now updating rakaat_screen.dart..."
        *proceeds with edits* ✅
```

### Why This Matters

- **User's work is precious** - Never risk losing user's changes
- **Easy rollback** - User can always return to backup if something goes wrong
- **Change tracking** - Clear git history of what changed and when
- **Peace of mind** - User can trust that their work is safe

### Exceptions

The ONLY time you can skip backup:
- User explicitly says "no backup needed" or "skip backup"
- You're only reading files (no modifications)
- You're only running commands (no code changes)

**When in doubt, ALWAYS create a backup. It's better to have too many backups than too few.**

## Development Commands

### Build & Run
```bash
# Run the app in debug mode
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Clean build files
flutter clean
```

### Testing
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format .
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Generate launcher icons
flutter pub run flutter_launcher_icons
```

## Architecture & Design Patterns

### Service Layer (Singleton Pattern)
All major services use the singleton pattern for global access:

- **`GlobalService`** (`lib/services/global_service.dart`) - Singleton managing app-wide settings (notifications, prayer-specific settings, sounds, time format) and cached location data. Must be initialized in `main()` before use.

- **`LocationService`** (`lib/services/location_service.dart`) - Singleton for GPS/location operations with caching strategy (1-hour staleness threshold). Handles permission requests and provides fallback to Kuala Lumpur.

- **`PrayerTimesService`** (`lib/services/prayer_times_service.dart`) - Fetches prayer times from JAKIM (Malaysia) or AlAdhan API (international). Implements smart caching with date-based invalidation.

- **`PrayerAlarmService`** (`lib/services/prayer_alarm_service.dart`) - Platform channel service for Android-side alarm scheduling via `MethodChannel`.

### Data Flow Pattern
1. **App Initialization** (`main.dart`):
   - Initialize `GlobalService` (loads settings + location)
   - Initialize `HomeWidgetService`
   - Initialize `AdsService`
   - Initialize `PrayerAlarmService` with dialog callback
   - Enable wakelock

2. **First Launch Flow**:
   - `LegalAcceptanceScreen` → `OnboardingScreen` → `PermissionIntroScreen` → `HomeScreen`
   - SharedPreferences flags: `prefIsLegalAccepted`, `prefIsFirstLaunch`, `prefIsPermission`

3. **Prayer Times Fetching**:
   ```
   HomeScreen → GlobalService.getLocationData()
              → PrayerTimesService.getPrayerTimesData()
              → Check cache (date + location match)
              → If stale: Fetch from API (JAKIM/AlAdhan)
              → Update UI + Home Widget
   ```

### State Management
- Uses **StatefulWidget** with local state management
- **GlobalService** provides centralized settings state
- **SharedPreferences** for persistence
- No external state management library (Provider, Riverpod, etc.)

### Platform Channels
- **Prayer Alarm Channel**: `net.brings2you.aqim/prayer_alarm`
  - `scheduleAllPrayerAlarms()` - Schedule alarms on Android side
  - `cancelAllPrayerAlarms()` - Cancel all alarms
  - `onPrayerAlarm` - Callback when alarm triggers

### Models
- **`PrayerTimeData`** (`lib/models/prayer_time_model.dart`) - Contains:
  - List of `PrayerTime` objects (7 prayers: Imsak, Subuh, Syuruk, Zohor, Asar, Maghrib, Isyak)
  - Each prayer has: name, time, isPassed, isNext flags
  - Hijri/Gregorian dates, zone, location, source

- **Zone Data** (`lib/models/zone_model.dart`) - Malaysian prayer zones with coordinates

## Key Implementation Details

### Prayer Time Caching Strategy
Prayer times are cached based on:
1. **Date match** (DD-MM-YYYY format)
2. **Location match** (locality name)

Cache is invalidated when either changes. Stored in SharedPreferences as JSON.

### Location Caching Strategy
Location data is cached for **1 hour** to minimize GPS usage:
- First checks memory cache (`_cachedLocationData` in GlobalService)
- Then checks SharedPreferences cache
- If cache is stale (>1 hour), fetches fresh location
- Falls back to cached data on timeout/error
- Ultimate fallback: Kuala Lumpur coordinates

### Prayer Time Zone Matching (Malaysia)
Multi-level matching strategy in `PrayerTimesService._findZoneByLocationMY()`:
1. **Exact match**: Match location name to zone definitions
2. **Partial match**: Contains-based matching
3. **Distance-based**: Haversine formula to find nearest zone
4. Handles special cases for Melaka, Perlis, Johor

### UI Design
- Uses **Material Design 3** with custom `ColorScheme` (flex_seed_scheme)
- **ScreenUtil** for responsive sizing (design base: 390x844)
- Custom fonts: Aqim (icon font), Lateef & ScheherazadeNew (Arabic fonts)
- Portrait-only orientation (locked in `HomeScreen`)

### Global Constants
All SharedPreferences keys are defined in `lib/utils/plugin.dart`:
- `prefIsFirstLaunch`, `prefIsLegalAccepted`, `prefIsPermission`
- `prefNotificationsEnabled`, `prefSoundEnabled`, `prefVibrationEnabled`
- Prayer-specific: `prefSubuhEnabled`, `prefSubuhSound`, etc.
- `prefCachedLocation`, `prefCachedLocationTime`
- `prefThemeMode`, `prefLanguageCode`

### Assets Structure
```
assets/
├── fonts/        - Aqim, Lateef, ScheherazadeNew fonts
├── images/       - Background images
├── json/         - Duas, hadith data
├── lottie/       - Animations (mosque, spinner)
├── sounds/       - Azan audio files
├── svg/          - Vector graphics
└── icon/         - App icon
```

## Testing Strategy
- Main test file: `test/widget_test.dart`
- Run widget tests with `flutter test`

## Platform-Specific Notes

### Android
- Min SDK: 21
- Uses AlarmManager for prayer notifications
- Custom MethodChannel for alarm callbacks
- Launcher icon configuration in pubspec.yaml

### iOS
- App icon configured via Xcode assets
- Location permissions required in Info.plist
- Background modes for notifications

## Common Tasks

### Adding a New Prayer Setting
1. Add key constant to `lib/utils/plugin.dart`
2. Add property to `GlobalService` class
3. Update `initialize()` to load from SharedPreferences
4. Add getter/setter in `GlobalService`
5. Update settings UI to modify the setting

### Adding a New Screen
1. Create screen file in `lib/screens/`
2. Add navigation in HomeScreen's `_buildQuickActions()` GridView
3. Add icon to `lib/utils/aqim_icons.dart` if needed
4. Use PageRouteBuilder with FadeTransition for consistent animations

### Modifying Prayer Time Display
- Prayer times are fetched in `HomeScreen._initializeHomeScreenFast()`
- Next prayer logic in `HomeScreen._setupNextPrayer()`
- Only 5 main prayers (Subuh, Zohor, Asar, Maghrib, Isyak) are considered for "next prayer"
- Imsak and Syuruk are displayed but not scheduled for alarms

### Working with Localization
- `AppLocalizations` service in `lib/services/app_localization.dart`
- Language code stored in SharedPreferences (`prefLanguageCode`)
- Default: Malay (`ms`)

## Dependencies Overview

**Core Flutter**: Camera, location (geolocator, geocoding), timezone, permissions

**UI/UX**: flutter_screenutil (responsive), shimmer (loading), carousel_slider, flutter_svg, lottie

**Backend**: dio (HTTP), shared_preferences (storage), intl (formatting)

**Features**:
- Google ML Kit (pose detection for rakaat counter)
- flutter_compass (Qibla direction)
- home_widget (Android/iOS widgets)
- awesome_notifications (prayer alarms)
- google_mobile_ads (monetization)
- qr_flutter (donation QR codes)

## API Endpoints

### JAKIM API (Malaysia)
```
GET https://www.e-solat.gov.my/index.php
    ?r=esolatApi/TakwimSolat
    &period=today
    &zone={ZONE_CODE}
```

### AlAdhan API (International)
```
GET https://api.aladhan.com/v1/timings/{timestamp}
    ?latitude={LAT}
    &longitude={LON}
    &method=4
```

## Important Global Variables
Located in `main.dart`:
- `globalService` - Instance of GlobalService
- `navigatorKey` - GlobalKey for navigation (used for alarm dialogs)
- `prayerTimeData` - Current prayer times (defined in plugin.dart)
- `isShowAds` - Ad visibility flag (defined in plugin.dart)

## Debug Screens
- `PrayerAlarmDebugScreen` - Test prayer alarm functionality (accessible via button on HomeScreen in debug builds)

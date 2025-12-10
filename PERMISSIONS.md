# Android Permissions Documentation for Aqim Prayer App

This document explains all Android permissions requested by the Aqim app, their purpose, and whether they are required by Google Play Store policies.

---

## 📋 Current Permissions in AndroidManifest.xml

### ✅ **REQUIRED PERMISSIONS** (Keep These)

#### 1. **INTERNET**
```xml
<uses-permission android:name="android.permission.INTERNET" />
```
- **Purpose**: Essential for fetching prayer times from APIs
- **Used For**:
  - JAKIM API (Malaysian prayer times)
  - AlAdhan API (International prayer times)
  - Google Mobile Ads
- **Play Store Required**: YES
- **User Prompt**: NO (granted automatically)
- **Files Using**: `lib/services/prayer_times_service.dart`, `lib/services/ads_service.dart`
- **Justification**: "Fetch daily prayer times from JAKIM and AlAdhan APIs"

---

#### 2. **CAMERA**
```xml
<uses-permission android:name="android.permission.CAMERA" />
```
- **Purpose**: Rakaat counter feature using pose detection
- **Used For**: Google ML Kit pose detection to count prayer rakaats
- **Play Store Required**: YES (if using camera feature)
- **User Prompt**: YES (runtime permission)
- **Files Using**: `lib/screens/rakaat_counter_screen.dart`
- **Justification**: "Enable rakaat counting during prayer using pose detection"

---

#### 3. **ACCESS_FINE_LOCATION**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```
- **Purpose**: Get user's precise location for accurate prayer times and Qibla direction
- **Used For**:
  - Determine prayer zone (Malaysia) or coordinates (International)
  - Calculate Qibla compass direction
  - Zone matching for Malaysian prayer times
- **Play Store Required**: YES
- **User Prompt**: YES (runtime permission)
- **Files Using**: `lib/services/location_service.dart`, Qibla compass feature
- **Justification**: "Determine accurate prayer times based on your location and calculate Qibla direction"

---

#### 4. **POST_NOTIFICATIONS** (Android 13+)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```
- **Purpose**: Show prayer time notifications
- **Used For**: Display azan notifications at prayer times
- **Play Store Required**: YES (for notifications)
- **User Prompt**: YES (runtime permission on Android 13+)
- **Files Using**: `android/app/src/main/kotlin/net/brings2you/aqim/PrayerAlarmReceiver.kt`
- **Justification**: "Notify you when it's time for prayer"

---

#### 5. **SCHEDULE_EXACT_ALARM**
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```
- **Purpose**: Schedule exact prayer time alarms
- **Used For**: Trigger azan at precise prayer times
- **Play Store Required**: YES (for alarm apps)
- **User Prompt**: YES (settings page)
- **Files Using**: `android/app/src/main/kotlin/net/brings2you/aqim/PrayerAlarmReceiver.kt`
- **Justification**: "Schedule exact alarms for prayer times (cannot be delayed)"

---

#### 6. **USE_EXACT_ALARM** (Android 14+)
```xml
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```
- **Purpose**: Alternative to SCHEDULE_EXACT_ALARM for Android 14+
- **Used For**: Same as SCHEDULE_EXACT_ALARM
- **Play Store Required**: YES
- **User Prompt**: NO (granted automatically for alarm apps)
- **Files Using**: `android/app/src/main/kotlin/net/brings2you/aqim/PrayerAlarmReceiver.kt`
- **Justification**: "Ensure prayer alarms trigger at exact times on Android 14+"

---

#### 7. **RECEIVE_BOOT_COMPLETED**
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```
- **Purpose**: Reschedule prayer alarms after device reboot
- **Used For**: Restore prayer notifications after phone restarts
- **Play Store Required**: YES (for persistent alarms)
- **User Prompt**: NO (granted automatically)
- **Files Using**: `android/app/src/main/kotlin/net/brings2you/aqim/BootReceiver.kt`
- **Justification**: "Restore prayer alarms after device restart"

---

#### 8. **WAKE_LOCK**
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
```
- **Purpose**: Keep screen on during prayer time display
- **Used For**: Prevent screen from sleeping during azan screen
- **Play Store Required**: YES
- **User Prompt**: NO (granted automatically)
- **Files Using**: `lib/main.dart` (`WakelockPlus.enable()`)
- **Justification**: "Keep screen on during prayer time notifications"

---

#### 9. **VIBRATE**
```xml
<uses-permission android:name="android.permission.VIBRATE" />
```
- **Purpose**: Vibrate phone during azan notifications
- **Used For**: Alert user with vibration at prayer times
- **Play Store Required**: YES
- **User Prompt**: NO (granted automatically)
- **Files Using**: Prayer alarm notifications
- **Justification**: "Provide haptic feedback for prayer notifications"

---

#### 10. **USE_FULL_SCREEN_INTENT**
```xml
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```
- **Purpose**: Show fullscreen azan when phone is locked
- **Used For**: Display azan screen even when device is locked
- **Play Store Required**: YES (for alarm apps)
- **User Prompt**: YES (Android 14+, settings page)
- **Files Using**: `android/app/src/main/kotlin/net/brings2you/aqim/MainActivity.kt` (lock screen flags)
- **Justification**: "Display prayer notifications on locked screen"

---

## ⚠️ **QUESTIONABLE PERMISSIONS** (Need Review)

### 🔍 **ACCESS_COARSE_LOCATION**
```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```
- **Purpose**: Less precise location (city-level)
- **Current Usage**: ❌ **NOT USED** - Your code only uses `ACCESS_FINE_LOCATION`
- **Analysis**:
  - Your `LocationService` uses `LocationAccuracy.high` (line 24)
  - You need precise location for zone matching
  - Coarse location provides ±500m accuracy (not enough for prayer zones)
- **Recommendation**: ⚠️ **CAN BE REMOVED** unless you want to offer a "low accuracy" fallback option
- **Play Store Impact**: Google will ask why you need BOTH fine and coarse location

**Decision**: **REMOVE** - You only need fine location for accurate prayer times.

---

### 🔍 **ACCESS_BACKGROUND_LOCATION**
```xml
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```
- **Purpose**: Access location when app is in background
- **Current Usage**: ❌ **NOT USED** - Your app only gets location when user opens it
- **Analysis**:
  - Your `LocationService.loadLocationFast()` is only called from `HomeScreen` (foreground)
  - You use **1-hour caching** to avoid repeated GPS requests
  - Prayer times are fetched **once per day** and cached
  - You do NOT track user location in background
  - Your app does NOT update prayer times automatically in background
- **Play Store Requirement**: ⚠️ **REQUIRES DETAILED JUSTIFICATION**
  - Google enforces strict policies on background location
  - Requires declaration form explaining EXACTLY why needed
  - High rejection risk if justification is weak
- **Recommendation**: ❌ **MUST BE REMOVED** - You don't use background location at all

**Decision**: **REMOVE IMMEDIATELY** - This will cause Play Store rejection if you can't justify it.

---

### 🔍 **REQUEST_IGNORE_BATTERY_OPTIMIZATIONS**
```xml
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```
- **Purpose**: Request exemption from battery optimization
- **Current Usage**: ✅ **USED** - `BatteryOptimizationHelper.kt`
- **Analysis**:
  - Used to ensure prayer alarms work reliably
  - Android's battery optimization can kill exact alarms
  - Your app has legitimate use case (alarm clock app)
- **Play Store Requirement**: ⚠️ **REQUIRES JUSTIFICATION**
  - Must explain why alarms need to bypass battery optimization
  - Only allowed for alarm clocks, task reminders, etc.
  - **ACCEPTABLE** for prayer time apps
- **Recommendation**: ✅ **KEEP** - Justified for alarm functionality

**Play Store Justification**:
> "Our app is a prayer time alarm clock that needs to trigger exact notifications at specific Islamic prayer times (5 times daily). Battery optimization can prevent these critical religious reminders from working reliably. This permission ensures timely notifications for users' religious obligations."

---

### 🔍 **FOREGROUND_SERVICE**
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```
- **Purpose**: Run a foreground service
- **Current Usage**: ❌ **NOT USED** - You have NO foreground services
- **Analysis**:
  - Searched all Kotlin files - no `Service` class found
  - No `startForeground()` calls anywhere
  - You use `BroadcastReceiver` for alarms (correct approach)
  - You use `WorkManager` for widget updates (correct approach)
- **Recommendation**: ❌ **MUST BE REMOVED** - You don't have any foreground services

**Decision**: **REMOVE** - Unused and will raise questions during Play Store review.

---

### 🔍 **FOREGROUND_SERVICE_SPECIAL_USE**
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
```
- **Purpose**: Declare special use case for foreground service
- **Current Usage**: ❌ **NOT USED** - You have NO foreground services
- **Analysis**: Same as above - you don't use foreground services at all
- **Recommendation**: ❌ **MUST BE REMOVED**

**Decision**: **REMOVE** - Completely unnecessary.

---

## 📝 **Summary of Recommendations**

### ✅ **KEEP These Permissions** (11 total):
1. ✅ `INTERNET` - API calls
2. ✅ `CAMERA` - Rakaat counter
3. ✅ `ACCESS_FINE_LOCATION` - Prayer times & Qibla
4. ✅ `POST_NOTIFICATIONS` - Prayer notifications
5. ✅ `SCHEDULE_EXACT_ALARM` - Exact prayer alarms
6. ✅ `USE_EXACT_ALARM` - Android 14+ alarms
7. ✅ `RECEIVE_BOOT_COMPLETED` - Restore alarms after reboot
8. ✅ `WAKE_LOCK` - Keep screen on
9. ✅ `VIBRATE` - Notification vibration
10. ✅ `USE_FULL_SCREEN_INTENT` - Lock screen notifications
11. ✅ `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` - Reliable alarms

### ❌ **REMOVE These Permissions** (4 total):
1. ❌ `ACCESS_COARSE_LOCATION` - Not needed (you use fine location)
2. ❌ `ACCESS_BACKGROUND_LOCATION` - Not used (high rejection risk)
3. ❌ `FOREGROUND_SERVICE` - No foreground services in app
4. ❌ `FOREGROUND_SERVICE_SPECIAL_USE` - No foreground services in app

---

## 🎯 **Google Play Store Justifications**

When uploading to Play Store, you'll need to fill out the **Permissions Declaration Form**. Here's what to write:

### **ACCESS_FINE_LOCATION**
**Why do you need this permission?**
> "Our app fetches accurate Islamic prayer times based on the user's location. For Malaysian users, we match their coordinates to specific prayer zones (e.g., Johor Bahru zone JHR01). For international users, we use coordinates to query the AlAdhan API. This permission is also used for the Qibla compass feature to calculate the direction to Mecca."

**When is it used?**
> "Only when the user opens the app to view prayer times or uses the Qibla compass. Location is cached for 1 hour to minimize GPS usage. We do NOT track location in the background."

---

### **CAMERA**
**Why do you need this permission?**
> "Our app includes a rakaat counter feature that uses Google ML Kit pose detection to automatically count prayer cycles (rakaats) by detecting the user's prayer movements. This is an optional feature that helps users keep track during prayer."

**When is it used?**
> "Only when the user explicitly opens the Rakaat Counter feature and grants camera permission."

---

### **REQUEST_IGNORE_BATTERY_OPTIMIZATIONS**
**Why do you need this permission?**
> "Our app is a prayer time alarm clock that needs to notify users at exact Islamic prayer times (5 times daily). Android's battery optimization can prevent these time-sensitive religious reminders from triggering on time. This permission ensures reliable, timely notifications for users' religious obligations."

**When is it used?**
> "We request this permission only when the user enables prayer notifications in settings. It ensures AlarmManager can trigger exact alarms even when the device is in Doze mode."

---

### **SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM**
**Why do you need these permissions?**
> "Islamic prayer times occur at specific astronomical times that cannot be delayed or approximated. Our app schedules exact alarms (e.g., 5:45 AM for Fajr) to ensure users receive timely reminders for their religious obligations."

---

### **USE_FULL_SCREEN_INTENT**
**Why do you need this permission?**
> "When prayer time arrives and the user's phone is locked, we display a full-screen notification with the azan (call to prayer). This ensures the user doesn't miss important prayer times even when their device is locked."

---

## ⚠️ **High-Risk Permissions to Avoid**

These permissions will trigger **manual review** by Google Play Store:

| Permission | Risk Level | Your App Status |
|------------|-----------|-----------------|
| `ACCESS_BACKGROUND_LOCATION` | 🔴 **CRITICAL** | ❌ **REMOVE** (not used) |
| `FOREGROUND_SERVICE` | 🟡 **MEDIUM** | ❌ **REMOVE** (not used) |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | 🟡 **MEDIUM** | ✅ **KEEP** (justified) |
| `USE_FULL_SCREEN_INTENT` | 🟢 **LOW** | ✅ **KEEP** (alarm app) |

---

## 🔧 **Implementation Notes**

### Location Permission Strategy:
Your app currently implements **GOOD PRACTICES**:
- ✅ Only requests location when app is opened (foreground)
- ✅ Caches location for 1 hour to reduce GPS usage
- ✅ Falls back to cached location on timeout/error
- ✅ Uses Kuala Lumpur as ultimate fallback

### What You DON'T Do (Good!):
- ❌ Track location in background
- ❌ Update location automatically
- ❌ Use location for analytics/ads
- ❌ Share location data with third parties

---

## 📱 **User Experience Impact**

After removing unnecessary permissions:

### Before (16 permissions):
```
⚠️ This app wants to:
- Access your location in the background  ← SCARY!
- Run in the background                   ← SCARY!
- Ignore battery optimizations
- Access camera
- ... (12 more)
```

### After (11 permissions):
```
✅ This app wants to:
- Access your precise location            ← CLEAR
- Use camera for rakaat counter           ← CLEAR
- Send notifications                      ← EXPECTED
- Schedule exact alarms                   ← EXPECTED
- ... (7 more)
```

---

## 📋 **Play Store Compliance Checklist**

Before submitting to Play Store:

- [ ] Remove `ACCESS_BACKGROUND_LOCATION` from AndroidManifest
- [ ] Remove `ACCESS_COARSE_LOCATION` from AndroidManifest
- [ ] Remove `FOREGROUND_SERVICE` from AndroidManifest
- [ ] Remove `FOREGROUND_SERVICE_SPECIAL_USE` from AndroidManifest
- [ ] Test app still works after removing permissions
- [ ] Prepare justifications for sensitive permissions
- [ ] Fill out Permissions Declaration Form in Play Console
- [ ] Record screen video showing permission usage (if requested)

---

## 🎯 **Next Steps**

1. **Remove unnecessary permissions** from `AndroidManifest.xml`
2. **Test thoroughly** to ensure app still works
3. **Prepare Play Store listing** with clear permission explanations
4. **Upload APK/Bundle** and fill out declaration forms
5. **Monitor for rejection** and respond quickly with justifications

---

**Last Updated**: 2025-12-09
**App Version**: 1.0.2+2
**Document Status**: Ready for Play Store submission

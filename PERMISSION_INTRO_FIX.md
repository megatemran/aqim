# 🔧 Permission Intro Screen - Exact Alarm Fix

## ❌ Masalah Yang Ditemui

### 1. **Exact Alarm Permission Always "Granted" di Permission Intro Screen**

**Lokasi:** `lib/screens/firstlaunch/permission_intro_screen.dart`

**Kod Bermasalah (Baris 111):**
```dart
final alarm = await Permission.scheduleExactAlarm.status;
```

**Punca Masalah:**
- `permission_handler` package **TIDAK support** `scheduleExactAlarm` dengan betul
- `.status` akan **always return `granted`** even kalau user belum enable permission
- Package ini tidak implement proper check untuk exact alarm pada Android 12+
- Menyebabkan UI menunjukkan ✅ green checkmark walaupun permission sebenarnya `denied`

**Impak:**
- User nampak permission dah granted (warna hijau)
- User boleh tekan "Teruskan" tanpa enable permission sebenar
- Alarm waktu solat akan jadi **inexact** (delay 15-60 minit!)
- Very confusing untuk user

---

### 2. **Duplicate Permission Check (Redundant)**

**2 tempat check exact alarm permission:**

1. ❌ **Permission Intro Screen** (`permission_intro_screen.dart`)
   - First launch onboarding flow
   - Using wrong method (permission_handler)

2. ✅ **Home Screen** (`home_screen.dart`)
   - After app loads
   - Using correct method (native MethodChannel)

**Masalah:**
- Dialog permission muncul **2 kali** - annoying untuk user
- Confusing - kenapa perlu ask twice?
- Code redundancy

---

## ✅ Penyelesaian

### **Fix 1: Guna Native Method Channel di Permission Intro**

**Before:**
```dart
// ❌ WRONG - permission_handler does NOT work
final alarm = await Permission.scheduleExactAlarm.status;

setState(() {
  _alarmStatus = alarm.isGranted ? 'granted' : 'denied';
});
```

**After:**
```dart
// ✅ CORRECT - Use native method channel
final alarm = await PrayerAlarmService.canScheduleExactAlarms();

setState(() {
  _alarmStatus = alarm ? 'granted' : 'denied';
});
```

**Kenapa Betul:**
- `PrayerAlarmService.canScheduleExactAlarms()` call native Android code
- Native code guna `alarmManager.canScheduleExactAlarms()` (official Android API)
- Return **actual permission status** bukan fake "granted"

---

### **Fix 2: Guna Native Method untuk Open Settings**

**Before:**
```dart
// ❌ WRONG - permission_handler cannot request exact alarm
onTap: () async {
  final result = await _requestPermission(
    permission: Permission.scheduleExactAlarm,
  );
  setState(() => _alarmStatus = result);
}
```

**After:**
```dart
// ✅ CORRECT - Open system settings directly
onTap: () async {
  // Open Settings for user to manually enable
  await PrayerAlarmService.openExactAlarmSettings();

  // Wait for user action
  await Future.delayed(const Duration(seconds: 1));

  // Re-check permission status
  final isGranted = await PrayerAlarmService.canScheduleExactAlarms();
  setState(() {
    _alarmStatus = isGranted ? 'granted' : 'denied';
  });
}
```

**Kenapa Betul:**
- Exact alarm permission **CANNOT be requested via dialog** pada Android 12+
- User **MESTI manually enable** dalam Settings
- Kita buka Settings terus, user toggle, then kita recheck status

---

### **Fix 3: Auto Re-check When User Returns from Settings**

**Added Lifecycle Observer:**

```dart
class _PermissionIntroScreenState extends State<PermissionIntroScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned from Settings - recheck permissions
      _checkInitialPermissions();
    }
  }
}
```

**Benefit:**
- Bila user kembali dari Settings → auto update UI
- Kalau permission enabled → ✅ green checkmark muncul automatically
- No need manual refresh

---

### **Fix 4: Remove Duplicate Dialog di Home Screen**

**Added Smart Check:**

```dart
// Only show if NOT in onboarding flow
final prefs = await SharedPreferences.getInstance();
final isFirstLaunch = prefs.getBool('prefIsFirstLaunch') ?? true;

if (isFirstLaunch) {
  // User in onboarding - skip home screen dialog
  return;
}

// Only for existing users or revoked permissions
await ExactAlarmPermissionDialog.showIfNeeded(context);
```

**Flow Sekarang:**

1. **First Launch:**
   - Permission Intro Screen handles ALL permission requests ✅
   - Home Screen dialog skipped (avoid duplicate)

2. **Existing Users:**
   - Permission Intro skipped
   - Home Screen dialog shown if permission missing
   - Catches revoked permissions

3. **Best of Both Worlds:**
   - New users: One-time setup in onboarding
   - Existing users: Reminder if permission revoked

---

## 📊 Comparison

### Before Fix:

| Screen | Check Method | Status Display | User Experience |
|--------|-------------|----------------|-----------------|
| Permission Intro | ❌ `permission_handler` | Always "granted" (fake) | Confusing ❌ |
| Home Screen | ✅ Native method | Correct | Shows 2nd dialog ❌ |

**Problems:**
- False positive in onboarding
- Duplicate dialogs
- User can skip real permission

---

### After Fix:

| Screen | Check Method | Status Display | User Experience |
|--------|-------------|----------------|-----------------|
| Permission Intro | ✅ Native method | Correct status | Clear & accurate ✅ |
| Home Screen | ✅ Native method (smart skip) | Correct | No duplicate ✅ |

**Benefits:**
- ✅ Accurate permission status everywhere
- ✅ No duplicate dialogs
- ✅ User cannot skip real permission
- ✅ Auto-update when returning from Settings

---

## 🧪 Testing Guide

### Test 1: Fresh Install (Android 12+)

1. Install app (fresh install)
2. Go through Legal → Onboarding screens
3. Reach **Permission Intro Screen**
4. Check "Alarm Tepat" status → Should show **❌ DENIED** (not green)
5. Tap "Alarm Tepat" → Opens Settings
6. Enable "Alarms & reminders" in Settings
7. Return to app → Status auto-updates to **✅ GRANTED** (green)
8. All 3 permissions granted → "Teruskan" button enabled
9. Tap "Teruskan" → Go to Home Screen
10. **NO duplicate dialog** should appear ✅

**Expected:** Permission handled ONCE in onboarding, no duplicate.

---

### Test 2: Existing User (Already Passed Onboarding)

1. App already installed (not first launch)
2. User already completed onboarding before
3. User **revokes** exact alarm permission in Settings
4. Open app → Go to Home Screen
5. After 2 seconds → **Dialog appears** asking for permission ✅
6. User grants permission via dialog
7. Next time open app → **No dialog** (permission already granted)

**Expected:** Dialog only for existing users with revoked permissions.

---

### Test 3: Android 11 and Below

1. Install on Android 11 (no exact alarm permission needed)
2. Permission Intro Screen → "Alarm Tepat" should show **✅ GRANTED** immediately
3. No Settings needed (permission auto-granted on old Android)

**Expected:** Works seamlessly on older Android versions.

---

## 📝 Files Modified

### 1. **permission_intro_screen.dart**
```diff
+ import 'package:aqim/services/prayer_alarm_service.dart';

+ class _PermissionIntroScreenState extends State<PermissionIntroScreen>
+     with WidgetsBindingObserver {

  Future<void> _checkInitialPermissions() async {
-   final alarm = await Permission.scheduleExactAlarm.status;
+   final alarm = await PrayerAlarmService.canScheduleExactAlarms();

    setState(() {
-     _alarmStatus = alarm.isGranted ? 'granted' : 'denied';
+     _alarmStatus = alarm ? 'granted' : 'denied';
    });
  }

  onTap: () async {
-   final result = await _requestPermission(
-     permission: Permission.scheduleExactAlarm,
-   );
+   await PrayerAlarmService.openExactAlarmSettings();
+   await Future.delayed(const Duration(seconds: 1));
+   final isGranted = await PrayerAlarmService.canScheduleExactAlarms();
+   setState(() => _alarmStatus = isGranted ? 'granted' : 'denied');
  }

+ @override
+ void didChangeAppLifecycleState(AppLifecycleState state) {
+   if (state == AppLifecycleState.resumed) {
+     _checkInitialPermissions();
+   }
+ }
```

---

### 2. **home_screen.dart**
```diff
+ import 'package:shared_preferences/shared_preferences.dart';

  Future<void> _checkExactAlarmPermission() async {
+   final prefs = await SharedPreferences.getInstance();
+   final isFirstLaunch = prefs.getBool('prefIsFirstLaunch') ?? true;
+
+   if (isFirstLaunch) {
+     // Skip dialog during onboarding
+     return;
+   }

-   await ExactAlarmPermissionDialog.showIfNeeded(context);
+   if (mounted) {
+     await ExactAlarmPermissionDialog.showIfNeeded(context);
+   }
  }
```

---

## 🎯 Summary

### Root Cause:
- `permission_handler` package does NOT properly support `scheduleExactAlarm`
- Always returns fake "granted" status
- Cannot request exact alarm permission via dialog

### Solution:
- ✅ Use native MethodChannel (`PrayerAlarmService.canScheduleExactAlarms()`)
- ✅ Open Settings directly for user to manually enable
- ✅ Auto-recheck when user returns from Settings
- ✅ Smart duplicate prevention (skip home dialog during onboarding)

### Result:
- ✅ Accurate permission status display
- ✅ No duplicate permission requests
- ✅ User cannot skip real permission grant
- ✅ Better UX - clear and streamlined

---

**Problem SOLVED!** 🎉 Permission intro screen sekarang menunjukkan status yang **BETUL** dan tidak ada duplicate dialog.

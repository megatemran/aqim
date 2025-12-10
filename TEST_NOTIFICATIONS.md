# Quick Notification Test - All Conditions

## Setup (Do Once):
1. Install: `adb install -r build\app\outputs\flutter-apk\app-release.apk`
2. Open app, complete onboarding, grant ALL permissions
3. Set a test prayer time 2-3 minutes from now

## Test Each Condition:

### Test 1: Foreground
- App is OPEN on screen
- Wait for alarm
- ✅ Should show AzanFullScreen immediately

### Test 2: Background
- Press HOME button
- Wait for alarm
- ✅ Should show fullscreen over home

### Test 3: Other App Running
- Open YouTube/Chrome
- Wait for alarm
- ✅ Should interrupt and show fullscreen

### Test 4: Locked Screen
- Lock phone (screen off)
- Wait for alarm
- ✅ Screen turns on + fullscreen shows

### Test 5: Doze Mode
- Wait 30+ minutes (or use ADB: `adb shell dumpsys deviceidle force-idle`)
- ✅ Should wake and show fullscreen

### Test 6: App Killed
- Force stop app in Settings
- Wait for alarm
- ✅ App launches automatically with fullscreen

## Result:
If all 6 tests pass ✅ = Notifications work perfectly!
